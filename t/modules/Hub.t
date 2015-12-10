use Test::Sync -V1, -SpecTester, Compare => [qw/is like match/];
use Test::Sync::Capabilities qw/CAN_FORK CAN_THREAD CAN_REALLY_FORK/;

{
    package My::Formatter;

    sub new { bless [], shift };

    my $check = 1;
    sub write {
        my $self = shift;
        my ($e, $count) = @_;
        push @$self => $e;
    }
}

{
    package My::Event;

    use base 'Test::Sync::Event';
    use Test::Sync::HashBase accessors => [qw/msg/];
}

tests basic => sub {
    my $hub = Test::Sync::Hub->new(
        formatter => My::Formatter->new,
    );

    my $send_event = sub {
        my ($msg) = @_;
        my $e = My::Event->new(msg => $msg, debug => 'fake');
        $hub->send($e);
    };

    ok(my $e1 = $send_event->('foo'), "Created event");
    ok(my $e2 = $send_event->('bar'), "Created event");
    ok(my $e3 = $send_event->('baz'), "Created event");

    my $old = $hub->format(My::Formatter->new);

    isa_ok($old, 'My::Formatter');
    is(
        $old,
        [$e1, $e2, $e3],
        "Formatter got all events"
    );
};

tests follow_ups => sub {
    my $hub = Test::Sync::Hub->new;
    $hub->state->set_count(1);

    my $dbg = Test::Sync::DebugInfo->new(
        frame => [__PACKAGE__, __FILE__, __LINE__],
    );

    my $ran = 0;
    $hub->follow_up(sub {
        my ($d, $h) = @_;
        is($d, $dbg, "Got debug");
        is($h, $hub, "Got hub");
        ok(!$hub->state->ended, "Hub state has not ended yet");
        $ran++;
    });

    like(
        dies { $hub->follow_up('xxx') },
        qr/follow_up only takes coderefs for arguments, got 'xxx'/,
        "follow_up takes a coderef"
    );

    $hub->finalize($dbg);

    is($ran, 1, "ran once");

    is(
        $hub->state->ended,
        $dbg->frame,
        "Ended at the expected place."
    );

    eval { $hub->finalize($dbg) };

    is($ran, 1, "ran once");

    $hub = undef;
};

tests IPC => sub {
    my ($driver) = Test::Sync::IPC->drivers;
    is($driver, 'Test::Sync::IPC::Files', "Default Driver");
    my $ipc = $driver->new;
    my $hub = Test::Sync::Hub->new(
        formatter => My::Formatter->new,
        ipc => $ipc,
    );

    my $build_event = sub {
        my ($msg) = @_;
        return My::Event->new(msg => $msg, debug => 'fake');
    };

    my $e1 = $build_event->('foo');
    my $e2 = $build_event->('bar');
    my $e3 = $build_event->('baz');

    my $do_send = sub {
        $hub->send($e1);
        $hub->send($e2);
        $hub->send($e3);
    };

    my $do_check = sub {
        my $name = shift;

        my $old = $hub->format(My::Formatter->new);

        isa_ok($old, 'My::Formatter');
        is(
            $old,
            [$e1, $e2, $e3],
            "Formatter got all events ($name)"
        );
    };

    if (CAN_REALLY_FORK) {
        my $pid = fork();
        die "Could not fork!" unless defined $pid;

        if ($pid) {
            is(waitpid($pid, 0), $pid, "waited properly");
            ok(!$?, "child exited with success");
            $hub->cull();
            $do_check->('Fork');
        }
        else {
            $do_send->();
            exit 0;
        }
    }

    if (CAN_THREAD && $] ge '5.010') {
        require threads;
        my $thr = threads->new(sub { $do_send->() });
        $thr->join;
        $hub->cull();
        $do_check->('Threads');
    }

    $do_send->();
    $hub->cull();
    $do_check->('no IPC');
};

