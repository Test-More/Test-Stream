package Test::Stream::Interceptor::Formatter;
use strict;
use warnings;

use Test::Stream::HashBase(
    accessors => [qw/events/],
);

sub init {
    my $self = shift;
    $self->{+EVENTS} = [];
}

sub write {
    my ($self, $e) = @_;
    push @{$self->{+EVENTS}} => $e;
}

1;
