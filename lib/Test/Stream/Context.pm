package Test::Stream::Context;
use strict;
use warnings;

use Scalar::Util qw/weaken/;

use Carp qw/confess croak/;

use Test::Stream::Capabilities qw/CAN_FORK/;

use Test::Stream::Hub;
use Test::Stream::TAP;
use Test::Stream::Util qw/get_tid USE_THREADS/;
use Test::Stream::DebugInfo;

# Preload some key event types
my %LOADED = (
    map {
        require "Test/Stream/Event/$_.pm";
        my $pkg = "Test::Stream::Event::$_";
        ( $pkg => $pkg, $_ => $pkg )
    } qw/Ok Diag Note Plan Bail Exception Waiting/
);

my @HUB_STACK;
my %CONTEXTS;
my $NO_WAIT;

use Test::Stream::Exporter qw/import export_to exports/;
exports qw/TOP_HUB PUSH_HUB POP_HUB NEW_HUB CULL context/;
no Test::Stream::Exporter;

# Set the exit status
my ($PID, $TID) = ($$, get_tid());
END {
    my $exit = $?;

    if ($PID != $$ || $TID != get_tid()) {
        $? = $exit;
        return;
    }

    if ($INC{'Test/Stream/IPC.pm'} && !$NO_WAIT) {
        my %seen;
        for my $hub (reverse @HUB_STACK) {
            my $ipc = $hub->ipc || next;
            next if $seen{$ipc}++;
            $ipc->waiting();
        }

        my $ipc_exit = IPC_WAIT();
        $exit ||= $ipc_exit;
    }

    my $dbg = Test::Stream::DebugInfo->new(
        frame => [ __PACKAGE__, __FILE__, __LINE__ + 4, 'END' ],
        detail => 'Test::Stream::Context END Block finalization',
    );
    my $hub_exit = 0;
    for my $hub (reverse @HUB_STACK) {
        next if $hub->no_ending;
        next if $hub->state->ended;
        $hub_exit += $hub->finalize($dbg, 1);
    }
    $exit ||= $hub_exit;

    if(my @unreleased = grep { $_ } values %CONTEXTS) {
        $exit ||= 255;
        for my $ctx (@unreleased) {
            $ctx->debug->alert("context object was never released! This means a testing tool is behaving very badly");
        }
    }

    @HUB_STACK = ();

    $exit = 255 if $exit > 255;

    $? = $exit;
}

sub NO_WAIT { ($NO_WAIT) = @_ if @_; $NO_WAIT }

sub IPC_WAIT {
    my $fail = 0;

    while (CAN_FORK()) {
        my $pid = CORE::wait();
        my $err = $?;
        last if $pid == -1;
        next unless $err;
        $fail++;
        $err = $err >> 8;
        warn "Process $pid did not exit cleanly (status: $err)\n";
    }

    if (USE_THREADS) {
        for my $t (threads->list()) {
            $t->join;
            my $err = $t->error;
            my $tid = $t->tid();
            $fail++;
            chomp($err);
            warn "Thread $tid did not end cleanly\n";
        }
    }

    return 0 unless $fail;
    return 255;
}

sub NEW_HUB {
    shift @_ if $_[0] && $_[0] eq __PACKAGE__;

    my ($ipc, $formatter);
    if (@HUB_STACK) {
        $ipc = $HUB_STACK[-1]->ipc;
        $formatter = $HUB_STACK[-1]->format;
    }
    else {
        $formatter = Test::Stream::TAP->new;
        if ($INC{'Test/Stream/IPC.pm'}) {
            my ($driver) = Test::Stream::IPC->drivers;
            $ipc = $driver->new;
        }
    }

    my $hub = Test::Stream::Hub->new(
        formatter => $formatter,
        ipc       => $ipc,
        @_,
    );

    return $hub;
}

sub TOP_HUB {
    push @HUB_STACK => NEW_HUB() unless @HUB_STACK;
    $HUB_STACK[-1];
}

sub PEEK_HUB { @HUB_STACK ? $HUB_STACK[-1] : undef }

sub PUSH_HUB {
    my $hub = pop;
    push @HUB_STACK => $hub;
}

sub POP_HUB {
    my $hub = pop;
    confess "You cannot pop the root hub"
        if 1 == @HUB_STACK;
    confess "Hub stack mismatch, attempted to pop incorrect hub"
        unless $HUB_STACK[-1] == $hub;
    pop @HUB_STACK;
}

