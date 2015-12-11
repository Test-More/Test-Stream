use strict;
use warnings;

use Test::Sync::Global;
use Test::Sync qw/context/;

sub done_testing {
    my $ctx = context();
    my $state = $ctx->hub->state;

    die "Test Already ended!" if $state->ended;
    $ctx->hub->finalize($ctx->debug, 1);
    $ctx->release;
}

sub ok($;$) {
    my ($bool, $name) = @_;
    my $ctx = context();
    $ctx->ok($bool, $name);
    $ctx->release;
}

ok(1, "First");

my $todo = Test::Sync::Global->stack->top->set_todo('here be dragons');
ok(0, "Second");
$todo = undef;

ok(1, "Third");

done_testing;

1;
