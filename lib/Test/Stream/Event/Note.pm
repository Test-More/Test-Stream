package Test::Stream::Event::Note;
use strict;
use warnings;

use Test::Stream::Formatter::TAP qw/OUT_STD/;

use base 'Test::Stream::Event';
use Test::Stream::HashBase accessors => [qw/message/];

sub init {
    $_[0]->SUPER::init();
    if (defined $_[0]->{+MESSAGE}) {
        $_[0]->{+MESSAGE} .= "";
    }
    else {
        $_[0]->{+MESSAGE} = 'undef';
    }
}

sub to_tap {
    my $self = shift;

    chomp(my $msg = $self->{+MESSAGE});
    return unless $msg;
    $msg = "# $msg" unless $msg =~ m/^\n/;
    $msg =~ s/\n/\n# /g;

    return [OUT_STD, "$msg\n"];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Note - Note event type

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

Notes, typically rendered to STDOUT.

=head1 SYNOPSIS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Note;

    my $ctx = context();
    my $event = $ctx->Note($message);

=head1 ACCESSORS

=over 4

=item $note->message

The message for the note.

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
