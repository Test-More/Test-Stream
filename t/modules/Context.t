use strict;
use warnings;

use Test::Sync::Tester;

use Test::Sync qw/context/;

my $error = exception { context(); 1 };
my $exception = "context() called, but return value is ignored at " . __FILE__ . ' line ' . (__LINE__ - 1);
like($error, qr/^\Q$exception\E/, "Got the exception" );

my $ref;
my $frame;
sub wrap(&) {
    my $ctx = context();
    my ($pkg, $file, $line, $sub) = caller(0);
    $frame = [$pkg, $file, $line, $sub];

    $_[0]->($ctx);

    $ref = "$ctx";

    $ctx->release;
}

wrap {
    my $ctx = shift;
    ok($ctx->hub, "got hub");
    delete $ctx->debug->frame->[4];
    is_deeply($ctx->debug->frame, $frame, "Found place to report errors");
};

wrap {
    my $ctx = shift;
    ok("$ctx" ne "$ref", "Got a new context");
    my $new = context();
    ok($ctx == $new, "Additional call to context gets same instance");
    delete $ctx->debug->frame->[4];
    is_deeply($ctx->debug->frame, $frame, "Found place to report errors");
    $new->release;
};

wrap {
    my $ctx = shift;
    my $snap = $ctx->snapshot;
    is_deeply($ctx, $snap, "snapshot is identical");
    ok($ctx != $snap, "snapshot is a new instance");
};

my $end_ctx;
{ # Simulate an END block...
    local *END = sub { local *__ANON__ = 'END'; context() };
    my $ctx = END(); $frame = [ __PACKAGE__, __FILE__, __LINE__, 'main::END' ];
    $end_ctx = $ctx->snapshot;
    $ctx->release;
}
delete $end_ctx->debug->frame->[4];
is_deeply( $end_ctx->debug->frame, $frame, 'context is ok in an end block');

# Test event generation
{
    package My::Formatter;

    sub write {
        my $self = shift;
        my ($e) = @_;
        push @$self => $e;
    }
}
my $events = bless [], 'My::Formatter';
my $hub = Test::Sync::Hub->new(
    formatter => $events,
);
my $dbg = Test::Sync::DebugInfo->new(
    frame => [ 'Foo::Bar', 'foo_bar.t', 42, 'Foo::Bar::baz' ],
);
my $ctx = Test::Sync::Context->new(
    debug => $dbg,
    hub   => $hub,
);

my $e = $ctx->build_event('Ok', pass => 1, name => 'foo');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
ok(!@$events, "No events yet");

$e = $ctx->send_event('Ok', pass => 1, name => 'foo');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->ok(1, 'foo');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->note('foo');
is($e->message, 'foo', "got message");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->diag('foo');
is($e->message, 'foo', "got message");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->plan(100);
is($e->max, 100, "got max");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->skip('foo', 'because');
is($e->name, 'foo', "got name");
is($e->reason, 'because', "got reason");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

# Test hooks

my @hooks;
$hub =  Test::Sync::Global->stack->top;
my $ref1 = $hub->add_context_init(sub { push @hooks => 'hub_init' });
my $ref2 = $hub->add_context_release(sub { push @hooks => 'hub_release' });
Test::Sync::Context->ON_INIT(sub { push @hooks => 'global_init' });
Test::Sync::Context->ON_RELEASE(sub { push @hooks => 'global_release' });

sub {
    push @hooks => 'start';
    my $ctx = context(on_init => sub { push @hooks => 'ctx_init' }, on_release => sub { push @hooks => 'ctx_release' });
    push @hooks => 'deep';
    my $ctx2 = sub {
        context(on_init => sub { push @hooks => 'ctx_init_deep' }, on_release => sub { push @hooks => 'ctx_release_deep' });
    }->();
    push @hooks => 'release_deep';
    $ctx2->release;
    push @hooks => 'release_parent';
    $ctx->release;
    push @hooks => 'released_all';

    push @hooks => 'new';
    $ctx = context(on_init => sub { push @hooks => 'ctx_init2' }, on_release => sub { push @hooks => 'ctx_release2' });
    push @hooks => 'release_new';
    $ctx->release;
    push @hooks => 'done';
}->();

$hub->remove_context_init($ref1);
$hub->remove_context_release($ref2);
@Test::Sync::Context::ON_INIT = ();
@Test::Sync::Context::ON_RELEASE = ();

is_deeply(
    \@hooks,
    [qw{
        start
        global_init
        hub_init
        ctx_init
        deep
        release_deep
        release_parent
        ctx_release_deep
        ctx_release
        hub_release
        global_release
        released_all
        new
        global_init
        hub_init
        ctx_init2
        release_new
        ctx_release2
        hub_release
        global_release
        done
    }],
    "Got all hook in correct order"
);

