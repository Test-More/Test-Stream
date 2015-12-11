use Test::Sync::Tester;
use strict;
use warnings;

use Test::Sync::Event::Skip;
use Test::Sync::DebugInfo;

my $skip = Test::Sync::Event::Skip->new(
    debug  => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    name   => 'skip me',
    reason => 'foo',
);

is($skip->name, 'skip me', "set name");
is($skip->reason, 'foo', "got skip reason");

done_testing;
