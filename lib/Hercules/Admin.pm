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

  my $r = $self->routes;

  $r->route('/')->to('dashboard#index');

}

1;
