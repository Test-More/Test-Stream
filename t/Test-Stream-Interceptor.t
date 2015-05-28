use strict;
use warnings;

use Test::More;
use Test::Stream::Context qw/TOP_HUB context/;
use Test::Stream::Interceptor qw{
    intercept dies warning warns lives no_warnings grab
};

TOP_HUB->set_no_ending(1);

can_ok(
    __PACKAGE__,
    qw{intercept dies warning warns lives no_warnings grab}
);

sub tool { context() };

my %params;
my $ctx = context(level => -1);
my $ictx;
my $events = intercept {
     %params = @_;

    $ictx = tool();
    $ictx->ok(1, 'pass');
    $ictx->ok(0, 'fail');
    my $dbg = Test::Stream::DebugInfo->new(
        frame => [ __PACKAGE__, __FILE__, __LINE__],
    );
    $ictx->hub->finalize($dbg);
};

is_deeply(
    \%params,
    {
        context => $ctx,
        hub => $ictx->hub,
    },
    "Passed in some useful params"
);

ok($ctx != $ictx, "Different context inside intercept");

is(@$events, 3, "got 3 events");
ok(!$ictx->hub->ipc, "No IPC was used");

$ictx->release;

{
    my $grab = grab();

        $ictx = tool();
        $ictx->ok(1, 'pass');
        $ictx->ok(0, 'fail');

    my $events = $grab->finish;
    ok(!$grab, "grab was destroyed");

    ok($ctx != $ictx, "Different context inside intercept");

    is(@$events, 2, "got 2 events");
    ok(!$ictx->hub->ipc, "No IPC was used");
}

$ctx->release;
$ictx->release;

my $exception = dies { die "xxx" };
like($exception, qr/^xxx at/, "Captured exception");
$exception = dies { 1 };
is($exception, undef, "no exception");

my $warning = warning { warn "xxx" };
like($warning, qr/^xxx at/, "Captured warning");

my $warnings = warns { 1 };
is($warnings, undef, "no warnings");
$warnings = warns { warn "xxx"; warn "yyy" };
is(@$warnings, 2, "2 warnings");
like($warnings->[0], qr/^xxx at/, "first warning");
like($warnings->[1], qr/^yyy at/, "second warning");

my $no_warn = no_warnings { ok(lives { 0 }, "lived") };
ok($no_warn, "no warning on live");

$warning = warning { ok(!lives { die 'xxx' }, "lived") };
like($warning, qr/^xxx at/, "warning with exception");

is_deeply(
    warns { warn "foo\n"; warn "bar\n" },
    [
        "foo\n",
        "bar\n",
    ],
    "Got expected warnings"
);

# Test that a skip_all in an intercept does not exit.
$events = intercept {
    $ictx = tool();
    $ictx->plan(0, skip_all => 'cause');
    $ictx->ok(0, "Should not see this");
};

is(@$events, 1, "got 1 event");
isa_ok($events->[0], 'Test::Stream::Event::Plan');

# Test that a bail-out in an intercept does not exit.
$events = intercept {
    $ictx = tool();
    $ictx->bail("The world ends");
    $ictx->ok(0, "Should not see this");
};

is(@$events, 1, "got 1 event");
isa_ok($events->[0], 'Test::Stream::Event::Bail');

require Test::Stream::IPC;

$events = intercept {
    $ictx = tool();
};

ok($ictx->hub->ipc, "intercept has IPC if IP is loaded");

$ictx->release;

{
    my $grab = grab();

        $ictx = tool();

    $grab->finish;
    ok(!$grab, "grab was destroyed");
    ok($ictx->hub->ipc, "IPC was used");
}

$ictx->release;

done_testing;
