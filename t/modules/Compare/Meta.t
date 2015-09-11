use Test::Stream -V1, Spec, Class => ['Test::Stream::Compare::Meta'], Compare => '*';

local *convert = Test::Stream::Plugin::Compare->can('strict_convert');

tests simple => sub {
    my $one = $CLASS->new();
    isa_ok($one, $CLASS, 'Test::Stream::Compare');
    is($one->items, [], "generated an empty items array");
    is($one->name, '<META CHECKS>', "sane name");
    is($one->verify(), 1, "always verifies");
    ok($CLASS->new(items => []), "Can provide items");
};

tests add_prop => sub {
    my $one = $CLASS->new();

    like(
        dies { $one->add_prop(undef, convert(1)) },
        qr/prop name is required/,
        "property name is required"
    );

    like(
        dies { $one->add_prop('fake' => convert(1)) },
        qr/'fake' is not a known property/,
        "Must use valid property"
    );

    like(
        dies { $one->add_prop('blessed') },
        qr/check is required/,
        "Must use valid property"
    );

    ok($one->add_prop('blessed' => convert('xxx')), "normal");
};

tests deltas => sub {
    my $one = $CLASS->new();

    my $it = bless {a => 1, b => 2, c => 3}, 'Foo';

    $one->add_prop('blessed' => 'Foo');
    $one->add_prop('reftype' => 'HASH');
    $one->add_prop('this' => exact_ref($it));
    $one->add_prop('size' => 3);

    is(
        [$one->deltas($it, \&convert, {})],
        [],
        "Everything matches"
    );

    my $not_it = bless ['a'], 'Bar';

    like(
        [$one->deltas($not_it, \&convert, {})],
        [
            { verified => F(), got => 'Bar' },
            { verified => F(), got => 'ARRAY' },
            { verified => F(), got => $not_it },
            { verified => F(), got => 1 },
        ],
        "Nothing matches"
    );

    like(
        [$one->deltas('a', \&convert, {})],
        [
            { verified => F(), got => undef },
            { verified => F(), got => undef },
            { verified => F(), got => 'a' },
            { verified => F(), got => undef },
        ],
        "Nothing matches, wrong everything"
    );
};

done_testing;
