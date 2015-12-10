package Test::Sync::Event::Note;
use strict;
use warnings;

use base 'Test::Sync::Event';
use Test::Sync::HashBase accessors => [qw/message/];

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

Test::Sync::Event::Note - Note event type

=head1 DESCRIPTION

Notes, typically rendered to STDOUT.

=head1 SYNOPSIS

    use Test::Sync::Context qw/context/;
    use Test::Sync::Event::Note;

    my $ctx = context();
    my $event = $ctx->Note($message);

=head1 ACCESSORS

=over 4

=item $note->message

The message for the note.

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
