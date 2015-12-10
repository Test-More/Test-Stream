package Test::Sync::Subtest;
use strict;
use warnings;

use Test::Sync::Context qw/context/;
use Test::Sync::Util qw/try/;

use Test::Sync::Event::Subtest();
use Test::Sync::Hub::Subtest();

our @EXPORT_OK = qw/subtest/;
use base 'Exporter';

sub subtest {
    my ($name, $code, $buffered, @args) = @_;

    my $ctx = context();

    $ctx->note($name) unless $buffered;

    my $parent = $ctx->hub;

    my $stack = $ctx->stack || Test::Sync->stack;
    my $hub = $stack->new_hub(
        class => 'Test::Sync::Hub::Subtest',
    );

    my @events;
    $hub->set_nested( $parent->isa('Test::Sync::Hub::Subtest') ? $parent->nested + 1 : 1 );
    $hub->listen(sub { push @events => $_[1] });
    $hub->format(undef) if $buffered;

    $hub->set_parent_todo(1) if defined $parent->get_todo;

    my ($ok, $err, $finished);
    TS_SUBTEST_WRAPPER: {
        ($ok, $err) = try { $code->(@args) };

        # They might have done 'BEGIN { skip_all => "whatever" }'
        if (!$ok && $err =~ m/Label not found for "last TS_SUBTEST_WRAPPER"/) {
            $ok  = undef;
            $err = undef;
        }
        else {
            $finished = 1;
        }
    }
    $stack->pop($hub);

    my $dbg = $ctx->debug;

    if (!$finished) {
        if(my $bailed = $hub->bailed_out) {
            $ctx->bail($bailed->reason);
        }
        my $code = $hub->exit_code;
        $ok = !$code;
        $err = "Subtest ended with exit code $code" if $code;
    }

    $hub->finalize($dbg, 1)
        if $ok
        && !$hub->no_ending
        && !$hub->state->ended;

    my $pass = $ok && $hub->state->is_passing;
    my $e = $ctx->build_event(
        'Subtest',
        pass => $pass,
        name => $name,
        buffered  => $buffered,
        subevents => \@events,
    );

    $e->set_diag([
        $e->default_diag,
        $ok ? () : ("Caught exception in subtest: $err"),
    ]) unless $pass;

    $ctx->hub->send($e);

    $ctx->release;
    return $hub->state->is_passing;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::Subtest - Subtest implementation details

=head1 DESCRIPTION

This module encapsulates the implementation details of subtests. This is
intended for writing tools that produce subtests. This package is NOT intended
for people trying to use subtest in their test files, it is too low level for
that.

=head1 SYNOPSIS

    use Test::Sync::Subtest qw/subtest/;

    # Run a subtest
    subtest($name, $coderef, $bufferd, @args);

=head1 IMPORTANT NOTE

You can use C<bail_out> or C<skip_all> in a subtest, but not in a BEGIN block
or use statement. This is due to the way flow control works within a begin
block. This is not normally an issue, but can happen in rare conditions using
eval, or script files as subtests.

=head1 EXPORTS

=over 4

=item subtest($name, $coderef, $buffered, @args)

This will run a subtest. C<$name> is the name of the subtest. C<$coderef> is
the code to run in the subtest. C<$buffered> is a boolean, when true subtest
output will be buffered. C<@args> are all passed as arguments into the
C<$coderef>.

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
