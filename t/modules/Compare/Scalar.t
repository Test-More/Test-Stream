use Test::Stream -V1, Class => ['Test::Stream::Compare::Scalar'];

my $one = $CLASS->new(item => 'foo');
is($one->name, '<SCALAR>', "got name");
is($one->operator, '${...}', "Got operator");

ok(!$one->verify(), "nothing to verify");
ok(!$one->verify('a'), "not a ref");
ok(!$one->verify({}), "not a scalar ref");

ok($one->verify(\'anything'), "Scalar ref");

my $convert = Test::Stream::Plugin::Compare->can('strict_convert');

use Data::Dumper;

is(
    [$one->deltas(\'foo', $convert, {})],
    [],
    "Exact match, no delta"
);

like(
    [$one->deltas(\'bar', $convert, {})],
    [
        {
            got => 'bar',
            id  => [SCALAR => '$*'],
            chk => {'input' => 'foo'},
        }
    ],
    "Value pointed to is different"
);

like(
    dies { $CLASS->new() },
    qr/'item' is a required attribute/,
    "item is required"
);

done_testing;
