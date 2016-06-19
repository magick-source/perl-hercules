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

  $r->route('/')->to('dashboard#index');

  # groups
  $r->route('/groups/')->to('groups#list');
  $r->route('/group/:group/reelect')->to('groups#reelect');
  $r->route('/group/:group/change')->to('groups#change');
  $r->route('/group/new/')->to('groups#new_group');

  # jobs
  $r->route('/jobs/')->to('jobs#list');
  $r->route('/jobs/:group')->to('jobs#list');
  $r->route('/job/:job')->to('jobs#view');
  $r->route('/job/:job/start')->to('jobs#start');
  $r->route('/job/:job/stop')->to('jobs#stop');
  $r->route('/job/:job/edit')->to('jobs#edit');
  $r->route('/job/:job/save')->to('jobs#save');

}

1;
