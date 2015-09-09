use Test::Stream -V1, Class => ['Test::Stream::Compare::DNE'];

my $one = $CLASS->new;
isa_ok($one, $CLASS, 'Test::Stream::Compare');

is($one->name, "<DOES NOT EXIST>", "name is obvious");
is($one->operator, '!exists', "operator is obvious");

is($one->verify(), 1, "nothing there");
is($one->verify(undef), 0, "Should not exist");
is($one->verify(1), 0, "Should not exist");
is($one->verify(0), 0, "Should not exist");

done_testing;
