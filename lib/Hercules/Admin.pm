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

  $r->route('/groups/')->to('groups#list');
  $r->route('/group/:group/reelect')->to('groups#reelect');
  $r->route('/group/:group/rename')->to('groups#rename');
}

1;
