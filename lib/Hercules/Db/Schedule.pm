package Hercules::Db::Schedule;

use strict;
use warnings;

use parent 'Hercules::Db';

use Hercules::Db::Output;

use DateTime;
use JSON qw(from_json to_json);

use Sys::Hostname qw(hostname);

__PACKAGE__->table('cronjob');

__PACKAGE__->columns( Primary => 'id' );

__PACKAGE__->columns( ALL => qw(
  id
  name
  cron_group
  class
  params
  run_every
  run_after
  run_schedule
  last_run_ok_epoch
  error_cnt
  running_until_epoch
  next_run_epoch
  max_run_time
  flags
));

__PACKAGE__->set_sql(runnable => q{
  SELECT %s
    FROM __TABLE__
    WHERE next_run_epoch<UNIX_TIMESTAMP()
      AND running_until_epoch<UNIX_TIMESTAMP()
      AND cron_group in (%s)
      AND flags LIKE '%%active%%'
    %s
});

__PACKAGE__->set_sql(next_run => q{
  SELECT min(next_run_epoch)
    FROM __TABLE__
    WHERE next_run_epoch>UNIX_TIMESTAMP()
      AND cron_group = ?
      AND flags LIKE '%%active%%'
});

__PACKAGE__->set_sql(group_stats => q{
  SELECT cron_group, flags,
      if(next_run_epoch<UNIX_TIMESTAMP(),1,0) runnable,
      min(next_run_epoch) min_next_run, count(*) cnt
    FROM cronjob
    GROUP BY cron_group, flags, runnable
});

__PACKAGE__->has_a(params => 'Hercules::Params',
    inflate => sub { 
      my $res;
      eval { $res = from_json( shift, {utf8=>1}) };
      $res = {} unless $res;
      return bless $res, 'Hercules::Params';
    },
    deflate => sub {
        my $val = shift;
        return '{}' unless ref $val and keys %$val;
        to_json( { %$val }, {utf8=>1});
      },
  );

sub count_runnable {
  my ($class,@groups) = @_;

  unshift @groups, '' unless grep { $_ eq '' } @groups;
  my $group_places = join ',', ('?')x(scalar @groups);

  my $sth = $class->sql_runnable(
      'count(*)',$group_places, ''
    );
    
  return $sth->select_val(@groups);
}

sub get_runnable {
  my ($class, $to_run, @groups) = @_;

  unshift @groups, '' unless grep { $_ eq '' } @groups;
  my $group_places = join ',', ('?')x(scalar @groups);

  my $sth = $class->sql_runnable(
      '*', $group_places,
      '   AND GET_LOCK(CONCAT("runnable",id),0)
      ORDER by next_run_epoch LIMIT 1'
    );

  my ($obj) = $class->sth_to_objects( $sth, \@groups );
  return unless $obj;

  if ($to_run) {
    my $run_until = time;
    if (my $max = $obj->max_run_time) {
      $run_until += $max * 1.5;
    } else {
      $run_until += 24 * 60 * 60;
    }

    $obj->running_until_epoch( $run_until );
    $obj->update;
  }

  $class
    ->sql_single("RELEASE_LOCK(CONCAT('runnable',$obj->{id}))")
    ->select_val();

  $obj->{__started_at} = time;

  return $obj;
}

sub runned {
  my ($self, $status) = @_;

  $self->running_until_epoch( 0 );
  if ($status eq 'ok') {
    $self->error_cnt(0);
    $self->last_run_ok_epoch( $self->{__started_at} || time );
  } else {
    $self->error_cnt( $self->error_cnt + 1 );
    $self->flags('failing')
      if $self->error_cnt >= 3;
  }
  
  if ($self->{__started_at} and $self->flags !~/faling/) {
    my $runtime = time - $self->{__started_at} + 1;
    if ($runtime > $self->max_run_time) {
      $self->max_run_time( $runtime );
    }
  }
  
  $self->_set_run_next();
  $self->update();

  return;
}

sub add_output {
  my ($self, $exitcode, $output) = @_;

  my $out = Hercules::Db::Output->find_or_create( cronjob_id => $self->id );

  $out->server_name( hostname );
  $out->run_epoch( $self->{__started_at} || time );
  $out->exit_code( $exitcode );
  $out->output( $output );

  $out->update;

  return;
}

sub get_next_run_for_group {
  my ($class, $group) = @_;

  return unless $group;
  my ($next_run) = $class->sql_next_run()->select_val($group);

  return $next_run;
}

my %durationparam = (
  s => 'seconds',
  m => 'minutes',
  h => 'hours',
  d => 'days',
  w => 'weeks',
  M => 'months',
  y => 'years',
);
my %small_unit = map { $_ => 1 } qw( s m h );
sub _set_run_next {
  my $self = shift;

  my $next;
  if (my $every = $self->run_every) {
    my ($time,$unit) = $every =~ m{^(\d+)(\w)?$};
    $unit ||= 'd';
    my $dt;
    if ($time and $durationparam{$unit}) {      
      if ($small_unit{$unit} or (time-$self->next_run_epoch)>3600) {
        $dt = DateTime->now();
      } else {
        $dt = DateTime->from_epoch( $self->next_run_epoch );
      }
      $dt->add( $durationparam{$unit} => $time );
      $next = $dt->epoch();
    }
  } elsif ( $self->run_schedule() ) {
    eval {
      require DateTime::Event::Cron;
      my $dtc = DateTime::Event::Cron->new_from_cron(
                cron=> $self->run_schedule
              );
      $next = $dtc->next->epoch;
    };
  }

  if ($next) {
    $self->next_run_epoch( $next );
  } else {
    $self->next_run_epoch( 0 );
    $self->flags('unscheduled'); #maybe we need a set_flags in the future
  }

  return;
}

sub group_stats {
  my ($class) = @_;

  my $sth = $class->sql_group_stats();
  $sth->execute();
  
  my %stats;
  $sth->bind_columns(\my ($group, $flags,$runnable, $next_run, $count));
  while ( $sth->fetch() ) {
    $stats{ $group//'' }{ $flags }{ $runnable } = {
        group     => $group,
        flags     => $flags,
        runnable  => $runnable,
        next_run  => $next_run,
        count     => $count,
      };
  }

  return wantarray ? %stats : \%stats;
}

1;
__END__