sub CULL { $_->cull for reverse @HUB_STACK }

use Test::Stream::HashBase(
    accessors => [qw/hub debug depth on_release _err/],
);

sub init {
    confess "debug is required"
        unless $_[0]->{+DEBUG};

    confess "hub is required"
        unless $_[0]->{+HUB};
}

sub snapshot { bless {%{$_[0]}}, __PACKAGE__ }

sub release {
    my $cbk  = $_[0]->{+ON_RELEASE};
    my $dbg  = $_[0]->{+DEBUG};
    my $hub  = $_[0]->{+HUB};
    my $hid  = $hub->hid;
    my $hcbk = $hub->{_context_release};

    my $snap = $cbk || $hcbk ? $_[0]->snapshot : undef;

    # Here we trigger the destruction of the context, we are temporarily
    # replacing DESTROY so that the warning about not calling release does not
    # fire.
    no warnings 'redefine';
    local *DESTROY = \&_DESTROY;
    $_[0] = undef; # Kill this reference

    # Removing this reference did not remove the context, so we do not run our
    # release hooks yet.
    return if $CONTEXTS{$hid};

    if ($cbk) {
        $_->($snap) for @$cbk;
    }
    if ($hcbk) {
        $_->($snap) for @$hcbk;
    }
}

sub _DESTROY() {}
sub DESTROY {
    my ($self) = @_;

    my $hid = $self->{+HUB}->hid;

    return unless $CONTEXTS{$hid} && $CONTEXTS{$hid} == $self;
    return unless "$@" eq "" . $self->{+_ERR};

    my $debug = $self->{+DEBUG};
    my $frame = $debug->frame;

    warn <<"    EOT";
Context was not released! Releasing at destruction.
Context creation details:
  Package: $frame->[0]
     File: $frame->[1]
     Line: $frame->[2]
     Tool: $frame->[3]
    EOT

    if(my $cbk = $self->{+ON_RELEASE}) {
        $_->($self) for @$cbk;
    }

    if (my $hcbk = $self->{+HUB}->{_context_release}) {
        $_->($self) for @$hcbk;
    }
}

sub context {
    my %params = (level => 0, @_);

    croak "context() called, but return value is ignored"
        unless defined wantarray;

    my $hub = TOP_HUB();
    my $hid = $hub->{hid};
    my $current = $CONTEXTS{$hid};

    my $level = 1 + $params{level};
    my $depth = $level;
    $depth++ while caller($depth + 1) && (!$current || $depth <= $current->{+DEPTH});

    if ($current && $params{on_release}) {
        $current->{+ON_RELEASE} ||= [];
        push @{$current->{+ON_RELEASE}} => $params{on_release};
    }

    return $current if $current && $current->{+DEPTH} < $depth;

    my ($pkg, $file, $line, $sub) = caller($level);
    confess "Could not find context at depth $level"
        unless $pkg;

    # Handle error condition of bad level
    if ($current) {
        my $oldframe = $current->{+DEBUG}->frame;
        my $olddepth = $current->{+DEPTH};

        warn <<"        EOT";
context() was called to retrieve an existing context, however the existing
context was created in a stack frame at the same, or deeper level. This usually
means that a tool failed to release the context when it was finished.

Old context details:
   File: $oldframe->[1]
   Line: $oldframe->[2]
   Tool: $oldframe->[3]
  Depth: $olddepth

New context details:
   File: $file
   Line: $line
   Tool: $sub
  Depth: $depth

Removing the old context and creating a new one...
        EOT

        delete $CONTEXTS{$hid};
        $current->release;
    }

    # This is a good spot to poll for pending IPC results. This actually has
    # nothing to do with getting a context.
    $hub->cull if $INC{'Test/Stream/IPC.pm'};

    my $dbg = bless(
        {
            frame => [$pkg, $file, $line, $sub],
            todo  => $hub->get_todo,
            pid   => $$,
            tid   => get_tid(),
        },
        'Test::Stream::DebugInfo'
    );

    $current = bless(
        {
            HUB()   => $hub,
            DEBUG() => $dbg,
            DEPTH() => $depth,
            _ERR()  => $@,
            $params{on_release} ? (ON_RELEASE() => [ $params{on_release} ]) : (),
        },
        __PACKAGE__
    );

    weaken($CONTEXTS{$hub->hid} = $current);

    $params{on_init}->($current) if $params{on_init};

    if (my $hcbk = $hub->{_context_init}) {
        $_->($current) for @$hcbk;
    }

    return $current;
}

