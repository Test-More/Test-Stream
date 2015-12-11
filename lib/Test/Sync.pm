package Test::Sync;
use strict;
use warnings;

use Test::Sync::Global;
use Test::Sync::Context;

use Carp qw/croak confess/;

use vars qw/$VERSION/;
$Test::Sync::VERSION = '1.302026';
$VERSION = eval $VERSION;

# Note, sub context is in our namespace because of Test::Sync::Context, see it
# defined there.
our @EXPORT_OK = qw/context release/;
use base 'Exporter';

sub release ($;@) {
    $_[0]->release;
    shift; # Remove undef that used to be our $self reference.
    return @_ > 1 ? @_ : $_[0];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync - Synchronization library for testing frameworks.

=head1 DESCRIPTION

B<This library is not intended for people who just want to write tests.> See
L<Test::Stream> or L<Test::More> if you are just tryingto write some tests.

This library is intended to synchronize events between any number of testing
tools or infrastructures. This library is intended to replace L<Test::Builder>
as the new common base for test tools. In the near future L<Test::Builder> will
use L<Test::Sync> under the hood.

=head1 SYNOPSIS

Here is an example tool that provides the C<ok()> function that behaves just
like the one in L<Test::More>.

    package Test::MyOk;
    use Test::Sync qw/context/;

    our @EXPORT = qw/ok/;
    use base 'Exporter';

    sub ok($;$) {
        my ($bool, $name) = @_;

        # Always obtain a context as early as possible
        my $ctx = context();

        # Send an 'ok' event
        $ctx->ok($bool, $name);

        # Always release the context before you return!
        $ctx->release;

        # Return a boolean pass or fail
        return $bool ? 1 : 0;
    }

    1;

=head1 EXPORTS

=over 4

=item $ctx = context()

This will return an L<Test::Sync::Context> object. The context object is your
primary interface for all things testing. See the L<Test::Sync::Context>
documentation for additional details.

=item release $ctx, $return

=item release $ctx, @return

This is a shortcut for release a context and returning a value.  This tool is
most useful when you want to return the value you get from calling a function
that needs to see the current context.

    sub foo {
        my $ctx = context();
        return release $ctx, do_something();
    }

This is the same as

    sub foo {
        my $ctx = context();
        my $val = do_something();
        $ctx->release;
        return $val;
    }

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
