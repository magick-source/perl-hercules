package Hercules::Db::Output;

use strict;
use warnings;

use parent 'Hercules::Db';

__PACKAGE__->table('cronjob_output');

__PACKAGE__->columns( Primary => 'cronjob_id' );

__PACKAGE__->columns( Essential => qw(
  cronjob_id
  server_name
  run_epoch
  exit_code
  output
));

1;
__END__

