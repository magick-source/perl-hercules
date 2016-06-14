package Hercules::Admin::Jobs;

use Mojo::Base qw(Mojolicious::Controller);

use Hercules::Db::Schedule;

use Hercules::Utils qw(
  seconds_to_timeunits
);

# my %status2db = (
#   active  => { flags => { -like => "%active%" }},
#   ok      => { flags => { -like => "%active%" },
#                next_run_epoch  => {'>=' => 'UNIX_TIMESTAMP()'}
#              },
#   behind  => { flags => { -like => "%active%" },
#                next_run_epoch  => {'<' => 'UNIX_TIMESTAMP()'},
#              },
#   failed  => { flags => {'-like' => "%failed%"} },
# );

sub list {
  my ($c) = @_;

  my $stash = $c->stash;
  $stash->{title} = 'Jobs - list';

  my $status = $c->param('status');
  my $search = $c->param('search');
  my $group  = $stash->{group};

  my %search;
  if ($status) {
    %search = %{ $status2db{ $status } || {} };
  }
  if ( $group ) {
    $search{ cron_group } = $group;
  }
  if ( $search ) {
    $search{ name } = { -like => "%$search%" };
  }

  my @jobs;
#   = Hercules::Db::Schedule->search(
#       \%search,
#       { columns => [qw(
#               id
#               name
#               cron_group
#               last_run_ok_epoch
#               next_run_epoch
#               running_until_epoch
#               flags
#           )],
#       }
#     );

  $stash->{ jobs } = \@jobs;
  $stash->{ search } = $search;
  $stash->{ status } = $status;

  $c->render( template => 'jobs/list' );
}

1;
