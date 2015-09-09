use Test::Stream -V1, Class => ['Test::Stream::Compare::Pattern'];

my $one = $CLASS->new(pattern => qr/HASH/);
isa_ok($one, $CLASS, 'Test::Stream::Compare');
is($one->name, "" . qr/HASH/, "got name");
is($one->operator, '=~', "got operator");
ok(!$one->verify({}), "A hashref does not validate against the pattern 'HASH'");
ok(!$one->verify(), "undef does not validate");
ok(!$one->verify('foo'), "Not a match");
ok($one->verify('A HASH B'), "Matches");

$one = $CLASS->new(pattern => qr/HASH/, negate => 1);
isa_ok($one, $CLASS, 'Test::Stream::Compare');
is($one->name, "" . qr/HASH/, "got name");
is($one->operator, '!~', "got operator");
ok(!$one->verify({}), "A hashref does not validate against the pattern 'HASH' even when negated");
ok(!$one->verify(), "undef does not validate");
ok($one->verify('foo'), "Not a match, but negated");
ok(!$one->verify('A HASH B'), "Matches, but negated");


like(
    dies { $CLASS->new },
    qr/'pattern' is a required attribute/,
    "Need to specify a pattern"
);

done_testing;
