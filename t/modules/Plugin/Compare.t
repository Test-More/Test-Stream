use Test::Stream -V1, -SpecTester, Defer, Compare => '*', Class => ['Test::Stream::Plugin::Compare'];
use Data::Dumper;

tests simple => sub {
    imported_ok qw{
        match mismatch check
        hash array object meta
        item field call prop
        end filter_items
        T F D DNE
        event
        exact_ref
    };
};

tests is => sub {
    my $events = intercept {
        def ok => (is(1, 1), '2 arg pass');

        def ok => (is('a', 'a', "simple pass", 'diag'), 'simple pass');
        def ok => (!is('a', 'b', "simple fail", 'diag'), 'simple fail');

        def ok => (is([{'a' => 1}], [{'a' => 1}], "complex pass", 'diag'), 'complex pass');
        def ok => (!is([{'a' => 2, 'b' => 3}], [{'a' => 1}], "complex fail", 'diag'), 'complex fail');
    };

    do_def;

    like(
        $events,
        array {
            event Ok => sub {
                call pass => T();
                call name => undef;
                call diag => undef;
            };

            event Ok => sub {
                call pass => T();
                call name => 'simple pass';
                call diag => undef;
            };

            event Ok => sub {
                call pass => F();
                call name => 'simple fail';
                call diag => [
                    qr/Failed test 'simple fail'/,
                    '+-----+----+-------+',
                    '| GOT | OP | CHECK |',
                    '+-----+----+-------+',
                    '| a   | eq | b     |',
                    '+-----+----+-------+',
                    'diag',
                ];
            };

            event Ok => sub {
                call pass => T();
                call name => 'complex pass';
                call diag => undef;
            };

            event Ok => sub {
                call pass => F();
                call name => 'complex fail';
                call diag => [
                    qr/Failed test 'complex fail'/,
                    '+--------+-----+---------+------------------+',
                    '| PATH   | GOT | OP      | CHECK            |',
                    '+--------+-----+---------+------------------+',
                    '| [0]{a} | 2   | ==      | 1                |',
                    '| [0]{b} | 3   | !exists | <DOES NOT EXIST> |',
                    '+--------+-----+---------+------------------+',
                    'diag',
                ];
            };

            end;
        },
        "Got expected events"
    );
};

tests like => sub {
    my $events = intercept {
        def ok => (like(1, 1), '2 arg pass');

        def ok => (like('a', qr/a/, "simple pass", 'diag'), 'simple pass');
        def ok => (!like('b', qr/a/, "simple fail", 'diag'), 'simple fail');

        def ok => (like([{'a' => 1, 'b' => 2}, 'a'], [{'a' => 1}], "complex pass", 'diag'), 'complex pass');
        def ok => (!like([{'a' => 2, 'b' => 2}, 'a'], [{'a' => 1}], "complex fail", 'diag'), 'complex fail');
    };

    do_def;

    my $rx = "" . qr/a/;

    like(
        $events,
        array {
            event Ok => sub {
                call pass => T();
                call name => undef;
                call diag => undef;
            };

            event Ok => sub {
                call pass => T();
                call name => 'simple pass';
                call diag => undef;
            };

            event Ok => sub {
                call pass => F();
                call name => 'simple fail';
                call diag => [
                    qr/Failed test 'simple fail'/,
                    qr/\+-+\+-+\+-+\+/,
                    qr/| GOT | OP | CHECK\s+|/,
                    qr/\+-+\+-+\+-+\+/,
                    qr/| b   | =~ | $rx\s+|/,
                    qr/\+-+\+-+\+-+\+/,
                    'diag',
                ];
            };

            event Ok => sub {
                call pass => T();
                call name => 'complex pass';
                call diag => undef;
            };

            event Ok => sub {
                call pass => F();
                call name => 'complex fail';
                call diag => [
                    qr/Failed test 'complex fail'/,
                    '+--------+-----+----+-------+',
                    '| PATH   | GOT | OP | CHECK |',
                    '+--------+-----+----+-------+',
                    '| [0]{a} | 2   | == | 1     |',
                    '+--------+-----+----+-------+',
                    'diag',
                ];
            };

            end;
        },
        "Got expected events"
    );
};

