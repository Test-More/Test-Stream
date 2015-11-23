package Test::Stream::Event::Skip;
use strict;
use warnings;

# Skip is a special class of Pass. Skip 'Reason' is the only difference.
use base 'Test::Stream::Event::Pass';
use Test::Stream::HashBase accessors => [qw/reason/];

1;
