use Test::Sync -V1, Compare => '*';

use Test::Sync::Hub::Interceptor;

my $one = Test::Sync::Hub::Interceptor->new();

isa_ok($one, 'Test::Sync::Hub::Interceptor', 'Test::Sync::Hub');

is(
    dies { $one->terminate(55) },
    object {
        prop 'blessed' => 'Test::Sync::Hub::Interceptor::Terminator';
        prop 'reftype' => 'SCALAR';
        prop 'this' => \'55';
    },
    "terminate throws an exception"
);

done_testing;
