package Hercules::Job::HTTPGet;

use strict;
use warnings;

use HTTP::Tiny;

sub main {
  my ($self,%params) = @_;

  my $url  = delete $params{url};
  die "Missing parameter 'url'\n"
    unless $url;

  my $resp = HTTP::Tiny->new()->get($url);
  if ($resp->{success}) {
    print STDERR "Got '$url' with success\n";
    return;
  }

  print STDERR "$resp->{status} $resp->{reason}\n";
  print STDERR "$_: $resp->{headers}->{$_}\n"
    for keys %{ $resp->{headers} };
  print STDERR "\n\n";
  print STDERR $resp->{content} if length($resp->{content});
  
  die "Failed to get '$url'\n";

}

1;
__END__

