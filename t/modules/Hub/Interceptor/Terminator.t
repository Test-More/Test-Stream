use strict;
use warnings;
use Test::Sync::Tester;

use Test::Sync::Hub::Interceptor::Terminator;

ok($INC{'Test/Sync/Hub/Interceptor/Terminator.pm'}, "loaded");

done_testing;