tests shortcuts => sub {
    is(1,            T(), "true");
    is('a',          T(), "true");
    is(' ',          T(), "true");
    is('0 but true', T(), "true");

    my $events = intercept {
        is(0, T(), "not true");
        is('', T(), "not true");
        is(undef, T(), "not true");
    };
    like(
        $events,
        array {
            event Ok => { pass => 0 };
            event Ok => { pass => 0 };
            event Ok => { pass => 0 };
            end()
        },
        "T() fails for untrue",
    );

    is(0,     F(), "false");
    is('',    F(), "false");
    is(undef, F(), "false");

    $events = intercept {
        is(1,   F(), "not false");
        is('a', F(), "not false");
        is(' ', F(), "not false");
    };
    like(
        $events,
        array {
            event Ok => {pass => 0};
            event Ok => {pass => 0};
            event Ok => {pass => 0};
            end()
        },
        "F() fails for true",
    );

    is(0,            D(), "defined");
    is(1,            D(), "defined");
    is('',           D(), "defined");
    is(' ',          D(), "defined");
    is('0 but true', D(), "defined");

    like(
        intercept { is(undef, D(), "not defined") },
        array { event Ok => { pass => 0 } },
        "undef is not defined"
    );
};

tests convert => sub {
    *strict_convert = $CLASS->can('strict_convert');
    *relaxed_convert = $CLASS->can('relaxed_convert');
    my @sets = (
        ['a',   'Value', 'Value'],
        [undef, 'Value', 'Value'],
        ['',    'Value', 'Value'],
        [1,     'Value', 'Value'],
        [0,     'Value', 'Value'],
        [[],    'Array', 'Array'],
        [{},    'Hash',  'Hash'],
        [qr/x/, 'Ref',   'Pattern'],
        [sub { 1 }, 'Ref', 'Custom'],
        [\*STDERR, 'Ref',    'Ref'],
        [\'foo',   'Scalar', 'Scalar'],

        [
            bless({}, 'Test::Stream::Compare'),
            '',
            ''
        ],

        [
            bless({expect => 'a'}, 'Test::Stream::Compare::Wildcard'),
            'Value',
            'Value',
        ],
    );

    for my $set (@sets) {
        my ($item, $strict, $relaxed) = @$set;

        my $name = defined $item ? "'$item'" : 'undef';

        my $gs = strict_convert($item);
        my $st = join '::', grep {$_} 'Test::Stream::Compare', $strict;
        ok($gs->isa($st), "$name -> $st") || diag Dumper($item);

        my $gr = relaxed_convert($item);
        my $rt = join '::', grep {$_} 'Test::Stream::Compare', $relaxed;
        ok($gr->isa($rt), "$name -> $rt") || diag Dumper($item);
    }
};

tests exact_ref => sub {
    my $ref = {};

    my $check = exact_ref($ref); my $line  = __LINE__;
    is($check->lines, [$line], "correct line");

    my $events = intercept {
        is($ref, $check, "pass");
        is({},   $check, "fail");
    };

    like(
        $events,
        array {
            event Ok => {pass => 1};
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    '+-----------------+----+-----------------+-----+',
                    '| GOT             | OP | CHECK           | LNs |',
                    '+-----------------+----+-----------------+-----+',
                    qr/| HASH\(.*\) | == | HASH\(.*\) | $line |/,
                    '+-----------------+----+-----------------+-----+'
                ],
            };
            end;
        },
        "Got events"
    );
};

