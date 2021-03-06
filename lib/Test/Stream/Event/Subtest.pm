package Test::Stream::Event::Subtest;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Carp qw/confess/;

use Test::Stream::Formatter::TAP qw/OUT_STD/;

use base 'Test::Stream::Event::Ok';
use Test::Stream::HashBase accessors => [qw/subevents buffered/];

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->{+SUBEVENTS} ||= [];
}

sub to_tap {
    my $self = shift;
    my ($num) = @_;

    my ($ok, @diag) = $self->SUPER::to_tap($num);

    return (
        $ok,
        @diag
    ) unless $self->{+BUFFERED};

    if ($ENV{HARNESS_IS_VERBOSE}) {
        $_->[1] =~ s/^/    /mg for @diag;
    }

    $ok->[1] =~ s/\n/ {\n/;

    my $count = 0;
    my @subs = map {
        $count++ if $_->isa('Test::Stream::Event::Ok');
        map { $_->[1] =~ s/^/    /mg; $_ } $_->to_tap($count);
    } @{$self->{+SUBEVENTS}};

    return (
        $ok,
        @diag,
        @subs,
        [OUT_STD(), "}\n"],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Subtest - Event for subtest types

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

This class represents a subtest. This class is a subclass of
L<Test::Stream::Event::Ok>.

=head1 ACCESSORS

This class inherits from L<Test::Stream::Event::Ok>.

=over 4

=item $arrayref = $e->subevents

Returns the arrayref containing all the events from the subtest

=item $bool = $e->buffered

True if the subtest is buffered, that is all subevents render at once. If this
is false it means all subevents render as they are produced.

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

See F<http://dev.perl.org/licenses/>

=cut
