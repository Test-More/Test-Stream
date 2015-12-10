use strict;
use warnings;
use Test::Sync::Tester;

use Test::Sync::Event();

my $ok = eval { Test::Sync::Event->new(); 1 };
my $err = $@;
ok(!$ok, "Died");
like($err, qr/No debug info provided/, "Need debug info");

{
    package My::MockEvent;

    use base 'Test::Sync::Event';
    use Test::Sync::HashBase accessors => [qw/foo bar baz/];
}

ok(My::MockEvent->can($_), "Added $_ accessor") for qw/foo bar baz/;

my $one = My::MockEvent->new(debug => 'fake');

ok(!$one->causes_fail, "Events do not cause failures by default");

ok(!$one->$_, "$_ is false by default") for qw/update_state terminate global/;

done_testing;
