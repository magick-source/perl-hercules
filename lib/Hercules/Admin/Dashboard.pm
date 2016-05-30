package Hercules::Admin::Dashboard;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Group;
use Hercules::Db::Schedule;

use Hercules::Utils qw(
  epoch_to_datetime
  seconds_to_timeunits
);

use Data::Dumper;

my %runningstatus = map { $_ => 1 } qw(
    active
  );

sub index {
  my ($c) = @_;

  my $stash = $c->stash;

  my @groups = Hercules::Db::Group->retrieve_all({columns=>'All'});
  $stash->{groups_count} = scalar @groups;

  my %group_stats = Hercules::Db::Schedule->group_stats();

  my @ginfo;
  for my $group (@groups) {

    my $rec = {
        name            => $group->group_name,
        server          => $group->server_name,
        elected         => $group->elected_epoch,
        reelect         => $group->re_elect_epoch,
        last_job_start  => $group->last_run_start_epoch,
        next_job_start  => $group->next_run_start_epoch,
      };

      for my $fld (qw(elected reelect last_job_start next_job_start)) {
        $rec->{$fld.'_dt'} = epoch_to_datetime( $rec->{$fld} );
      }
      $rec->{'next_job_start_tu'} = $rec->{next_job_start} < time
          ? 'late '. seconds_to_timeunits( time - $rec->{next_job_start} )
          : 'in '  . seconds_to_timeunits( $rec->{next_job_start} - time );
      $rec->{'last_job_start_tu'}
          = seconds_to_timeunits(time - $rec->{last_job_start} ). ' ago';

      $rec->{ runnable_jobs } 
        = $group_stats{$group}->{ active }->{ 1 }->{ count } // 0;
      $rec->{ failing_jobs } 
        = $group_stats{$group}->{ failing }->{ 1 }->{ count } // 0;
      $rec->{ active_jobs } 
        = $group_stats{$group}->{ active }->{ 0 }->{ count } // 0;

      push @ginfo, $rec;
  }

  if ($group_stats{''}) {
    my $last_run = 0;
    my $next_run = undef;
    for my $status (keys %{ $group_stats{''} }) {
      for my $runnable (keys %{ $group_stats{''}{ $status } }) {

        next unless $runningstatus{ $status };
        $last_run = $group_stats{''}{$status}{$runnable}{last_run}
          if  $group_stats{''}{$status}{$runnable}{last_run} > $last_run;

#         next unless $runnable;
        $next_run = $group_stats{''}{$status}{$runnable}{next_run}
          if !$next_run
            or $group_stats{''}{$status}{$runnable}{next_run} < $next_run;
      }
    }
    
    my $runnable_jobs
      = $group_stats{''}->{ active }->{ 1 }->{ count } // 0;
    my $failing_jobs
      = $group_stats{''}->{ failing }->{ 1 }->{ count } // 0;
    my $jobs_ok
      = $group_stats{''}->{ active }->{ 0 }->{ count } // 0;

    my $last_run_tu = seconds_to_timeunits( time - $last_run );
    $last_run_tu .= ' ago';
    my $next_run_tu = $next_run < time
        ? 'late '. seconds_to_timeunits( time - $next_run )
        : 'in '  . seconds_to_timeunits( $next_run - time );

    push @ginfo, {
        name              => '',
        server            => '*',
        elected           => '',
        reelect           => '',
        elected_dt        => '',
        reelect_dt        => '',
        last_job_start    => $last_run,
        last_job_start_dt => epoch_to_datetime( $last_run ),
        last_job_start_tu => $last_run_tu,
        next_job_start    => $next_run,
        next_job_start_dt => epoch_to_datetime( $next_run ),
        next_job_start_tu => $next_run_tu,
        runnable_jobs     => $runnable_jobs,
        failing_jobs      => $failing_jobs,
        active_jobs       => $jobs_ok,
      };
  }

  @ginfo = sort {
          $b->{runnable_jobs}   <=> $a->{runnable_jobs}
      ||  $b->{next_job_start}  <=> $a->{next_job_start}
    } @ginfo;

  my ($jobs_behind, $jobs_ok, $jobs_failed, $max_late) = (0,0,0,0);

  for my $group (@ginfo) {
    $jobs_behind += $group->{runnable_jobs} || 0;
    $jobs_ok     += $group->{active_jobs}   || 0;
    $jobs_failed += $group->{failing_jobs}  || 0;
    $max_late     = $group->{next_job_start}
      if !$max_late or $max_late > $group->{next_job_start};
  }
  if ($max_late) {
    $max_late = time - $max_late;
  }
  my $max_late_time
    = seconds_to_timeunits( $max_late > 0 ? $max_late : -$max_late );
  
  $stash->{counters} = {
    max_late      => $max_late,
    max_late_time => $max_late_time,
    jobs_active   => ( $jobs_ok + $jobs_behind ),
    jobs_ok       => $jobs_ok,
    jobs_behind   => $jobs_behind,
    jobs_failed   => $jobs_failed,
    job_groups    => scalar @ginfo,
  };

  $stash->{cron_groups} = \@ginfo;

  my @jobs = Hercules::Db::Schedule->last_jobs_by_status('active');
  for my $job (@jobs) {
    my $run_until = $job->running_until_epoch;
    my $next_run = $run_until > time ? $run_until : $job->next_run_epoch;
    $job->{next_run} = $next_run;
  
    $job->{'next_run_tu'} = $job->{next_run} < time
          ? 'late '. seconds_to_timeunits( time - $job->{next_run} )
          : 'in '  . seconds_to_timeunits( $job->{next_run} - time );
    $job->{'last_run_tu'}
          = $job->{last_run_ok_epoch} 
            ? seconds_to_timeunits(time - $job->{last_run_ok_epoch} )
                . ' ago'
            : 'never';
  }
  $stash->{last_runned} = [ @jobs ];
  
  @jobs = Hercules::Db::Schedule->last_jobs_by_status('failing');
  for my $job (@jobs) {
    my $run_until = $job->running_until_epoch;
    my $next_run = $run_until > time ? $run_until : $job->next_run_epoch;
    $job->{next_run} = $next_run;
  
    $job->{'next_run_tu'} = $job->{next_run} < time
          ? 'late '. seconds_to_timeunits( time - $job->{next_run} )
          : 'in '  . seconds_to_timeunits( $job->{next_run} - time );
    $job->{'last_run_tu'}
          = $job->{last_run_ok_epoch} 
            ? seconds_to_timeunits(time - $job->{last_run_ok_epoch} )
                . ' ago'
            : 'never';
  }
  $stash->{last_failed} = [ @jobs ];

  $c->render(template=>'index');
}

1;

