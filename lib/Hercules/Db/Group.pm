package Hercules::Db::Group;

use strict;
use warnings;

use parent 'Hercules::Db';

use Hercules::Db::Schedule;

use Sys::Hostname;

__PACKAGE__->table('cronjob_group');

__PACKAGE__->columns( Primary => 'group_name' );

__PACKAGE__->columns( ALL => qw(
  group_name
  max_parallel_jobs
  server_name
  elected_epoch
  last_run_start_epoch
  next_run_start_epoch
  re_elect_epoch
));

__PACKAGE__->set_sql( electable => q{
SELECT * FROM __TABLE__
  WHERE re_elect_epoch < ?
    AND server_name != ?
    AND GET_LOCK(CONCAT('relect','=',group_name),0)
  LIMIT 1
});

__PACKAGE__->set_sql(list => q{
SELECT * FROM __TABLE__
  WHERE group_name like ?
    AND group_name >= ?
 ORDER BY group_name
 LIMIT 50
});

__PACKAGE__->set_sql( select_group_list => q{
SELECT group_name, max_parallel_jobs, server_name
  FROM __TABLE__
  ORDER by IF(elected_epoch,elected_epoch,UNIX_TIMESTAMP()) DESC
});

sub elect_group {
  my ($class) = @_;

  my $servername = hostname();
  
  my $sth = $class->sql_electable();
  my ($group) = $class->sth_to_objects($sth, [time, $servername]);

  return unless $group;

  $group->server_name( $servername );
  $group->elected_epoch( time );
  $group->re_elect_epoch( time + 300 ); # 5 minutes to take over
  $group->update();

  $class
    ->sql_single("RELEASE_LOCK(CONCAT('relect','=',?))")
    ->select_val( $group->group_name );

  return $group;
}

sub make_electable {
  my ($self) = @_;

  $self->re_elect_epoch( time );
  $self->server_name('');
  $self->update();

  return;
}

sub get_my_groups {
  my ($class) = @_;

  my $server_name = hostname();
  my @groups = $class->search(
      server_name => $server_name,
    );

  return wantarray ? @groups : \@groups;
}

sub running_job {
  my ($self) = @_;

  my ($next_run) = Hercules::Db::Schedule
      ->get_next_run_for_group( $self->group_name );
  $next_run ||= time;

  $self->last_run_start_epoch( time );
  $self->next_run_start_epoch( $next_run );
  $self->re_elect_epoch( $next_run + 300 );
  $self->update;

  return;
}

sub runned_job {
  my ($self) = @_;

  my ($next_run) = Hercules::Db::Schedule
    ->get_next_run_for_group( $self->group_name );
  $next_run ||= time;

  $self->next_run_start_epoch( $next_run );
  $self->re_elect_epoch( $next_run + 300 );
  $self->update;

  return;
}

sub list_groups_like {
  my ($class, $search, $after) = @_;

  $search ||= '%';

  my $sth = $class->sql_list();
  $sth->execute( "%$search%", $after );

  return $class->sth_to_objects( $sth );
}

sub get_jobs {
  my ($self) = @_;
  
  return Hercules::Db::Schedule->jobs_for_group( $self->group_name );
}

sub rename {
  my ($self, $new_name) = @_;


  print STDERR "'$new_name' doesn't match\n"
    unless $new_name =~ m{\A\w[\w\-_]*\w\z};

  return unless $new_name =~ m{\A\w[\w\-_]*\w\z};

  my @jobs = $self->get_jobs();
  $self->copy( $new_name );

  for my $job (@jobs) {
    $job->cron_group( $new_name );
    $job->update;
  }

  $self->delete;

  return;
}

sub all_groups {
  my ($class) = @_;

  my $sth = $class->sql_select_group_list();
  $sth->execute();
  $sth->bind_columns(\my ($name, $jobs, $server));
  my @groups;
  while ($sth->fetch()) {
    push @groups, {
        name      => $name,
        max_jobs  => $jobs,
        server    => $server
      };
  }

  return wantarray ? @groups : \@groups;
}

1;
__END__

