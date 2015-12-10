package Test::Sync::Hub::Subtest;
use strict;
use warnings;

use base 'Test::Sync::Hub';
use Test::Sync::HashBase accessors => [qw/nested bailed_out exit_code/];

sub process {
    my $self = shift;
    my ($e) = @_;
    $e->set_nested($self->nested);
    $self->set_bailed_out($e) if $e->isa('Test::Sync::Event::Bail');
    $self->SUPER::process($e);
}

sub terminate {
    my $self = shift;
    my ($code) = @_;
    $self->set_exit_code($code);
    no warnings 'exiting';
    last TS_SUBTEST_WRAPPER;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::Hub::Subtest - Hub used by subtests

=head1 DESCRIPTION

Subtests make use of this hub to route events.

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