{
    my $ctx = context(level => -1);

    local $@ = 'testing error';
    my $one = Test::Sync::Context->new(
        debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'blah']),
        hub => Test::Sync::Global->stack->top,
    );
    is($one->_err, 'testing error', "Copied \$@");
    is($one->_depth, 0, "default depth");

    my $ran = 0;
    my $doit = sub {
        is_deeply(\@_, [qw/foo bar/], "got args");
        is(context(), $one, "The one context is our context");
        $ran++;
        die "Make sure old context is restored";
    };

    eval { $one->do_in_context($doit, 'foo', 'bar') };
    is(context(level => -1, wrapped => -2), $ctx, "Old context restored");
    $ctx->release;

    ok(!exception { $one->do_in_context(sub {1}) }, "do_in_context works without an original")
}

{
    my $warnings;
    my $exit;
    sub {
        my $ctx = context();

        local $? = 0;
        $warnings = warnings { Test::Sync::Context::_do_end() };
        $exit = $?;

        $ctx->release;
    }->();

    {
        my $line = __LINE__ - 3;
        my $file = __FILE__;
        is_deeply(
            $warnings,
            [
                "context object was never released! This means a testing tool is behaving very badly at $file line $line.\n"
            ],
            "Warned about unfreed context"
        );

        is($exit, 255, "set exit code to 255");
    }
}

{
    like(exception { Test::Sync::Context->new() }, qr/The 'debug' attribute is required/, "need to have debug");

    my $debug = Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'foo']);
    like(exception { Test::Sync::Context->new(debug => $debug) }, qr/The 'hub' attribute is required/, "need to have hub");

    my $hub = Test::Sync::Global->stack->top;
    my $ctx = Test::Sync::Context->new(debug => $debug, hub => $hub);
    is($ctx->{_depth}, 0, "depth set to 0 when not defined.");

    $ctx = Test::Sync::Context->new(debug => $debug, hub => $hub, _depth => 1);
    is($ctx->{_depth}, 1, "Do not reset depth");

    like(
        exception { $ctx->release },
        qr/release\(\) should not be called on a non-canonical context/,
        "Non canonical context, do not release"
    );
    ok(!$ctx, "ctx still destroyed from bad release");
}

sub {
    my $caller = [caller(0)];
    my $ctx = context();

    my $warnings = warnings { $ctx = undef };
    my @parts = split /^\n/m, $warnings->[0];
    is($parts[0], <<"    EOT", 'Got warning about unreleased context');
Context was not released! Releasing at destruction\.
Context creation details:
  Package: main
     File: $caller->[1]
     Line: $caller->[2]
     Tool: $caller->[3]
    EOT

    like($parts[1], qr/Trace:/, "got trace");

    ok(@$warnings == 1, "Only 1 warning");
}->();

sub {
    like(
        exception { my $ctx = context(level => 20) },
        qr/Could not find context at depth 21/,
        "Level sanity"
    );

    ok(
        !exception {
            my $ctx = context(level => 20, fudge => 1);
            $ctx->release;
        },
        "Was able to get context when fudging level"
    );
}->();

sub {
    my ($ctx1, $ctx2);
    sub { $ctx1 = context() }->();

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        $ctx2 = context();
        $ctx1 = undef;
    }

    $ctx2->release;

    is(@warnings, 1, "1 warning");
    like(
        $warnings[0],
        qr/^context\(\) was called to retrieve an existing context, however the existing/,
        "Got expected warning"
    );
}->();

sub {
    my $ctx = context();
    my $e = exception { $ctx->throw('xxx') };
    ok(!$ctx, "context was destroyed");
    like($e, qr/xxx/, "got exception");

    $ctx = context();
    my $warnings = warnings { $ctx->alert('xxx') };
    like($warnings->[0], qr/xxx/, "got warning");
    $ctx->release;
}->();

sub {
    my $ctx = context;
    my $clone = $ctx;
    $ctx = $clone->snapshot;
    $clone->release;

    is($ctx->_parse_event('Ok'), 'Test::Sync::Event::Ok', "Got the Ok event class");
    is($ctx->_parse_event('+Test::Sync::Event::Ok'), 'Test::Sync::Event::Ok', "Got the +Ok event class");

    like(
        exception { $ctx->_parse_event('+DFASGFSDFGSDGSD') },
        qr/Could not load event module 'DFASGFSDFGSDGSD': Can't locate DFASGFSDFGSDGSD\.pm/,
        "Bad event type"
    );
}->();

{
    my ($e1, $e2);
    intercept {
        my $ctx = context();
        $e1 = $ctx->ok(0, 'foo', ['xxx']);
        $e2 = $ctx->ok(0, 'foo');
        $ctx->release;
    };

    like($e1->diag->[0], qr/Failed test 'foo'/, "event 1 diag 1");
    is($e1->diag->[1], 'xxx', "event 1 diag 2");

    like($e2->diag->[0], qr/Failed test 'foo'/, "event 1 diag 1");
    is(@{$e2->diag}, 1, "only 1 diag for event 2");
}

done_testing;