sub peek {
    my $hub = TOP_HUB();
    $CONTEXTS{$hub->hid}
}

sub clear {
    my $hub = TOP_HUB();
    delete $CONTEXTS{$hub->hid};
}

sub send_event {
    my $self  = shift;
    my $event = shift;
    my %args  = @_;

    my $pkg = $LOADED{$event} || $self->_parse_event($event);

    $self->{+HUB}->send(
        $pkg->new(
            debug => $self->{+DEBUG}->snapshot,
            %args,
        )
    );
}

sub build_event {
    my $self  = shift;
    my $event = shift;
    my %args  = @_;

    my $pkg = $LOADED{$event} || $self->_parse_event($event);

    $pkg->new(
        debug => $self->{+DEBUG}->snapshot,
        %args,
    );
}

sub ok {
    my $self = shift;
    my ($pass, $name, $diag) = @_;

    my $e = Test::Stream::Event::Ok->new(
        debug => $self->{+DEBUG}->snapshot,
        pass  => $pass,
        name  => $name,
    );

    return $self->hub->send($e) if $pass;

    $diag ||= [];
    unshift @$diag => $e->default_diag;

    $e->set_diag($diag);

    $self->hub->send($e);
}

sub note {
    my $self = shift;
    my ($message) = @_;
    $self->send_event('Note', message => $message);
}

sub diag {
    my $self = shift;
    my ($message) = @_;
    $self->send_event('Diag', message => $message);
}

sub plan {
    my ($self, $max, $directive, $reason) = @_;
    if ($directive && $directive =~ m/skip/i) {
        $self = $self->snapshot;
        $_[0]->release;
    }

    $self->send_event('Plan', max => $max, directive => $directive, reason => $reason);
}

sub bail {
    my ($self, $reason, $quiet) = @_;
    $self = $self->snapshot;
    $_[0]->release;
    $self->send_event('Bail', reason => $reason, quiet => $quiet);
}

