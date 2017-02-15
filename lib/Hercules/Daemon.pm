package Hercules::Daemon;

use parent qw(Parallel::Dragons);

use Hercules::Db::Schedule;
use Hercules::Db::Group;

sub wait_before_restart { 1 }

sub max_childs {
  my ($self) = @_;
  return $self->server_cores;
}

my $count = 0;
my $next_count_epoch = 0;
my $count_groups = '';

sub _group_names {
  my ($self) = @_;

  my @groups = @{ $self->{__cron_groups} ||= [] };

  @groups = grep {
          !$_->{max_parallel_jobs}
      or  $_->{max_parallel_jobs}
            < ( $self->{_group_running}->{ $_->{group_name} } || 0 )
    } @groups;

  my @gnames = map { $_->{group_name} } @groups;

  return @gnames;
}

sub need_childs {
  my ($self) = shift;

  my @gnames = _group_names( $self );
  my $gnames = join ',', @gnames;

  my $needed = $self->childs_running;
  if ($next_count_epoch<time or $count_groups ne $gnames) {
    $count = Hercules::Db::Schedule->count_runnable( @gnames );
    $next_count_epoch = time + 10;
    $count_groups     = $gnames;
    print STDERR "$$: have $count runnable crons\n"
      if $count;
  }
  if ($count > 0) {
    $needed++;
    $count--;
  }

  return $needed;
}

sub pre_start {
  my ($self) = @_;

  return if $self->is_foreground();

  my $dirname = $self->sockfile();
  $dirname .= '-tmp';
  mkdir $dirname unless -d $dirname;

  $self->{tmpdir} = $dirname;
  $self->{_group_running} = {};

  _idle_update_groups( $self );

  return;
}

my %idle_meths = (
  10  => \&_idle_elect_groups,
  45  => \&_idle_update_groups,
);
sub idle {
  my ($self) = @_;

  if (my $meth = $idle_meths{int(rand(100))}) {
    $meth->( $self );
  }

  return;
}

sub _idle_elect_groups {
  my ($self) = @_;

  Hercules::Db::Group->elect_group();

  _idle_update_groups( $self );
}

sub _idle_update_groups {
  my ($self) = @_;

  my $groups = $self->{__cron_groups} ||= [];

  @$groups = Hercules::Db::Group->get_my_groups();

  return;
}

sub pre_fork {
  my ($self) = @_;

  my @gnames = _group_names( $self );
  my $cron = Hercules::Db::Schedule->get_runnable(1, @gnames);
  $self->{cron} = $cron;

  if ( $cron and my $gname = $cron->cron_group() ) {
    my ($group) = grep {
        $_->group_name eq $gname
      } @{ $self->{__cron_groups} };
    
    if ($group) {
      $group->running_job();
    }
  }
}

sub post_child_start {
  my ($self, $child) = @_;

  my $cron
    = $self->{_cron_running}->{ $child->{pid} }
    = delete $self->{cron};

  $self->{_group_running}->{ $cron->cron_group }++;

  return;
}

sub post_child_exit {
  my ($self, $child) = @_;

  my $cron = delete $self->{_cron_running}->{ $child->{pid} };
  return unless $cron;

  $self->{_group_running}->{ $cron->cron_group }--;

  print "$$: A child Ended\n";
  my $log;
  {
    my $child_pid = $child->{pid};
    my $child_log = $self->{tmpdir}."/$child_pid.out";
    open my $fh, '<', $child_log;
    my $printed_head = 0;
    while (my $ln = <$fh>) {
      unless ($printed_head) {
        print STDERR "$child_pid>>> output of '$cron->{name}'\n";
        $printed_head++;
      }
      $log .= $ln;
      print STDERR "$child_pid>>> $ln";
    }
    close $fh;
    unlink $child_log;
  }
  $cron->add_output( $child->{exit_code}, $log );

  if (my $gname = $cron->cron_group ) {
    my ($group) = grep {
        $_->group_name eq $gname
      } @{ $self->{__cron_groups} };
    if ($group) {
      $group->runned_job();
    }
  }
}

sub init_child {
  my ($self) = @_;
  return if $self->is_foreground;
  
  open LOG, '>', $self->{tmpdir}."/$$.out";
  *STDERR = *STDOUT = *LOG;
}

sub main {
  my $self = shift;

  my $cron = $self->{cron};
  return unless $cron;

  my $name = $cron->name;
  my $class = $cron->class;
  my $status = 'ok';

  eval {
    eval "require $class; 1" or do { my $err=$@; die "die on load: $err"; };

    $class->main( %{ $cron->params } );

    1;
  } or do {
    my $err = $@;
    print STDERR "Cron failed:\n$err\n\n";
    $status = 'failed';
  };

  $cron->runned( $status );

  return;
}

1;
__END__

