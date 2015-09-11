use Test::Stream -V1, Class => ['Test::Stream::Compare::Ref'];

my $ref = sub { 1 };
my $one = $CLASS->new(input => $ref);
isa_ok($one, $CLASS, 'Test::Stream::Compare');

like($one->name, qr/CODE\(.*\)/, "Got Name");
is($one->operator, '==', "got operator");

ok($one->verify($ref), "verified ref");
ok(!$one->verify(sub { 1 }), "different ref");

is(
    [ 'a', $ref ],
    [ 'a', $one ],
    "Did a ref check"
);

ok(!$one->verify('a'), "not a ref");

$one->set_input('a');
ok(!$one->verify($ref), "input not a ref");

like(
    dies { $CLASS->new() },
    qr/'input' is a required attribute/,
    "Need input"
);

like(
    dies { $CLASS->new(input => 'a') },
    qr/'input' must be a reference, got 'a'/,
    "Input must be a ref"
);

done_testing;
