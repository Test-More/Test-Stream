use strict;
use warnings;

use Test::Sync::Tester;
use Test::Sync::Event::Plan;
use Test::Sync::DebugInfo;
use Test::Sync::State;

my $plan = Test::Sync::Event::Plan->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 100,
);

ok(!$plan->global, "regular plan is not a global event");
my $state = Test::Sync::State->new;
$plan->update_state($state);
is($state->plan, 100, "set plan in state");
is($plan->terminate, undef, "No terminate for normal plan");

$plan->set_max(0);
$plan->set_directive('SKIP');
$plan->set_reason('foo');
ok($plan->global, "plan is global on skip all");
$state = Test::Sync::State->new;
$plan->update_state($state);
is($state->plan, 'SKIP', "set plan in state");
is($plan->terminate, 0, "Terminate 0 on skip_all");

$plan->set_max(0);
$plan->set_directive('NO PLAN');
$plan->set_reason(undef);
$state = Test::Sync::State->new;
$plan->update_state($state);
is($state->plan, 'NO PLAN', "set plan in state");
is($plan->terminate, undef, "No terminate for no_plan");
$plan->set_max(100);
$plan->set_directive(undef);
$plan->update_state($state);
is($state->plan, '100', "Update plan in state if it is 'NO PLAN'");

$plan = Test::Sync::Event::Plan->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 0,
    directive => 'skip_all',
);
is($plan->directive, 'SKIP', "Change skip_all to SKIP");

$plan = Test::Sync::Event::Plan->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 0,
    directive => 'no_plan',
);
is($plan->directive, 'NO PLAN', "Change no_plan to 'NO PLAN'");
ok(!$plan->global, "NO PLAN is not global");

like(
    exception {
        $plan = Test::Sync::Event::Plan->new(
            debug     => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max       => 0,
            directive => 'foo',
        );
    },
    qr/'foo' is not a valid plan directive/,
    "Invalid Directive"
);

like(
    exception {
        $plan = Test::Sync::Event::Plan->new(
            debug  => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max    => 0,
            reason => 'foo',
        );
    },
    qr/Cannot have a reason without a directive!/,
    "Reason without directive"
);

like(
    exception {
        $plan = Test::Sync::Event::Plan->new(
            debug  => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
        );
    },
    qr/No number of tests specified/,
    "Nothing to do"
);

like(
    exception {
        $plan = Test::Sync::Event::Plan->new(
            debug  => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max => 'skip',
        );
    },
    qr/Plan test count 'skip' does not appear to be a valid positive integer/,
    "Max must be an integer"
);

done_testing;