tests match => sub {
    my $check = match qr/xyz/; my $line = __LINE__;
    is($check->lines, [$line], "Got line number");

    my $events = intercept {
        is('axyzb', $check, "pass");
        is('abcde', $check, "fail");
    };

    my $rx = "" . qr/xyz/;
    like(
        $events,
        array {
            event Ok => {pass => 1};
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| GOT\s+| OP | CHECK\s+| LNs\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| abcde\s+| =~ | $rx\s+| $line\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                ],
            };
            end;
        },
        "Got events"
    );
};

tests mismatch => sub {
    my $check = mismatch qr/xyz/; my $line = __LINE__;
    is($check->lines, [$line], "Got line number");

    my $events = intercept {
        is('abcde', $check, "pass");
        is('axyzb', $check, "fail");
    };

    my $rx = "" . qr/xyz/;
    like(
        $events,
        array {
            event Ok => {pass => 1};
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| GOT\s+| OP | CHECK\s+| LNs\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| axyzb\s+| !~ | $rx\s+| $line\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                ],
            };
            end;
        },
        "Got events"
    );
};

tests check => sub {
    my @lines;
    my $one = check sub { $_ ? 1 : 0 }; push @lines => __LINE__;
    my $two = check two => sub { $_ ? 1 : 0 }; push @lines => __LINE__;
    my $thr = check 't', thr => sub { $_ ? 1 : 0 }; push @lines => __LINE__;

    is($one->lines, [$lines[0]], "line 1");
    is($two->lines, [$lines[1]], "line 2");
    is($thr->lines, [$lines[2]], "line 3");

    my $events = intercept {
        is(1, $one, 'pass');
        is(1, $two, 'pass');
        is(1, $thr, 'pass');

        is(0, $one, 'fail');
        is(0, $two, 'fail');
        is(0, $thr, 'fail');
    };

    like(
        $events,
        array {
            event Ok => {pass => 1};
            event Ok => {pass => 1};
            event Ok => {pass => 1};
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| GOT\s+| OP\s+| CHECK\s+| LNs\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| 0\s+| CODE\(\.\.\.\)\s+| <Custom Code>\s+| $lines[0]s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                ],
            };
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| GOT\s+| OP\s+| CHECK\s+| LNs\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| 0\s+| CODE\(\.\.\.\)\s+| <Custom Code>\s+| $lines[1]s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                ],
            };
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed test/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| GOT\s+| OP\s+| CHECK\s+| LNs\s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                    qr/| 0\s+| t\s+| thr\s+| $lines[2]s+|/,
                    qr/\+-+\+-+\+-+\+-+\+/,
                ],
            };
            end;
        },
        "Got events"
    );
};

tests DNE => sub {
    my $one  = DNE(); my $line = __LINE__;
    isa_ok($one, 'Test::Stream::Compare', 'Test::Stream::Compare::DNE');
    is($one->lines, [$line], "got lines");
    is($one->file, __FILE__, "got file");

    is(
        {a => 1},
        {a => 1, b => $one},
        "b does not exist",
    );

    like(
        intercept { is({a => 1}, {a => $one}, "Fail") },
        [
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed/,
                    '+------+-----+---------+------------------+-----+',
                    '| PATH | GOT | OP      | CHECK            | LNs |',
                    '+------+-----+---------+------------------+-----+',
                    "| {a}  | 1   | !exists | <DOES NOT EXIST> | $line |",
                    '+------+-----+---------+------------------+-----+',
                ]
            }
        ],
        "Got failure (hash)"
    );

    is([], [$one], "does not exist");

    like(
        intercept { is([1], [$one], "does not exist") },
        [
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed/,
                    '+------+-----+---------+------------------+-----+',
                    '| PATH | GOT | OP      | CHECK            | LNs |',
                    '+------+-----+---------+------------------+-----+',
                    "| [0]  | 1   | !exists | <DOES NOT EXIST> | $line |",
                    '+------+-----+---------+------------------+-----+',
                ]
            },
        ],
        "got failure (array)"
    );

    my $pb = mock Boo => (add => [boo => sub {'boo'}]);

    my $boo = bless {}, 'Boo';
    like($boo, object { call baz => $one }, "method does not exist");

    like(
        intercept { is($boo, object { call boo => $one }, "does not exist") },
        [
            event Ok => {
                pass => 0,
                diag => [
                    qr/Failed/,
                    T(), # Border
                    T(), # Header
                    T(), # Border
                    qr/| Boo=HASH/, # The object
                    qr/| boo\(\) \| boo\s+| !exists\s+| <DOES NOT EXIST>\s+| $line\s+|/,
                    T(), # Border
                ]
            },
        ],
        "got failure (array)"
    );
};

