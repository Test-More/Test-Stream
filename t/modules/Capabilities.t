use strict;
use warnings;
use Test::Sync::Tester;

use Test::Sync::Capabilities qw/CAN_FORK CAN_THREAD/;

# Make sure running them does not die
# We cannot really do much to test these.
CAN_THREAD();
CAN_FORK();

ok(1);

done_testing;
