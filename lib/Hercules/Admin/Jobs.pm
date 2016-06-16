package Hercules::Admin::Jobs;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Schedule;

use Hercules::Utils qw(
  seconds_to_timeunits
);

my %status2icon   = ( 
  failing => 'times',
  running => 'rocket',
  ok      => 'check',
  delayed => 'clock-o',
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
      $job->{next_run_tu} = $next_run
        ? $next_run < time
          ? 'late '. seconds_to_timeunits( time - $next_run )
          : 'in '  . seconds_to_timeunits( $next_run - time )
        : '';
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

1;
