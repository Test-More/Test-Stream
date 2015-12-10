use strict;
use warnings;

use Test::Sync::Tester;
use Test::Sync::Event::Waiting;

my $waiting = Test::Sync::Event::Waiting->new(
    debug => 'fake',
);

ok($waiting, "Created event");
ok($waiting->global, "waiting is global");

done_testing;
