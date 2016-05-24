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


  $stash->{debug_dump} = Dumper(\@ginfo);

  $c->render(template=>'index');
}

1;

