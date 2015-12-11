package Test::Sync::Event::Exception;
use strict;
use warnings;

use base 'Test::Sync::Event';
use Test::Sync::HashBase accessors => [qw/error/];

sub update_state {
    my $self = shift;
    my ($state) = @_;

    $state->bump_fail;
    return undef;
}

sub causes_fail { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::Event::Exception - Exception event

=head1 DESCRIPTION

An exception event will display to STDERR, and will prevent the overall test
file from passing.

=head1 SYNOPSIS

    use Test::Sync::Context qw/context/;
    use Test::Sync::Event::Exception;

    my $ctx = context();
    my $event = $ctx->send_event('Exception', error => 'Stuff is broken');

=head1 METHODS

Inherits from L<Test::Sync::Event>. Also defines:

=over 4

=item $reason = $e->error

The reason for the exception.

=back

=head1 SOURCE

The source code repository for Test::Sync can be found at
F<http://github.com/Test-More/Test-Sync/>.

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