sub _parse_event {
    my $self = shift;
    my $event = shift;

    my $pkg;
    if ($event =~ m/::/) {
        $pkg = $event;
    }
    else {
        $pkg = "Test::Stream::Event::$event";
    }

    confess "'$pkg' is not a subclass of 'Test::Stream::Event', did you forget to load it?"
        unless $pkg->isa('Test::Stream::Event');

    $LOADED{$pkg}   = $pkg;
    $LOADED{$event} = $pkg;

    return $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Context - Object to represent a testing context.

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 KEY CONCEPTS AND RESPONSIBILITIES

This class manages the singleton, and singleton-like object instances used by
all Test-Stream tools.

=head2 CONTEXT OBJECTS

Context objects are instances of L<Test::Stream::Context>. These are the
primary point of interaction into the Test-Stream framework.

A Context object is a semi-singleton in that they are not arbitrarily created
or creatable. At any given time there will be exactly 0 or 1 instances of a
context object per hub in the hub stack. If there is only 1 hub in the hub
stack, there will only be 1 context object, if any.

The 1 context object for any given hub will be destroyed automatically if there
are no external references to it. If there is an instance of the context object
for a given hub it will be returned any time you call C<context()>. If there
are no existing instances, a new one will be generated.

The context returned by C<context()> will always be the instance for whatever
hub is at the top of the stack.

=head2 THE HUB STACK

The L<Test::Stream::Hub> objects are responsbile for routing events and
maintaining state. In many cases you only ever need 1 hub object. However there
are times where it is useful to temporarily use a new hub. Some example use
cases of temporarily replacing the hub are subtests, and intercepting results
to test testing tools.

=head3 IPC

If you load L<Test::Stream::IPC> or an IPC driver BEFORE the root hub is
generated, then IPC will be used. IPC will not be loaded for you automatically.
When you request a new hub using C<NEW_HUB> it will inherit the IPC instance
from the current hub.

=head3 FORMATTER

The root hub will use L<Test::Stream::TAP> as its formatter by default. If you
want to change this you must get the hub either by using C<< $context->hub >>
or C<TOP_HUB()> and set/unset the formatter using the C<format()> method.

The formatter is inherited, that is if you use C<NEW_HUB> to create a new hub,
it will reference the current hubs formatter.

=head1 USING THE CONTEXT

    sub my_tool {
        my $ctx = context();

        ...

        $ctx->release; # This sets $ctx = undef

        ...
    }

This function is used to get the current context. If a tool down the stack has
already aquired the context then this will return it. If the context has not
already been aquired in the stack a new one will be returned.

When you are finished with the context you B<MUST> call C<< $ctx->release >>.
This allows the next tool to aquire a new context. This is also how some
callbacks are triggered.

You B<MUST NOT> pass contexts around between subs. Anything that needs to use
a context should call C<context()> again. Storing a context in a persistant
location beyond the end of your sub will cause problems. If you need to use the
context later you must create a snapshot C<< my $copy = $ctx->snapshot >>. The
snapshot is safe to store and use again.

=head2 CONTEXT OPTIONS

when you call context you can pass in the following options:

    context(
        level => 0, # This can be any integer, it defaults to 0
        on_init => sub {
            my $ctx = shift;
            ...
        },
        on_release => sub {
            my $ctx = shift;
            ...
        }
    );

=over 4

=item level => 0

Normally C<context()> gets the caller just above its own, this is considered
C<0>. You can set it to C<-1> to get the actual call to C<context()> itself.
You can also set it to an integer bigger than 0 to go further down the stack.

You almost never need this. This is only useful if you are calling C<context>
outside of a subroutine, or calling it nested within subroutines that do not
also obtain the context. Usually it is best to call context first thing in
whatever sub is your entry point.

=item on_init => sub { my $ctx = shift; ... }

This lets you provide a callback sub that will be called B<ONLY> if your call
to c<context()> generated a new context. The callback B<WILL NOT> be called if
C<contect()> is returning an existing context. The only argument passed into
the callback will be the context object itself.

    sub foo {
        my $ctx = context(on_init => sub { 'will run' });

        my $inner = sub {
            # This callback is not run since we are getting the existing
            # context from our parent sub.
            my $ctx = context(on_init => sub { 'will NOT run' });
            $ctx->release;
        }
        $inner->();

        $ctx->release;
    }

=item on_release => sub { my $ctx = shift; ... }

This lets you provide a callback sub that will be called when the context
instance is released. This callback will be added to the returned context even
if an existing context is returned. If multiple calls to context add callbacks
then all will be called in order when the context is finally released.

    sub foo {
        my $ctx = context(on_release => sub { 'will run first' });

        my $inner = sub {
            my $ctx = context(on_release => sub { 'will run second' });

            # Neither callback runs on this release
            $ctx->release;
        }
        $inner->();

        # Both callbacks run here.
        $ctx->release;
    }

=back

=head2 CONTEXT HUB HOOKS

Hub objects can have associated C<context_init> and C<context_release> hooks.
These hooks run after any callback hooks defined when C<context()> is called.
Please see L<Test::Stream::Hub> for information on using these hooks.

=head2 CONTEXT RULES

=over 4

=item Context objects must not be passed around or stored in a persistent place.

Under the hood a weak reference is used to keep track of the canonical
instance. This means that the canonical reference will go away as soon as all
external references are free. If you store a reference to the context object in
a persistant place this will result in a leaked context.

There is a protection in place to try and recover from such a situation (This
is the depth check mentioned below). The protection will warn you when it is
triggered, but is not fatal. The main reason this is a warning and not fatal is
that it is very easy for it to happen due to an exception that is caught in the
wrong place.

=item context() will release an existing context if it is called again from the same level, or a more shallow level.

    sub tool {
        my $ctx = context();
        ...
        # No call to release
    }

    # In both these cases context() initializes the context at stack depth of
    # 1. context() will notice this and release the old context in order to
    # create a new one. This will issue a warning to let you know it happened.
    tool();
    tool();

This is not fatal because it is very easy for code in that C<...> to throw an
exception preventing any call to C<release> from happening.

=item context() will throw an exception if you ignore the object it returns.

    sub tool {
        # This will throw an exception, you are not using the context() object it returns.
        context();
        ...
    }

The way contexts work with references means that ignoring the return from
C<context()> is nearly always a bug.

=back

=head2 REAL-WORLD EXAMPLE

    sub ok {
        my ($bool, $name) = @_;

        # Aquire the context
        my $ctx = context();

        # Send an 'Ok' event
        $ctx->ok($bool, $name);

        # Clean up the context
        $ctx->release;

        return $bool;
    }

    sub dual_ok {
        my ($bool1, $bool2, $name) = @_;

        my $ctx = context();

        # ok(), defined above, will get our $ctx when it calls context().
        ok($bool1, "$name part 1");
        ok($bool2, "$name part 2");

        $ctx->release;

        return $bool1 && $bool2;
    }

=head1 EXPORTS

B<Note:> Nothing is exported by default, you must choose what you want to
import.

Many of these also work fine as class methods on the Test::Stream::Context
class, when that is the case an example is provided.

=over 4

=item $ctx = context()

=item $ctx = context(...)

See the L</"USING THE CONTEXT"> section for details on this function.

=item $hub = TOP_HUB()

=item $hub = $class->TOP_HUB()

This will return the hub at the top of the stack. If there are no hubs on the
stack it will generate a root one for you.

=item $hub = NEW_HUB(%ARGS)

=item $hub = $class->NEW_HUB(%ARGS)

This will generate a new hub, any arguments are passed to the
L<Test::Stream::Hub> constructor. Unless you override them, this will set the
formatter and ipc instance to those of the current hub.

B<Note:> This does not add the hub to the hub stack.

=item PUSH_HUB($hub)

=item $class->PUSH_HUB($hub)

This is used to push a new hub onto the stack. This hub will be the hub used by
any new contexts until either a new hub is pushed above it, or it is popped.

=item POP_HUB($hub)

=item $class->POP_HUB($hub)

This is used to pop a hub off the stack. You B<Must> pass in the hub you think
you are popping. An exception will be thrown if you do not specify the hub to
expect, or the hub you expect is not on the top of the stack.

=item CULL()

=item $class->CULL()

This will cause all hubs in the current proc/thread to cull any IPC results
they have not yet collected.

=item NO_WAIT($bool)

=item $bool = NO_WAIT()

=item $class->NO_WAIT($bool)

=item $bool = $class->NO_WAIT()

Normally Test::Stream::Context will wait on all child processes and join all
non-detached threads before letting the parent process end. Setting this to
true will prevent this behavior.

=back

=head1 METHODS

=over 4

=item $ctx->release()

    # This also sets '$ctx = undef' using magic.
    $ctx->release;

Use this to note that the context is done. This will set C<$ctx> to undef, so
if you need to use the context object after it is released (you should never
need to do this) you will need to make a snapshot of it first using
C<< my $clone = $ctx->snapshot >>.

=item $hub = $ctx->hub()

This retrieves the L<Test::Stream::Hub> object associated with the current
context.

=item $dbg = $ctx->debug()

This retrieves the L<Test::Stream::DebugInfo> object associated with the
current context.

=item $copy = $ctx->snapshot;

This will make a B<SHALLOW> copy of the context object. This copy will have the
same hub, and the same instance of L<Test::Stream::DebugInfo>. However this
shallow copy can be saved without locking the context forever.

=item $ctx = $class->peek

This can be used to see if there is already a context for the current hub. This
will return undef if there is no current hub.

=item $class->clear

Remove the one true context for the current hub.

=back

=head2 EVENT PRODUCTION METHODS

=over 4

=item $e = $ctx->send_event($Type, %args)

Build and send an event of C<$Type> with the current context. C<$Type> may be a
full event package name, or the last part of C<Test::Stream::Event::*>. All
C<%args> are passed to the event constructor.

=item $e = $ctx->build_event($Type, %args)

Build an event of C<$Type> with the current context. C<$Type> may be a full
event package name, or the last part of C<Test::Stream::Event::*>. All C<%args>
are passed to the event constructor.

=item $e = $ctx->ok($pass, $name, \@diag)

Shortcut for sending 'Ok' events. This shortcut will add your diagnostics ONLY
in the event of a failure. This shortcut will also take care of adding the
default failure diagnostics for you.

=item $e = $ctx->note($message)

Shortcut for sendingg 'Note' events.

=item $e = $ctx->diag($message)

Shortcut for sending 'Diag' events.

=item $e = $ctx->plan($max)

=item $e = $ctx->plan(0, 'no_plan')

=item $e = $ctx->plan(0, 'skip_all' => $reason)

Shortcut for sending 'Plan' events.

=item $e = $ctx->bail($reason, $quiet)

Shortcut for sending 'bail' events.

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

=item Kent Fredric E<lt>kentnl@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
