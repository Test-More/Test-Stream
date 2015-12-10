use Test::Sync -V1;

use Test::Sync::Event::Bail;

use Test::Sync::Formatter::TAP qw/OUT_STD/;

my $bail = Test::Sync::Event::Bail->new(
    debug => 'fake',
    reason => 'evil',
);

ok($bail->causes_fail, "balout always causes fail.");

warns {
    is(
        [$bail->to_tap(1)],
        [[OUT_STD, "Bail out!  evil\n" ]],
        "Got tap"
    );
};

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
