package Hercules::Admin::Dashboard;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Group;
use Hercules::Db::Schedule;

use Hercules::Utils qw(
  epoch_to_datetime
);

use Data::Dumper;

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

      $rec->{ runnable_jobs } 
        = $group_stats{$group}->{ active }->{ 1 }->{ count } // 0;
      $rec->{ failing_jobs } 
        = $group_stats{$group}->{ failing }->{ 1 }->{ count } // 0;

      my @jobs = 

      push @ginfo, $rec;
  }

  if ($group_stats{''}) {
    my $last_run = 0;
    my $next_run = undef;
    for my $status (keys %{ $group_stats{''} }) {
      for my $runnable (keys %{ $group_stats{''}{ $status } }) {
        $last_run = $group_stats{''}{$status}{$runnable}{last_run}
          if  $group_stats{''}{$status}{$runnable}{last_run} > $last_run;

        $next_run = $group_stats{''}{$status}{$runnable}{next_run}
          if !$next_run
            or $group_stats{''}{$status}{$runnable}{next_run} < $next_run;
      }
    }
    
    my $runnable_jobs
      = $group_stats{''}->{ active }->{ 1 }->{ count } // 0;
    my $failing_jobs
      = $group_stats{''}->{ failing }->{ 1 }->{ count } // 0;

    push @ginfo, {
        name              => '',
        server            => '*',
        elected           => '',
        reelect           => '',
        elected_dt        => '',
        reelect_dt        => '',
        last_job_start    => $last_run,
        last_job_start_dt => epoch_to_datetime( $last_run ),
        next_job_start    => $next_run,
        next_job_start_dt => epoch_to_datetime( $next_run ),
        runnable_jobs     => $runnable_jobs,
        failing_jobs      => $failing_jobs,
      };
  }

  @ginfo = sort {
          $b->{runnable_jobs}   <=> $a->{runnable_jobs}
      ||  $b->{next_job_start}  <=> $a->{next_job_start}
    } @ginfo;

  $stash->{debug_dump} = Dumper(\@ginfo);

  $c->render(template=>'index');
}

1;

