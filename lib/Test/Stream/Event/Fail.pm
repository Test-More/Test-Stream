package Test::Stream::Event::Fail;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Carp qw/confess/;

use base 'Test::Stream::Event';
use Test::Stream::HashBase accessors => [qw/name diag allow_bad_name/];

sub init {
    my $self = shift;

    confess("No debug info provided!") unless $self->{+DEBUG};

    return if $self->{+ALLOW_BAD_NAME};
    my $name = $self->{+NAME} || return;
    return unless index($name, '#') != -1 || index($name, "\n") != -1;
    $self->debug->throw("'$name' is not a valid name, names must not contain '#' or newlines.")
}

sub default_diag {
    my $self = shift;

    my $name  = $self->{+NAME};
    my $dbg   = $self->{+DEBUG};
    my $todo  = defined $dbg->todo;

    my $msg = $todo ? "Failed (TODO)" : "Failed";
    my $prefix = $ENV{HARNESS_ACTIVE} && !$ENV{HARNESS_IS_VERBOSE} ? "\n" : "";

    my $trace = $dbg->trace;

    if (defined $name) {
        $msg = qq[$prefix$msg test '$name'\n$trace.];
    }
    else {
        $msg = qq[$prefix$msg test $trace.];
    }

    return $msg;
}

sub update_state {
    my $self = shift;
    my ($state) = @_;

    my $pass = $self->{+DEBUG}->no_fail ? 1 : 0;

    $state->bump($pass);
}

sub causes_fail {
    my $self = shift;
    return $self->{+DEBUG}->no_fail ? 0 : 1;
}

1;
