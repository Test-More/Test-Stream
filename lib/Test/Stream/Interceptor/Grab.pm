package Test::Stream::Interceptor::Grab;
use strict;
use warnings;

use Test::Stream::DebugInfo;
use Test::Stream::Interceptor::Hub;
use Test::Stream::Interceptor::Formatter;

use Test::Stream::Context qw/PUSH_HUB POP_HUB TOP_HUB/;

use Test::Stream::HashBase(
    accessors => [qw/hub finished/],
);

sub init {
    my $self = shift;

    my $ipc;
    if ($INC{'Test/Stream/IPC.pm'}) {
        my ($driver) = Test::Stream::IPC->drivers;
        $ipc = $driver->new;
    }

    $self->{+HUB} = Test::Stream::Interceptor::Hub->new(
        ipc => $ipc,
        formatter => Test::Stream::Interceptor::Formatter->new,
        no_ending => 1,
    );

    TOP_HUB(); # Make sure there is a top hub before we begin.
    PUSH_HUB($self->{+HUB});
}

sub flush {
    my $self = shift;
    my $out = $self->{+HUB}->format->events;
    $self->{+HUB}->format->set_events([]);
    return $out;
}

sub events {
    my $self = shift;
    # Copy
    return [@{$self->{+HUB}->format->events}];
}

sub finish {
    my ($self) = @_; # Do not shift;
    $_[0] = undef;

    my $hub = $self->{+HUB};

    $self->{+FINISHED} = 1;
    POP_HUB($hub);

    my $dbg = Test::Stream::DebugInfo->new(
        frame => [caller(0)],
    );
    $hub->finalize($dbg, 1)
        if !$hub->no_ending
        && !$hub->state->ended;

    return $self->flush;
}

sub DESTROY {
    my $self = shift;
    return if $self->{+FINISHED};
    POP_HUB($self->{+HUB});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Interceptor::Grab - Object used to temporarily intercept all
events.

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 DESCRIPTION

Once created this object will intercept and stash all events sent to the shared
L<Test::Stream::Hub> object. Once the object is destroyed events will once
again be sent to the shared hub.

=head1 SYNOPSIS

    use Test::More;
    use Test::Stream::Tester::Grab;

    my $grab = Test::Stream::Tester::Grab->new();

    # Generate some events, they are intercepted.
    ok(1, "pass");
    ok(0, "fail");

    my $events_a = $grab->flush;

    # Generate some more events, they are intercepted.
    ok(1, "pass");
    ok(0, "fail");

    # Same as flush, except it destroys the grab object.
    my $events_b = $grab->finish;

After calling C<finish()> the grab object is destroyed and C<$grab> is set to
undef. C<$events_a> is an arrayref with the first 2 events. C<$events_b> is an
arrayref with the second 2 events.

=head1 METHODS

=over 4

=item $grab = $class->new()

Create a new grab object, immediately starts intercepting events.

=item $ar = $grab->flush()

Get an arrayref of all the events so far, clearing the grab objects internal
list.

=item $ar = $grab->events()

Get an arrayref of all events so far, does not clear the internal list.

=item $ar = $grab->finish()

Get an arrayref of all the events, then destroy the grab object.

=item $hub = $grab->hub()

Get the hub that is used by the grab event.

=back

=head1 ENDING BEHAVIOR

By default the hub used has C<no_ending> set to true. This will prevent the hub
from enforcing that you issued a plan and ran at least 1 test. You can turn
enforcement back one like this:

    $grab->hub->set_no_ending(0);

With C<no_ending> turned off, C<finish> will run the post-test checks to
enforce the plan and that tests were run. In many cases this will result in
additional events in your events array.

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
