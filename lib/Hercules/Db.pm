package Hercules::Db;

use base 'Class::DBI';
use Hercules::Config qw(config);

my %dbinfo = config('database');

Hercules::Db->connection(
    "dbi:mysql:$dbinfo{dbname}",
    $dbinfo{dbuser},
    $dbinfo{dbpass}
  );

DBI->trace("3|SQL")
  if $dbinfo{trace};

1;
__END__
