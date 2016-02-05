package Test::Stream::Plugin::SRand;
use strict;
use warnings;

use Test::Stream::Plugin qw/import/;
use Test::Stream::Sync();

use Carp qw/carp/;

use Test::Stream::Context qw/context/;

my $ADDED_HOOK = 0;
my $SEED;
my $FROM;

sub seed { $SEED }
sub from { $FROM }

sub load_ts_plugin {
    my $class = shift;
    my $caller = shift;

    carp "SRand loaded multiple times, re-seeding rand"
        if defined $SEED;

    if (@_) {
        ($SEED) = @_;
        $FROM = 'import arg'
    }
    elsif(exists $ENV{TS_RAND_SEED}) {
        $SEED = $ENV{TS_RAND_SEED};
        $FROM = 'environment variable'
    }
    else {
        my @ltime = localtime;
        $SEED = sprintf('%04d%02d%02d', 1900 + $ltime[5], 1 + $ltime[4], $ltime[3]);
        $FROM = 'local date';
    }

    $SEED = 0 unless $SEED;
    srand($SEED);

    if ($ENV{HARNESS_IS_VERBOSE}) {
        # If the harness is verbose then just display the message for all to
        # see. It is nice info and they already asked for noisy output.
        Test::Stream::Sync->post_load(sub {
            my $ctx = context();
            $ctx->note("Seeded srand with seed '$SEED' from $FROM.");
            $ctx->release;
        });
    }
    elsif (!$ADDED_HOOK++) {
        # The seed can be important for debugging, so if anything is wrong we
        # should output the seed message as a diagnostics message. This must be
        # done at the very end, even later than a hub hook.
        Test::Stream::Sync->add_hook(
            sub {
                my ($ctx, $real, $new) = @_;

                $ctx->diag("Seeded srand with seed '$SEED' from $FROM.")
                    if $real
                    || ($new && $$new)
                    || !$ctx->hub->state->is_passing;
            }
        );
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::SRand - Control the random seed for more controlled test
environments.

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

This module gives you control over the random seed used for your unit tests. In
some testing environments the random seed can play a major role in results.

The default configuration for this module will seed srand with the local date.
Using the date as the seed means that on any given day the random seed will
always be the same, this means behavior will not change from run to run on a
given day. However the seed is different on different days allowing you to be
sure the code still works with actual randomness.

The seed is printed for you on failure, or when the harness is verbose. You can
use the C<TS_RAND_SEED> environment variable to specify the seed. You can also
provide a specific seed as a load-time argument to the plugin.

=head1 SYNOPSIS

Loading the plugin is easy, and the defaults are sane:

    use Test::Stream 'SRand';

Custom seed:

    use Test::Stream SRand => ['42'];

=head1 NOTE ON LOAD ORDER

If you use this plugin you probably want to use it as the first, or near-first
plugin. C<srand> is not called until the plugin is loaded, so other plugins
loaded first may already be making use of random numbers before your seed
takes effect.

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
