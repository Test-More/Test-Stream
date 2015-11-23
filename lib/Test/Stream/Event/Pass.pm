package Test::Stream::Event::Pass;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Carp qw/confess/;

use base 'Test::Stream::Event';
use Test::Stream::HashBase accessors => [qw/name allow_bad_name/];

sub init {
    my $self = shift;

    confess("No debug info provided!") unless $self->{+DEBUG};

    return if $self->{+ALLOW_BAD_NAME};
    my $name = $self->{+NAME} || return;
    return unless index($name, '#') != -1 || index($name, "\n") != -1;
    $self->debug->throw("'$name' is not a valid name, names must not contain '#' or newlines.")
}

sub causes_fail { 0 }

sub update_state { $_[1]->bump(1) }

1;
