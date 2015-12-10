use strict;
use warnings;
use Test::Sync::Tester;
use Test::Sync::Event::Diag;
use Test::Sync::DebugInfo;

my $diag = Test::Sync::Event::Diag->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => 'foo',
);

$diag = Test::Sync::Event::Diag->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => undef,
);

is($diag->message, 'undef', "set undef message to undef");

$diag = Test::Sync::Event::Diag->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => {},
);

like($diag->message, qr/^HASH\(.*\)$/, "stringified the input value");

done_testing;
