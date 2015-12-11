use strict;
use warnings;
use Test::Sync::Tester;
use Test::Sync::Event::Bail;

my $bail = Test::Sync::Event::Bail->new(
    debug => 'fake',
    reason => 'evil',
);

ok($bail->causes_fail, "balout always causes fail.");

is($bail->terminate, 255, "Bail will cause the test to exit.");
is($bail->global, 1, "Bail is global, everything should bail");

require Test::Sync::State;
my $state = Test::Sync::State->new;
ok($state->is_passing, "passing");
ok(!$state->failed, "no failures");

$bail->update_state($state);

ok(!$state->is_passing, "not passing");
ok($state->failed, "failure added");

done_testing;
