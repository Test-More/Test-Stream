use Test::Sync -V1;

BEGIN {
    $INC{'My/HBase.pm'} = __FILE__;

    package My::HBase;
    use Test::Sync::HashBase(
        accessors => [qw/foo bar baz/],
    );

    use Test::Sync -V1;
    is(FOO, 'foo', "FOO CONSTANT");
    is(BAR, 'bar', "BAR CONSTANT");
    is(BAZ, 'baz', "BAZ CONSTANT");
}

BEGIN {
    package My::HBaseSub;
    use base 'My::HBase';
    use Test::Sync::HashBase accessors => [qw/apple pear/];

    use Test::Sync -V1;
    is(FOO,   'foo',   "FOO CONSTANT");
    is(BAR,   'bar',   "BAR CONSTANT");
    is(BAZ,   'baz',   "BAZ CONSTANT");
    is(APPLE, 'apple', "APPLE CONSTANT");
    is(PEAR,  'pear',  "PEAR CONSTANT");

    local $SIG{__WARN__} = sub { 1 };
    my $bad = eval { Test::Sync::HashBase->import( base => 'foobarbaz' ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/Base class 'foobarbaz' is not a HashBase class/, "Expected error");
}

BEGIN {
    package My::HBaseSubDep;
    BEGIN {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift };
        Test::Sync::HashBase->import(
            accessors => [qw/apple pear/],
            base      => 'My::HBase',
        );
        main::like($warning, qr/'base' argument to HashBase is deprecated\./, "got import deprecation warning");
    }

    use Test::Sync -V1;
    is(FOO,   'foo',   "FOO CONSTANT");
    is(BAR,   'bar',   "BAR CONSTANT");
    is(BAZ,   'baz',   "BAZ CONSTANT");
    is(APPLE, 'apple', "APPLE CONSTANT");
    is(PEAR,  'pear',  "PEAR CONSTANT");

    local $SIG{__WARN__} = sub { 1 };
    my $bad = eval { Test::Sync::HashBase->import( base => 'foobarbaz' ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/Base class 'foobarbaz' is not a HashBase class/, "Expected error");
}

{
    package Consumer;
    use Test::Sync -V1;

    local $SIG{__WARN__} = sub { 1 };
    my $bad = eval { Test::Sync::HashBase->import( base => 'Fake::Thing' ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/Base class 'Fake::Thing' is not a HashBase class/, "Expected error");
}

isa_ok('My::HBaseSub', 'My::HBase');

my $one = My::HBase->new(foo => 'a', bar => 'b', baz => 'c');
is($one->foo, 'a', "Accessor");
is($one->bar, 'b', "Accessor");
is($one->baz, 'c', "Accessor");
$one->set_foo('x');
is($one->foo, 'x', "Accessor set");
$one->set_foo(undef);

is(
    $one,
    {
        foo => undef,
        bar => 'b',
        baz => 'c',
    },
    'hash'
);

$one->clear_foo;
is(
    $one,
    {
        bar => 'b',
        baz => 'c',
    },
    'hash'
);


my $obj = bless {}, 'FAKE';

my $accessor = Test::Sync::HashBase->gen_accessor('foo');
my $getter   = Test::Sync::HashBase->gen_getter('foo');
my $setter   = Test::Sync::HashBase->gen_setter('foo');

is($obj, {}, "nothing set");

is($obj->$accessor(), undef, "nothing set");
is($obj->$accessor('foo'), 'foo', "set value");
is($obj->$accessor(), 'foo', "was set");

is($obj, {foo => 'foo'}, "set");

is($obj->$getter(), 'foo', "got the value");
is($obj->$getter(), 'foo', "got the value again");

is($obj, {foo => 'foo'}, "no change");

is( $obj->$setter, undef, "set to nothing" );
is($obj, {foo => undef}, "nothing");
is( $obj->$setter('foo'), 'foo', "set it again" );
is($obj, {foo => 'foo'}, "is set");
is($obj->$getter(), 'foo', "got the value");
is($obj->$accessor('foo'), 'foo', "get via accessor");

is($obj, {foo => 'foo'}, "no change");

done_testing;
