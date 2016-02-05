package Test::Stream::Event::Bail;
use strict;
use warnings;

use Test::Stream::Formatter::TAP qw/OUT_STD/;

use base 'Test::Stream::Event';
use Test::Stream::HashBase accessors => [qw/reason/];

sub to_tap {
    my $self = shift;
    return [
        OUT_STD,
        "Bail out!  " . $self->reason . "\n",
    ];
}

sub update_state {
    my $self = shift;
    my ($state) = @_;

    $state->set_bailed_out($self);
    $state->bump_fail;
}

# Make sure the tests terminate
sub terminate { 255 };

sub global { 1 };

sub causes_fail { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Bail - Bailout!

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

The bailout event is generated when things go horribly wrong and you need to
halt all testing in the current file.

=head1 SYNOPSIS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Bail;

    my $ctx = context();
    my $event = $ctx->bail('Stuff is broken');

=head1 METHODS

Inherits from L<Test::Stream::Event>. Also defines:

=over 4

=item $reason = $e->reason

The reason for the bailout.

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
