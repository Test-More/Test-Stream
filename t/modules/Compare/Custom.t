use Test::Stream -V1, Class => ['Test::Stream::Compare::Custom'];

my $pass = $CLASS->new(code => sub { 1 });
my $fail = $CLASS->new(code => sub { 0 });

isa_ok($pass, $CLASS, 'Test::Stream::Compare');
isa_ok($fail, $CLASS, 'Test::Stream::Compare');

ok($pass->verify(got => "anything"), "always passes");
ok(!$fail->verify(got => "anything"), "always fails");

is($pass->operator, 'CODE(...)', "default operator");
is($pass->name, '<Custom Code>', "default name");

my $args;
my $under;
my $one = $CLASS->new(code => sub { $args = {@_}; $under = $_ }, name => 'the name', operator => 'the op');
$_ = undef;
$one->verify(got => 'foo', exists => 'x');
is($_, undef, '$_ restored');

is($args, {got => 'foo', exists => 'x', operator => 'the op', name => 'the name'}, "Got the expected args");
is($under, 'foo', '$_ was set');

like(
    dies { $CLASS->new() },
    qr/'code' is required/,
    "Need to provide code"
);

done_testing;
