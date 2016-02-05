package Test::Stream::Plugin::CanThread;
use strict;
use warnings;

use Test::Stream::Capabilities qw/CAN_THREAD/;

use Test::Stream::Plugin qw/import/;

sub load_ts_plugin {
    return if CAN_THREAD;

    require Test::Stream::Context;
    my $ctx = Test::Stream::Context::context();
    $ctx->plan(0, "SKIP", "This test requires a perl capable of threading.");
    $ctx->release;
    exit 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::CanThread - Skip a test file unless the system supports
threading

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

It is fairly common to write tests that need to use threads. Not all systems
support threads. This library does the hard work of checking if threading is
supported on the current system. If threading is not supported then this will
skip all tests and exit true.

=head1 SYNOPSIS

    use Test::Stream::Plugin::CanThread;

    ... Code that uses threads ...

=head1 EXPLANATION

Checking if the current system supports threading is not simple, here is an
example of how to do it:

    use Config;

    sub CAN_THREAD {
        # Threads are not reliable before 5.008001
        return 0 unless $] >= 5.008001;
        return 0 unless $Config{'useithreads'};

        # Devel::Cover currently breaks with threads
        return 0 if $INC{'Devel/Cover.pm'};
        return 1;
    }

Duplicating this non-trivial code in all tests that need to use threads is
dumb. It is easy to forget bits, or get it wrong. On top of these checks you
also need to tell the harness that no tests should run and why.

=head1 SEE ALSO

=over 4

=item L<Test::Stream::Plugin::CanFork>

Skip the test file if the system does not support forking.

=item L<Test::Stream>

Test::Stream::CanThread uses L<Test::Stream> under the hood.

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
