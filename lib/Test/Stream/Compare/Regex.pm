package Test::Stream::Compare::Regex;
use strict;
use warnings;

use base 'Test::Stream::Compare';
use Test::Stream::HashBase accessors => [qw/input/];

use Test::Stream::Util qw/render_ref rtype/;
use Scalar::Util qw/reftype refaddr/;
use Carp qw/croak/;

sub init {
    my $self = shift;

    croak "'input' is a required attribute"
        unless $self->{+INPUT};

    croak "'input' must be a regex , got '" . $self->{+INPUT} . "'"
        unless rtype($self->{+INPUT}) eq 'REGEXP';

    $self->SUPER::init();
}

sub stringify_got { 1 }

sub operator { 'eq' }

sub name { "" . $_[0]->{+INPUT} };

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;

    my $in = $self->{+INPUT};
    my $got_type = rtype($got) or return 0;

    return 0 unless $got_type eq 'REGEXP';

    return "$in" eq "$got";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Compare::Regex - Regex direct comparison

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

Used to compare 2 regexes. This compares the stringified form of each regex.

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
