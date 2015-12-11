package Test::Sync::Event::Diag;
use strict;
use warnings;

use base 'Test::Sync::Event';
use Test::Sync::HashBase accessors => [qw/message todo/];

sub init {
    $_[0]->SUPER::init();
    if (defined $_[0]->{+MESSAGE}) {
        $_[0]->{+MESSAGE} .= "";
    }
    else {
        $_[0]->{+MESSAGE} = 'undef';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::Event::Diag - Diag event type

=head1 DESCRIPTION

Diagnostics messages, typically rendered to STDERR.

=head1 SYNOPSIS

    use Test::Sync::Context qw/context/;
    use Test::Sync::Event::Diag;

    my $ctx = context();
    my $event = $ctx->diag($message);

=head1 ACCESSORS

=over 4

=item $diag->message

The message for the diag.

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
