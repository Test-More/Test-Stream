use strict;
use warnings;

use Test::Sync::Tester;
use Test::Sync::Event::Note;
use Test::Sync::DebugInfo;

my $note = Test::Sync::Event::Note->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => 'foo',
);

$note = Test::Sync::Event::Note->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => undef,
);

is($note->message, 'undef', "set undef message to undef");

$note = Test::Sync::Event::Note->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => {},
);

like($note->message, qr/^HASH\(.*\)$/, "stringified the input value");

done_testing;
