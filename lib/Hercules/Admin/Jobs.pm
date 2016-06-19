package Hercules::Admin::Jobs;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Group;
use Hercules::Db::Schedule;

use Hercules::Utils qw(
  epoch_to_datetime
  seconds_to_timeunits
  stash_core_job_classes
);

my %status2icon   = ( 
  failing => 'times',
  running => 'rocket',
  ok      => 'check',
  delayed => 'clock-o',
  stopped => 'pause',
);

my %status2panel = (
  failing => 'red',
  running => 'primary',
  ok      => 'green',
  delayed => 'yellow',
  stopped => 'default'
);

sub list {
  my ($c) = @_;

  my $stash = $c->stash;
  $stash->{title} = 'Jobs - list';

  my $status = $c->param('status');
  my $search = $c->param('search');
  my $group  = $stash->{group};

  my %search;

  my @jobs = Hercules::Db::Schedule->list_jobs_like(
      status  => $status,
      search  => $search,
      group   => $group,
    );

  for my $job (@jobs) {
      $job->{last_run_tu} = $job->{last_run_ok_epoch}
        ? seconds_to_timeunits( time - $job->{last_run_ok_epoch} )
            .' ago'
        : '';
      my $next_run = $job->{next_run_epoch};
      if (($job->{running_until_epoch}||0) > time) {
        $job->{next_run_tu} = 'running';
      } else {
        $job->{next_run_tu} = $next_run
          ? $next_run < time
            ? 'late '. seconds_to_timeunits( time - $next_run )
            : 'in '  . seconds_to_timeunits( $next_run - time )
          : '';
      }
      $job->{status}  = $job->status;
		  $job->{icon}    = $status2icon{ $job->status };
  }

  $stash->{ jobs } = \@jobs;
  $stash->{ param_search } = $search;
  $stash->{ param_status } = $status;

  use Data::Dumper;
  $stash->{debug_dump} = Dumper(\@jobs);

  $c->render( template => 'jobs/list' );
}

sub start {
  my ($c) = @_;
  my $stash = $c->stash;
  
  my $jobname = $stash->{job};
  my ($job) = Hercules::Db::Schedule->retrieve(name => $jobname);

  return $c->render->not_found
    unless $job;

  my %flags = map { $_ => 1 } split /\s*,\s*/, $job->flags;
  $flags{active} = 1;
  delete $flags{failing};
  $job->flags( join ',', keys %flags);
  $job->error_cnt(0);
  $job->update;

  $c->render(text => 'ok, maybe');
}

sub stop {
  my ($c) = @_;
  my $stash = $c->stash;

  my $jobname = $stash->{job};
  my ($job) = Hercules::Db::Schedule->retrieve(name => $jobname);

  return $c->render->not_found
    unless $job;

  my %flags = map { $_ => 1 } split /\s*,\s*/, $job->flags;
  delete $flags{active};
  $job->flags( join ',', keys %flags);
  $job->update;

  $c->render(text => 'ok, maybe');
}

sub view {
  my ($c) = @_;
  my $stash = $c->stash;

  my $jobname = $stash->{job};
  my ($job) = Hercules::Db::Schedule->retrieve(name => $jobname);

  return $c->render->not_found
    unless $job;

  for my $fld (qw(last_run_ok_epoch running_until_epoch next_run_epoch)) {
    $job->{$fld.'_dt'} = epoch_to_datetime( $job->{$fld} );
  }
  $job->{panel_class} = $status2panel{ $job->status } || 'danger';
  if ($job->{running_until_epoch}) {
    $job->{running_until_epoch_tu}
        = 'in '.seconds_to_timeunits( $job->{running_until_epoch} - time );
    $job->{now_running} = 1;
  }
  if ($job->{next_run_epoch}) {
    $job->{next_run_epoch_tu}
      = $job->{next_run_epoch} >= time
        ? 'in '.seconds_to_timeunits($job->{next_run_epoch} - time)
        : 'late '.seconds_to_timeunits(time - $job->{next_run_epoch});
  }
  
 
  $stash->{job} = $job;

  my $output = $job->get_output();
  my $out = $stash->{job_output} = $output 
    ? {%{ $output }}
    : 0;

  if ($out and $out->{run_epoch}) {
    $out->{run_epoch_tu} = seconds_to_timeunits( $out->{run_epoch}, 3 );
    $out->{run_epoch_dt} = epoch_to_datetime( $out->{run_epoch} );
  }

  $c->render( template => 'jobs/view' );
}

sub edit {
  my ($c) = @_;
  my $stash = $c->stash;

  my $jobname = $stash->{job};
  my ($job) = Hercules::Db::Schedule->retrieve(name => $jobname);

  return $c->render->not_found
    unless $job;

  $stash->{job} = $job;

  $job->{params_as_text} = $job->params_as_text;

  $job->{usecoreclass} = $job->{class} =~ m{Hercules::Job::} ? 1 : 0;

  _stash_groups( $c );
  stash_core_job_classes( $c );

  use Data::Dumper;
  $stash->{debug_dump} = Dumper( $c->stash );

  $c->render(template => 'jobs/edit');
}

sub _stash_groups {
  my ($c) = @_;

  $c->stash->{all_groups} = Hercules::Db::Group->all_groups;
}

1;
