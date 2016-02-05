package Test::Stream::Compare::Pattern;
use strict;
use warnings;

use base 'Test::Stream::Compare';
use Test::Stream::HashBase accessors => [qw/pattern negate stringify_got/];

use Carp qw/croak/;

sub init {
    my $self = shift;

    croak "'pattern' is a required attribute" unless $self->{+PATTERN};

    $self->{+STRINGIFY_GOT} ||= 0;

    $self->SUPER::init();
}

sub name { shift->{+PATTERN} . "" }
sub operator { shift->{+NEGATE} ? '!~' : '=~' }

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;
    return 0 unless defined($got);
    return 0 if ref $got && !$self->stringify_got;

    return $got !~ $self->{+PATTERN}
        if $self->{+NEGATE};

    return $got =~ $self->{+PATTERN};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Compare::Pattern - Use a pattern to validate values in a deep
comparison.

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

This allows you to use a regex to validate a value in a deep comparison.
Sometimes a value just needs to look right, it may not need to be exact. An
example is a memory address, it might change from run to run.

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