tests prop => sub {
    like(
        dies { prop x => 1 },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [meta { my $x = prop x => 1 }] },
        qr/'prop' should only ever be called in void context/,
        "restricted context"
    );

    like(
        dies { [array { prop x => 1 }] },
        qr/'Test::Stream::Compare::Array.*' does not support meta-checks/,
        "not everything supports properties"
    );
};

tests end => sub {
    like(
        dies { end() },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [meta { end() }] },
        qr/'Test::Stream::Compare::Meta.*' does not support 'ending'/,
        "Build does not support end"
    );

    like(
        dies { [array { [end()] }] },
        qr/'end' should only ever be called in void context/,
        "end context"
    );
};

tests field => sub {
    like(
        dies { field a => 1 },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [array { field a => 1 }] },
        qr/'Test::Stream::Compare::Array.*' does not support hash field checks/,
        "Build does not take fields"
    );

    like(
        dies { [hash { [field a => 1] }] },
        qr/'field' should only ever be called in void context/,
        "field context"
    );
};

tests filter_items => sub {
    like(
        dies { filter_items {1} },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [hash { filter_items {1} }] },
        qr/'Test::Stream::Compare::Hash.*' does not support filters/,
        "Build does not take filters"
    );

    like(
        dies { [array { [filter_items {1}] }] },
        qr/'filter_items' should only ever be called in void context/,
        "filter context"
    );
};

tests item => sub {
    like(
        dies { item 0 => 'a' },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [hash { item 0 => 'a' }] },
        qr/'Test::Stream::Compare::Hash.*' does not support array item checks/,
        "Build does not take items"
    );

    like(
        dies { [array { [ item 0 => 'a' ] }] },
        qr/'item' should only ever be called in void context/,
        "item context"
    );
};

tests call => sub {
    like(
        dies { call foo => 1 },
        qr/No current build/,
        "Need a build"
    );

    like(
        dies { [hash { call foo => 1 }] },
        qr/'Test::Stream::Compare::Hash.*' does not support method calls/,
        "Build does not take methods"
    );

    like(
        dies { [object { [ call foo => 1 ] }] },
        qr/'call' should only ever be called in void context/,
        "call context"
    );
};

tests meta => sub {
    my $x = bless {}, 'Foo';
    my $check = meta {
        prop blessed => 'Foo';
        prop reftype => 'HASH';
        prop this    => $x;
    };
    my @lines = map { __LINE__ - $_ } reverse 1 .. 5;

    is($x, $check, "meta pass");

    local $main::XXX = 1;
    my $events = intercept { is([], $check, "meta fail") };
    local $main::XXX = 0;
    like(
        $events,
        array {
            event Ok => sub {
                call pass => 0;
                call diag => [
                    qr/Failed test/,
                    '+-----------+------------------+----+---------------+----------+',
                    '| PATH      | GOT              | OP | CHECK         | LNs      |',
                    '+-----------+------------------+----+---------------+----------+',
                    qr/|           | ARRAY\(.*\) |    | <META CHECKS> | $lines[0], $lines[4] /,
                    "| <blessed> | <UNDEF>          |    | Foo           | $lines[1]      |",
                    "| <reftype> | ARRAY            | eq | HASH          | $lines[2]      |",
                    qr/| <this>    | ARRAY\(.*\) | eq | HASH          | $lines[3]      |/,
                    '+-----------+------------------+----+---------------+----------+'
                ];
            };
        },
        "got failure"
    );
};

