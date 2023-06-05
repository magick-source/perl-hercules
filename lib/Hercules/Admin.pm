package Hercules::Admin;

use Mojo::Base qw'Mojolicious';

use Hercules::Config qw(config);

has sitetitle => 'Hercules Admin';

sub startup {
  my $self = shift;

  $self->log->level('debug');

  $self->defaults->{site_title} = $self->sitetitle;
  $self->defaults->{title} = '';
  $self->defaults->{debug_dump} = '';
  $self->defaults->{hercules_version} = $Hercules::Config::VERSION;

  my $r = $self->routes;

  $r->any('/')->to('dashboard#index');

  # groups
  $r->any('/groups/')->to('groups#list');
  $r->any('/group/:group/reelect')->to('groups#reelect');
  $r->any('/group/:group/change')->to('groups#change');
  $r->any('/group/new/')->to('groups#new_group');

  # jobs
  $r->any('/jobs/')->to('jobs#list');
  $r->any('/jobs/:group')->to('jobs#list');
  $r->any('/job/new')->to('jobs#new_job');
  $r->any('/job/add')->to('jobs#save');
  $r->any('/job/:job')->to('jobs#view');
  $r->any('/job/:job/start')->to('jobs#start');
  $r->any('/job/:job/stop')->to('jobs#stop');
  $r->any('/job/:job/edit')->to('jobs#edit');
  $r->any('/job/:job/save')->to('jobs#save');

}

1;
