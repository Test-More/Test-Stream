package Test::Stream::Compare::Meta;
use strict;
use warnings;

use Test::Stream::Delta;

use Test::Stream::Compare;
use Test::Stream::HashBase(
    base => 'Test::Stream::Compare',
    accessors => [qw/items/],
);

use Carp qw/croak confess/;
use Scalar::Util qw/reftype blessed/;

sub init {
    my $self = shift;
    $self->{+ITEMS} ||= [];
}

sub name { '<META CHECKS>' }

sub verify { 1 }

sub add_prop {
    my $self = shift;
    my ($name, $check) = @_;

    croak "prop name is required"
        unless defined $name;

    croak "check is required"
        unless defined $check;

    my $meth = "get_prop_$name";
    croak "'$name' is not a known property"
        unless $self->can($meth);

    push @{$self->{+ITEMS}} => [$meth, $check, $name];
}

sub deltas {
    my $self = shift;
    my ($got, $convert, $seen) = @_;

    my @deltas;
    my $items = $self->{+ITEMS};

    for my $set (@$items) {
        my ($meth, $check, $name) = @$set;

        $check = $convert->($check);

        my $val = $self->$meth($got);

        push @deltas => $check->run(
            id      => [META => $name],
            got     => $val,
            convert => $convert,
            seen    => $seen,
        );
    }

    return @deltas;
}

sub get_prop_blessed { blessed($_[1]) }

sub get_prop_reftype { reftype($_[1]) }

sub get_prop_this { $_[1] }

sub get_prop_size {
    my $self = shift;
    my ($it) = @_;

    my $type = reftype($it) || '';

    return scalar @$it      if $type eq 'ARRAY';
    return scalar keys %$it if $type eq 'HASH';
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Compare::Meta - Check library for meta-checks

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 DESCRIPTION

Sometimes in a deep comparison you want to run extra checks against an item
down the chain. This library allows you to write a check that verifies several
attributes of an item.

=head1 DEFINED CHECKS

=over 4

=item blessed

Lets you check that an item is blessed, and that it is blessed into the
expected class.

=item reftype

Lets you check the reftype of the item.

=item this

Lets you check the item itself.

=item size

Lets you check the size of the item, for an arrayref this is the number of
elements, for a hashref this is the number of keys, for everything else this is
undef.

=back

=head1 SOURCE

The source code repository for Test::Stream can be found at
F<http://github.com/Test-More/Test-Stream/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