tests hash => sub {
    my $empty = hash { };

    my $full = hash {
        field a => 1;
        field b => 2;
    };

    my $closed = hash {
        field a => 1;
        field b => 2;
        end();
    };

    isa_ok($_, 'Test::Stream::Compare', 'Test::Stream::Compare::Hash') for $empty, $full, $closed;

    is({}, $empty, "empty hash");
    is({a => 1}, $empty, "unclosed empty matches anything");

    is({a => 1, b => 2}, $full, "full exact match");
    is({a => 1, b => 2, c => 3 }, $full, "full with extra");

    is({a => 1, b => 2}, $closed, "closed");

    my $events = intercept {
        is([], $empty);
        is(undef, $empty);
        is(1, $empty);
        is('HASH', $empty);

        is({}, $full);
        is({a => 2, b => 2}, $full);

        is({a => 1, b => 2, c => 3}, $closed);
    };

    is(@$events, 7, '7 events');
    is($_->pass, 0, "event failed") for @$events;
};

tests array => sub {
    my $empty = array { };

    my $simple = array {
        item 'a';
        item 'b';
        item 'c';
    };

    my $filtered = array {
        filter_items { grep { m/a/ } @_ };
        item 0 => 'a';
        item 1 => 'a';
        item 2 => 'a';
    };

    my $shotgun = array {
        item 1 => 'b';
        item 3 => 'd';
    };

    my $closed = array {
        item 0 => 'a';
        item 1 => 'b';
        item 2 => 'c';
        end;
    };

    is([], $empty, "empty array");
    is(['a'], $empty, "any array matches empty");

    is([qw/a b c/], $simple, "simple exact match");
    is([qw/a b c d e/], $simple, "simple with extra");

    is([qw/x a b c a v a t t/], $filtered, "filtered out unwanted values");

    is([qw/a b c d e/], $shotgun, "selected indexes only");

    is([qw/a b c/], $closed, "closed array");

    my $events = intercept {
        is({}, $empty);
        is(undef, $empty);
        is(1, $empty);
        is('ARRAY', $empty);

        is([qw/x y z/], $simple);
        is([qw/a b x/], $simple);
        is([qw/x b c/], $simple);

        is([qw/aa a a a b/], $filtered);

        is([qw/b c d e f/], $shotgun);

        is([qw/a b c d/], $closed);
    };

    is(@$events, 10, "10 events");
    is($_->pass, 0, "event failed") for @$events;
};

