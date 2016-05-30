package Hercules::Admin::Groups;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Group;

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
  $stash->{title} = 'Groups - list';

  my $search    = $c->param('search');
  my $after     = $c->param('after_name') // '';

  $stash->{search} = $search;

  my @groups    = Hercules::Db::Group->list_groups_like(
      $search, $after
    );

  for my $group (@groups) {
    $group->{last_run_tu}
      = seconds_to_timeunits( time - $group->{last_run_start_epoch} )
        . ' ago';
    
    my $next_run = $group->{next_run_start_epoch};
    $group->{next_run_tu}
      = $next_run < time
        ? 'late '. seconds_to_timeunits( time - $next_run )
        : 'in '  . seconds_to_timeunits( $next_run - time );
  
    $group->{jobs} = [];
    my @jobs =  $group->get_jobs;
    if (@jobs) {
      for my $job (@jobs) {
        push @{ $group->{jobs} }, {
            name    => $job->name,
            status  => $job->status,
            icon    => $status2icon{ $job->status },
          };
      }
    }
  }

  $stash->{groups} = \@groups;
  
  use Data::Dumper;
  $stash->{debug_dump} = Dumper(\@groups);

  $c->render( template => 'groups/list' );
}

1;

