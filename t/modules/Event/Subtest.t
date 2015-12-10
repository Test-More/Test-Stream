use Test::Sync -V1;

use Test::Sync::Formatter::TAP qw/OUT_STD OUT_ERR/;
use Test::Sync::Event::Subtest;
my $st = 'Test::Sync::Event::Subtest';

my $dbg = Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']);
my $one = $st->new(
    debug     => $dbg,
    pass      => 1,
    buffered  => 1,
    name      => 'foo',
);

isa_ok($one, $st, 'Test::Sync::Event::Ok');
is($one->subevents, [], "subevents is an arrayref");

warns {
    is(
        [$one->to_tap(5)],
        [
            [OUT_STD, "ok 5 - foo {\n"],
            [OUT_STD, "}\n"],
        ],
        "Got Buffered TAP output"
    );
};

$one->set_buffered(0);
warns {
    is(
        [$one->to_tap(5)],
        [
            [OUT_STD, "ok 5 - foo\n"],
        ],
        "Got Unbuffered TAP output"
    );
};

$dbg = Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']);
$one = $st->new(
    debug     => $dbg,
    pass      => 0,
    buffered  => 1,
    name      => 'bar',
    diag      => [ 'bar failed' ],
    subevents => [
        Test::Sync::Event::Ok->new(debug => $dbg, name => 'first',  pass => 1),
        Test::Sync::Event::Ok->new(debug => $dbg, name => 'second', pass => 0, diag => ["second failed"]),
        Test::Sync::Event::Ok->new(debug => $dbg, name => 'third',  pass => 1),

        Test::Sync::Event::Diag->new(debug => $dbg, message => 'blah blah'),

        Test::Sync::Event::Plan->new(debug => $dbg, max => 3),
    ],
);

warns {
    local $ENV{HARNESS_IS_VERBOSE};
    is(
        [$one->to_tap(5)],
        [
            [OUT_STD, "not ok 5 - bar {\n"],
            [OUT_ERR, "# bar failed\n"],
            [OUT_STD, "    ok 1 - first\n"],
            [OUT_STD, "    not ok 2 - second\n"],
            [OUT_ERR, "    # second failed\n"],
            [OUT_STD, "    ok 3 - third\n"],
            [OUT_ERR, "    # blah blah\n"],
            [OUT_STD, "    1..3\n"],
            [OUT_STD, "}\n"],
        ],
        "Got Buffered TAP output (non-verbose)"
    );
};

warns {
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    is(
        [$one->to_tap(5)],
        [
            [OUT_STD, "not ok 5 - bar {\n"],
            [OUT_ERR, "    # bar failed\n"],
            [OUT_STD, "    ok 1 - first\n"],
            [OUT_STD, "    not ok 2 - second\n"],
            [OUT_ERR, "    # second failed\n"],
            [OUT_STD, "    ok 3 - third\n"],
            [OUT_ERR, "    # blah blah\n"],
            [OUT_STD, "    1..3\n"],
            [OUT_STD, "}\n"],
        ],
        "Got Buffered TAP output (verbose)"
    );
};

warns {
    local $ENV{HARNESS_IS_VERBOSE};
    $one->set_buffered(0);
    is(
        [$one->to_tap(5)],
        [
            # In unbuffered TAP the subevents are rendered outside of this.
            [OUT_STD, "not ok 5 - bar\n"],
            [OUT_ERR, "# bar failed\n"],
        ],
        "Got Unbuffered TAP output (non-verbose)"
    );
};

warns {
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    $one->set_buffered(0);
    is(
        [$one->to_tap(5)],
        [
            # In unbuffered TAP the subevents are rendered outside of this.
            [OUT_STD, "not ok 5 - bar\n"],
            [OUT_ERR, "# bar failed\n"],
        ],
        "Got Unbuffered TAP output (verbose)"
    );
};

done_testing;
