use strict;
use warnings;
use Test::Sync::Tester;
use Test::Sync::Event::Exception;

my $exception = Test::Sync::Event::Exception->new(
    debug => 'fake',
    error => "evil at lake_of_fire.t line 6\n",
);

ok($exception->causes_fail, "Exception events always cause failure");

require Test::Sync::State;
my $state = Test::Sync::State->new;
ok($state->is_passing, "passing");
ok(!$state->failed, "no failures");

$exception->update_state($state);

ok(!$state->is_passing, "not passing");
ok($state->failed, "failure added");

done_testing;
