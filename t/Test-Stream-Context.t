use strict;
use warnings;

use Test::Stream;
use Test::Stream::Interceptor qw/dies warns/;

use Test::Stream::Context qw/context TOP_HUB/;

can_ok(__PACKAGE__, qw/context/);

my $error = dies { context(); 1 };
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
    isa_ok($ctx->hub, 'Test::Stream::Hub');
    is_deeply($ctx->debug->frame, $frame, "Found place to report errors");
};

wrap {
    my $ctx = shift;
    isnt("$ctx", $ref, "Got a new context");
    my $new = context();
    ok($ctx == $new, "Additional call to context gets same instance");
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
my $hub = Test::Stream::Hub->new(
    formatter => $events,
);
my $dbg = Test::Stream::DebugInfo->new(
    frame => [ 'Foo::Bar', 'foo_bar.t', 42, 'Foo::Bar::baz' ],
);
my $ctx = Test::Stream::Context->new(
    debug => $dbg,
    hub   => $hub,
);

my $e = $ctx->build_event('Ok', pass => 1, name => 'foo');
isa_ok($e, 'Test::Stream::Event::Ok');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
ok(!@$events, "No events yet");

$e = $ctx->send_event('Ok', pass => 1, name => 'foo');
isa_ok($e, 'Test::Stream::Event::Ok');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->ok(1, 'foo');
isa_ok($e, 'Test::Stream::Event::Ok');
is($e->pass, 1, "Pass");
is($e->name, 'foo', "got name");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->note('foo');
isa_ok($e, 'Test::Stream::Event::Note');
is($e->message, 'foo', "got message");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->diag('foo');
isa_ok($e, 'Test::Stream::Event::Diag');
is($e->message, 'foo', "got message");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

$e = $ctx->plan(100);
isa_ok($e, 'Test::Stream::Event::Plan');
is($e->max, 100, "got max");
is_deeply($e->debug, $dbg, "Got the debug info");
is(@$events, 1, "1 event");
is_deeply($events, [$e], "Hub saw the event");
pop @$events;

# Test todo
my ($dbg1, $dbg2);
my $todo = TOP_HUB->set_todo("Here be dragons");
wrap { $dbg1 = shift->debug };
$todo = undef;
wrap { $dbg2 = shift->debug };

is($dbg1->todo, 'Here be dragons', "Got todo in context created with todo in place");
is($dbg2->todo, undef, "no todo in context created after todo was removed");


# Test hooks

my @hooks;
$hub = TOP_HUB();
my $ref1 = $hub->add_context_init(sub { push @hooks => 'hub_init' });
my $ref2 = $hub->add_context_release(sub { push @hooks => 'hub_release' });

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

is_deeply(
    \@hooks,
    [qw{
        start
        ctx_init
        hub_init
        deep
        release_deep
        release_parent
        ctx_release
        ctx_release_deep
        hub_release
        released_all
        new
        ctx_init2
        hub_init
        release_new
        ctx_release2
        hub_release
        done
    }],
    "Got all hook in correct order"
);

done_testing;