tests listen => sub {
    my $hub = Test::Sync::Hub->new();

    my @events;
    my @counts;
    my $it = $hub->listen(sub {
        my ($h, $e, $count) = @_;
        is($h, $hub, "got hub");
        push @events => $e;
        push @counts => $count;
    });

    my $second;
    my $it2 = $hub->listen(sub { $second++ });

    my $ok1 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'foo',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok2 = Test::Sync::Event::Ok->new(
        pass => 0,
        name => 'bar',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok3 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'baz',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    $hub->send($ok1);
    $hub->send($ok2);

    $hub->unlisten($it);

    $hub->send($ok3);

    is(\@counts, [1, 2], "Got counts");
    is(\@events, [$ok1, $ok2], "got events");
    is($second, 3, "got all events in listener that was not removed");

    like(
        dies { $hub->listen('xxx') },
        qr/listen only takes coderefs for arguments, got 'xxx'/,
        "listen takes a coderef"
    );
};

tests metadata => sub {
    my $hub = Test::Sync::Hub->new();

    my $default = { foo => 1 };
    my $meta = $hub->meta('Foo', $default);
    is($meta, $default, "Set Meta");

    $meta = $hub->meta('Foo', {});
    is($meta, $default, "Same Meta");

    $hub->delete_meta('Foo');
    is($hub->meta('Foo'), undef, "No Meta");

    $hub->meta('Foo', {})->{xxx} = 1;
    is($hub->meta('Foo')->{xxx}, 1, "Vivified meta and set it");

    like(
        dies { $hub->meta(undef) },
        qr/Invalid key '\(UNDEF\)'/,
        "Cannot use undef as a meta key"
    );

    like(
        dies { $hub->meta(0) },
        qr/Invalid key '0'/,
        "Cannot use 0 as a meta key"
    );

    like(
        dies { $hub->delete_meta(undef) },
        qr/Invalid key '\(UNDEF\)'/,
        "Cannot use undef as a meta key"
    );

    like(
        dies { $hub->delete_meta(0) },
        qr/Invalid key '0'/,
        "Cannot use 0 as a meta key"
    );
};

tests munge => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    my $hub = Test::Sync::Hub->new();

    my @events;
    my $it = $hub->munge(sub {
        my ($h, $e) = @_;
        is($h, $hub, "got hub");
        push @events => $e;
    });

    my $count;
    my $it2 = $hub->munge(sub { $count++ });

    my $ok1 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'foo',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok2 = Test::Sync::Event::Ok->new(
        pass => 0,
        name => 'bar',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok3 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'baz',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    $hub->send($ok1);
    $hub->send($ok2);

    $hub->unmunge($it);

    $hub->send($ok3);

    is(\@events, [$ok1, $ok2], "got events");
    is($count, 3, "got all events, even after other munger was removed");

    $hub = Test::Sync::Hub->new();
    @events = ();

    $hub->munge(sub { $_[1] = undef });
    $hub->listen(sub {
        my ($hub, $e) = @_;
        push @events => $e;
    });

    $hub->send($ok1);
    $hub->send($ok2);
    $hub->send($ok3);

    ok(!@events, "Blocked events");

    like(
        dies { $hub->munge('xxx') },
        qr/munge only takes coderefs for arguments, got 'xxx'/,
        "munge takes a coderef"
    );

    delete $SIG{__WARN__};
    is(
        \@warnings,
        [
            match qr/use of mungers is deprecated, look at filters instead\. mungers will be removed in the near future\./,
            match qr/use of mungers is deprecated, look at filters instead\. mungers will be removed in the near future\./,
            match qr/use of mungers is deprecated, look at filters instead\. mungers will be removed in the near future\./,
            match qr/use of mungers is deprecated, look at filters instead\. mungers will be removed in the near future\./,
        ],
        "Got the warnings"
    );
};

tests filter => sub {
    my $hub = Test::Sync::Hub->new();

    my @events;
    my $it = $hub->filter(sub {
        my ($h, $e) = @_;
        is($h, $hub, "got hub");
        push @events => $e;
        return $e;
    });

    my $count;
    my $it2 = $hub->filter(sub { $count++; $_[1] });

    my $ok1 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'foo',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok2 = Test::Sync::Event::Ok->new(
        pass => 0,
        name => 'bar',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    my $ok3 = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'baz',
        debug => Test::Sync::DebugInfo->new(
            frame => [ __PACKAGE__, __FILE__, __LINE__ ],
        ),
    );

    $hub->send($ok1);
    $hub->send($ok2);

    $hub->unfilter($it);

    $hub->send($ok3);

    is(\@events, [$ok1, $ok2], "got events");
    is($count, 3, "got all events, even after other filter was removed");

    $hub = Test::Sync::Hub->new();
    @events = ();

    $hub->filter(sub { undef });
    $hub->listen(sub {
        my ($hub, $e) = @_;
        push @events => $e;
    });

    $hub->send($ok1);
    $hub->send($ok2);
    $hub->send($ok3);

    ok(!@events, "Blocked events");

    like(
        dies { $hub->filter('xxx') },
        qr/filter only takes coderefs for arguments, got 'xxx'/,
        "filter takes a coderef"
    );
};

tests todo_system => sub {
    my $hub = Test::Sync::Hub->new();

    {
        my $todo = $hub->set_todo('foo');
        ok($todo, "True");
        is($hub->get_todo, 'foo', "In todo");
    }

    is($hub->get_todo, undef, "Todo ended");

    my $todo = $hub->set_todo('foo');
    ok($todo, "True");
    is($hub->get_todo, 'foo', "In todo");
    $todo = undef;
    is($hub->get_todo, undef, "Todo ended");

    # Imitate Test::Builders todo:
    our $TODOX;
    {
        local $TODOX = $hub->set_todo('foo');
        ok($TODOX, "True");
        is($hub->get_todo, 'foo', "In todo");
    }
    is($hub->get_todo, undef, "Todo ended");

    like(
        warning { $hub->set_todo('xxx') },
        qr/set_todo\Q(...)\E called in void context, todo not set!/,
        "Need to capture the todo!"
    );

    like(
        warning { my $todo = $hub->set_todo() },
        qr/set_todo\(\) called with undefined argument, todo not set!/,
        "Todo cannot be undef"
    );
};

done_testing;
