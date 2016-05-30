package Hercules::Utils;

use base qw'Exporter';

use strict;
use warnings;

use Hercules::Config qw(config);

use POSIX qw(strftime);

our @EXPORT_OK = qw(
  epoch_to_datetime
  seconds_to_timeunits
);

my %date_formats = (
  iso   => '%F %T',
  http  => '%a, %d %b %Y %T',
);

my %second_units = (
  1                 => 's',
  60                => 'm',
  60 * 60           => 'h',
  24 * 60 * 60      => 'd',
  365* 24 * 60 * 60 => 'y',
);

my $timeformat;
my $localtime;

sub epoch_to_datetime {
  my $epoch = shift;

  unless ($timeformat) {
    $timeformat = config('display','datetime_format') || 'iso';

    if ($timeformat and $date_formats{ $timeformat } ) {
      $timeformat = $date_formats{ $timeformat };
    }
  }
  unless (defined $localtime) {
    $localtime = config('display','use_localtime') // 1;
  }

  my $time;
  if ($localtime) {
    $time = strftime( $timeformat, localtime($epoch) );
  } else {
    $time = strftime( $timeformat, gmtime($epoch) );
  }

  return $time;
}

sub seconds_to_timeunits {
  my ($seconds, $units) = @_;
  $units ||= 1;
  my $res = '';

  for my $secs (sort {$b <=> $a} keys %second_units) {
    next if $seconds < $secs;
    $res .= ' ' if $res;

    my $unit = int($seconds/$secs);
    $seconds = $seconds % $secs;

    $res .= $unit .$second_units{ $secs };

    last unless --$units;
  }

  return $res;
}

1;
