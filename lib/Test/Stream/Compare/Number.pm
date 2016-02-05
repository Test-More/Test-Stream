package Test::Stream::Compare::Number;
use strict;
use warnings;

use Carp qw/confess/;

use base 'Test::Stream::Compare';
use Test::Stream::HashBase accessors => [qw/input negate/];

sub init {
    my $self = shift;
    my $input = $self->{+INPUT};

    confess "input must be defined for 'Number' check"
        unless defined $input;

    # Check for ''
    confess "input must be a number for 'Number' check"
        unless length($input) && $input =~ m/\S/;

    $self->SUPER::init(@_);
}

sub name {
    my $self = shift;
    my $in = $self->{+INPUT};
    return $in;
}

sub operator {
    my $self = shift;
    return '' unless @_;
    my ($got) = @_;

    return '' unless defined($got);
    return '' unless length($got) && $got =~ m/\S/;

    return '!=' if $self->{+NEGATE};
    return '==';
}

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;
    return 0 unless defined $got;
    return 0 if ref $got;
    return 0 unless length($got) && $got =~ m/\S/;

    my $input  = $self->{+INPUT};
    my $negate = $self->{+NEGATE};

    my @warnings;
    my $out;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        $out = $negate ? ($input != $got) : ($input == $got);
    }

    for my $warn (@warnings) {
        if ($warn =~ m/numeric/) {
            $out = 0;
            next; # This warning won't help anyone.
        }
        warn $warn;
    }

    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Compare::Number - Compare 2 values as numbers

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

This is used to compare 2 numbers. You can also check that 2 numbers are not
the same.

B<Note>: This will fail if the recieved value is undefined, it must be a number.

B<Note>: This will fail if the comparison generates a non-numeric value warning
(which will not be shown), this is because it must get a number. The warning is
not shown as it will report to a useless line and filename, however the test
diagnotics show both values.

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
