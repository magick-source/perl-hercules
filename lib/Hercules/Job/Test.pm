package Hercules::Job::Test;

use strict;
use warnings;

sub main {
  my ($self,%params) = @_;

  my $loop = delete $params{loop} || 3;
  my $wait = delete $params{wait} || 1;

  for my $l (1..$loop) {
    print STDERR "loop $l - going to sleep $wait secs\n";
    sleep $wait;
  }

  return;
}

1;
__END__

