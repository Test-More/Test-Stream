use Test::Stream -Classic, -Tester, Compare => ['-all', is => { -as => '_is' }], class => 'Test::Stream::Plugin::Is';

imported_ok(qw/is is_deeply/);

my $ref = {};

is($ref,   "$ref", "flat check, ref as string right");
is("$ref", $ref,   "flat check, ref as string left");

# is_deeply uses the same algorithm as the 'Compare' plugin, so it is already
# tested over there.
is_deeply(
    {foo => 1, bar => 'baz'},
    {foo => 1, bar => 'baz'},
    "Deep compare"
);

done_testing;
