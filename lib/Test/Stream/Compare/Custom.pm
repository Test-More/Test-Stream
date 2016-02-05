package Test::Stream::Compare::Custom;
use strict;
use warnings;

use base 'Test::Stream::Compare';
use Test::Stream::HashBase accessors => [qw/code name operator/];

use Carp qw/croak/;

sub init {
    my $self = shift;

    croak "'code' is required" unless $self->{+CODE};

    $self->{+OPERATOR} ||= 'CODE(...)';
    $self->{+NAME}     ||= '<Custom Code>';

    $self->SUPER::init();
}

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    my $code = $self->{+CODE};

    local $_ = $got;
    my $ok = $code->(
        got      => $got,
        exists   => $exists,
        operator => $self->{+OPERATOR},
        name     => $self->{+NAME}
    );

    return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Compare::Custom - Custom field check for comparisons.

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

Sometimes you want to do something complicated or unusual when validating a
field nested inside a deep data structure. You could pull it out of the
structure and test it separately, or you can use this to embed the check. This
provides a way for you to write custom checks for fields in deep comparisons.

=head1 SYNOPSIS

    my $cus = Test::Stream::Compare::Custom->new(
        name => 'IsRef',
        operator => 'ref(...)',
        code => sub {
            my ($got, $exists, $operator, $name) = @_;
            return ref($got) ? 1 : 0;
        },
    );

    # Pass
    is(
        { a => 1, ref => {},   b => 2 },
        { a => 1, ref => $cus, b => 2 },
        "This will pass"
    );

    # Fail
    is(
        {a => 1, ref => 'notref', b => 2},
        {a => 1, ref => $cus,     b => 2},
        "This will fail"
    );

=head1 ARGUMENTS

Your custom sub will get 4 arguments:

    code => sub {
        my ($got, $exists, $operator, $name) = @_;
        return ref($got) ? 1 : 0;
    },

C<$_> is also localized to C<$got> to make it easier for those who need to use
regexes.

=over 4

=item $got

=item $_

This is the value to be checked.

=item $exists

This will be a boolean. This will be true if C<$got> exists at all. If
C<$exists> is false then it means C<$got> is not simply undef, but doesn't
exist at all (think checking the value of a hash key that does not exist).

=item $operator

This is the operator specified at construction.

=item $name

This is the name provided at construction.

=back

=head1 METHODS

=over 4

=item $code = $cus->code

Get the coderef provided at construction.

=item $name = $cus->name

Get the name provided at construction.

=item $op = $cus->operator

Get the operator provided at construction

=item $bool = $cus->verify(got => $got, exists => $bool)

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
