use strict;
use warnings;
use Test::Sync::Tester;

use Test::Sync::Hub::Interceptor;

my $one = Test::Sync::Hub::Interceptor->new();

ok($one->isa('Test::Sync::Hub'), "inheritence");;

my $e = exception { $one->terminate(55) };
ok($e->isa('Test::Sync::Hub::Interceptor::Terminator'), "exception type");
is($$e, 55, "Scalar reference value");

done_testing;
