package Hercules::Utils;

use base qw'Exporter';

use Hercules::Config qw(config);

use POSIX qw(strftime);

our @EXPORT_OK = qw(
  epoch_to_datetime
);

my %date_formats = (
  iso   => '%F %T',
  http  => '%a, %d %b %Y %T',
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

1;
