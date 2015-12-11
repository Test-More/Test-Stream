use strict;
use warnings;
use Test::Sync::Tester;
use Test::Sync::DebugInfo;

like(
    exception { 'Test::Sync::DebugInfo'->new() },
    qr/Frame is required/,
    "got error"
);

my $one = 'Test::Sync::DebugInfo'->new(frame => ['Foo::Bar', 'foo.t', 5, 'Foo::Bar::foo']);
is_deeply($one->frame,  ['Foo::Bar', 'foo.t', 5, 'Foo::Bar::foo'], "Got frame");
is_deeply([$one->call], ['Foo::Bar', 'foo.t', 5, 'Foo::Bar::foo'], "Got call");
is($one->package, 'Foo::Bar',      "Got package");
is($one->file,    'foo.t',         "Got file");
is($one->line,    5,               "Got line");
is($one->subname, 'Foo::Bar::foo', "got subname");

is($one->trace, "at foo.t line 5", "got trace");
$one->set_detail("yo momma");
is($one->trace, "yo momma", "got detail for trace");
$one->set_detail(undef);

is(
    exception { $one->throw('I died') },
    "I died at foo.t line 5.\n",
    "got exception"
);

is_deeply(
    warnings { $one->alert('I cried') },
    [ "I cried at foo.t line 5.\n" ],
    "alter() warns"
);

my $snap = $one->snapshot;
is_deeply($snap, $one, "identical");
ok($snap != $one, "Not the same instance");

done_testing;
