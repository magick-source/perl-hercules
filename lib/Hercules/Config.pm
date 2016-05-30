package Hercules::Config;

our $VERSION = '0.1.0';

use Config::RecurseINI 'hercules' => qw(config);

use parent 'Exporter';

our @EXPORT_OK = qw(config);

1;
__END__