tests object => sub {
    my $empty = object { };

    my $simple = object {
        call foo => 'foo';
        call bar => 'bar';
    };

    my $array = object {
        call foo => 'foo';
        call bar => 'bar';
        item 0 => 'x';
        item 1 => 'y';
    };

    my $closed_array = object {
        call foo => 'foo';
        call bar => 'bar';
        item 0 => 'x';
        item 1 => 'y';
        end();
    };

    my $hash = object {
        call foo => 'foo';
        call bar => 'bar';
        field x => 1;
        field y => 2;
    };

    my $closed_hash = object {
        call foo => 'foo';
        call bar => 'bar';
        field x => 1;
        field y => 2;
        end();
    };

    my $meta = object {
        call foo => 'foo';
        call bar => 'bar';
        prop blessed => 'ObjectFoo';
        prop reftype => 'HASH';
    };

    my $mix = object {
        call foo => 'foo';
        call bar => 'bar';
        field x => 1;
        field y => 2;
        prop blessed => 'ObjectFoo';
        prop reftype => 'HASH';
    };

    my $obf = mock 'ObjectFoo' => (add => [foo => sub { 'foo' }, bar => sub { 'bar' }, baz => sub {'baz'}]);
    my $obb = mock 'ObjectBar' => (add => [foo => sub { 'nop' }, baz => sub { 'baz' }]);

    is(bless({}, 'ObjectFoo'), $empty, "Empty matches any object");
    is(bless({}, 'ObjectBar'), $empty, "Empty matches any object");

    is(bless({}, 'ObjectFoo'), $simple, "simple match hash");
    is(bless([], 'ObjectFoo'), $simple, "simple match array");

    is(bless([qw/x y/], 'ObjectFoo'), $array, "array match");
    is(bless([qw/x y z/], 'ObjectFoo'), $array, "array match");

    is(bless([qw/x y/], 'ObjectFoo'), $closed_array, "closed array");

    is(bless({x => 1, y => 2}, 'ObjectFoo'), $hash, "hash match");
    is(bless({x => 1, y => 2, z => 3}, 'ObjectFoo'), $hash, "hash match");

    is(bless({x => 1, y => 2}, 'ObjectFoo'), $closed_hash, "closed hash");

    is(bless({}, 'ObjectFoo'), $meta, "meta match");

    is(bless({x => 1, y => 2, z => 3}, 'ObjectFoo'), $mix, "mix");

    my $events = intercept {
        is({}, $empty);
        is(undef, $empty);
        is(1, $empty);
        is('ARRAY', $empty);

        is(bless({}, 'ObjectBar'), $simple, "simple match hash");
        is(bless([], 'ObjectBar'), $simple, "simple match array");

        is(bless([qw/a y/], 'ObjectFoo'), $array, "array match");
        is(bless([qw/a y z/], 'ObjectFoo'), $array, "array match");

        is(bless([qw/x y z/], 'ObjectFoo'), $closed_array, "closed array");

        is(bless({x => 2, y => 2}, 'ObjectFoo'), $hash, "hash match");
        is(bless({x => 2, y => 2, z => 3}, 'ObjectFoo'), $hash, "hash match");
    
        is(bless({x => 1, y => 2, z => 3}, 'ObjectFoo'), $closed_hash, "closed hash");
    
        is(bless({}, 'ObjectBar'), $meta, "meta match");
        is(bless([], 'ObjectFoo'), $meta, "meta match");
    
        is(bless({}, 'ObjectFoo'), $mix, "mix");
        is(bless([], 'ObjectFoo'), $mix, "mix");
        is(bless({x => 1, y => 2, z => 3}, 'ObjectBar'), $mix, "mix");
    };

    is(@$events, 17, "17 events");
    is($_->pass, 0, "event failed") for @$events;

};

done_testing;


__END__

sub event($;$) {
    my ($intype, $spec) = @_;

    my @caller = caller;

    croak "type is required" unless $intype;

    my $type;
    if ($intype =~ m/^\+(.*)$/) {
        $type = $1;
    }
    else {
        $type = "Test::Stream::Event::$intype";
    }

    my $event;
    if (!$spec) {
        $event = Test::Stream::Compare::Event->new(
            etype => $intype,
            file  => $caller[1],
            lines => [$caller[2]],
        );
    }
    elsif (!ref $spec) {
        croak "'$spec' is not a valid event specification"
    }
    elsif (reftype($spec) eq 'CODE') {
        $event = build('Test::Stream::Compare::Event', $spec);
        my $block = Test::Stream::Block->new(coderef => $spec, caller => \@caller);
        $event->set_file($block->file);
        $event->set_lines([$block->start_line, $block->end_line]);
        $event->set_etype($intype),
    }
    else {
        my $refcheck = Test::Stream::Compare::Hash->new(
            inref => $spec,
            file  => $caller[1],
            lines => [$caller[2]],
        );
        $event = Test::Stream::Compare::Event->new(
            refcheck => $refcheck,
            file     => $caller[1],
            lines    => [$caller[2]],
            etype => $intype,
        );
    }

    my $tcheck = Test::Stream::Compare::Custom->new(
        file  => $caller[1],
        lines => [$caller[2]],
        code  => sub {},
        name  => "isa($intype)",
    );

    $event->add_prop('this' => $tcheck);

    return $event if defined wantarray;

    my $build = get_build() || croak "No current build!";
    $build->add_item($event);
}
