use strict;
use warnings;

use Test::Sync::Tester;
use Test::Sync::Event::Subtest;
my $st = 'Test::Sync::Event::Subtest';

my $dbg = Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']);
my $one = $st->new(
    debug     => $dbg,
    pass      => 1,
    buffered  => 1,
    name      => 'foo',
);

ok($one->isa('Test::Sync::Event::Ok'), "Inherit from Ok");
is_deeply($one->subevents, [], "subevents is an arrayref");

done_testing;
