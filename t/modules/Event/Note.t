use Test::Sync -V1;
use strict;
use warnings;

use Test::Sync::Event::Note;
use Test::Sync::DebugInfo;

use Test::Sync::Formatter::TAP qw/OUT_STD/;

my $note = Test::Sync::Event::Note->new(
    debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => 'foo',
);

warns {
    is(
        [$note->to_tap(1)],
        [[OUT_STD, "# foo\n"]],
        "Got tap"
    );
    
    $note->set_message("foo\n");
    is(
        [$note->to_tap(1)],
        [[OUT_STD, "# foo\n"]],
        "Only 1 newline"
    );
    
    $note->set_message("foo\nbar\nbaz");
    is(
        [$note->to_tap(1)],
        [[OUT_STD, "# foo\n# bar\n# baz\n"]],
        "All lines have proper prefix"
    );
};

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

warns {
    $note->set_message("");
    is([$note->to_tap], [], "no tap with an empty message");
    
    $note->set_message("\n");
    is([$note->to_tap], [], "newline on its own is not shown");
    
    $note->set_message("\nxxx");
    is([$note->to_tap], [[OUT_STD, "\n# xxx\n"]], "newline starting");
};

done_testing;
