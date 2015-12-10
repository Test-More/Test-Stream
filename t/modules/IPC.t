use strict;
use warnings;

use Test::Sync::IPC;

my @drivers;
BEGIN { @drivers = Test::Sync::IPC->drivers };

use Test::Sync::Tester;
use Test::Sync::Context qw/context/;
use Test::Sync::Subtest qw/subtest/;
sub tests {
    my ($name, $code) = @_;
    my $ctx = context();
    subtest($name, $code, 1);
    $ctx->release;
}

is_deeply(
    \@drivers,
    ['Test::Sync::IPC::Files'],
    "Got default driver"
);

require Test::Sync::IPC::Files;
Test::Sync::IPC::Files->import();
Test::Sync::IPC::Files->import();
Test::Sync::IPC::Files->import();

Test::Sync::IPC->register_drivers(
    'Test::Sync::IPC::Files',
    'Test::Sync::IPC::Files',
    'Test::Sync::IPC::Files',
);

is_deeply(
    [Test::Sync::IPC->drivers],
    ['Test::Sync::IPC::Files'],
    "Driver not added multiple times"
);

tests init_drivers => sub {
    ok( !exception { Test::Sync::IPC->new }, "Found working driver" );

    no warnings 'redefine';
    local *Test::Sync::IPC::Files::is_viable = sub { 0 };
    use warnings;

    like(
        exception { Test::Sync::IPC->new },
        qr/Could not find a viable IPC driver! Aborting/,
        "No viable drivers"
    );

    no warnings 'redefine';
    local *Test::Sync::IPC::Files::is_viable = sub { undef };
    use warnings;
    like(
        exception { Test::Sync::IPC->new },
        qr/Could not find a viable IPC driver! Aborting/,
        "No viable drivers"
    );
};

tests polling => sub {
    ok(!Test::Sync::IPC->polling_enabled, "no polling yet");
    ok(!@Test::Sync::Context::ON_INIT, "no context init hooks yet");

    Test::Sync::IPC->enable_polling;

    ok(1 == @Test::Sync::Context::ON_INIT, "added 1 hook");
    ok(Test::Sync::IPC->polling_enabled, "polling enabled");

    Test::Sync::IPC->enable_polling;

    ok(1 == @Test::Sync::Context::ON_INIT, "Did not add hook twice");
};

for my $meth (qw/send cull add_hub drop_hub waiting is_viable/) {
    my $one = Test::Sync::IPC->new;
    like(
        exception { $one->$meth },
        qr/'\Q$one\E' did not define the required method '$meth'/,
        "Require override of method $meth"
    );
}

tests abort => sub {
    my $one = Test::Sync::IPC->new(no_fatal => 1);
    my ($err, $out) = ("", "");

    {
        local *STDERR;
        local *STDOUT;
        open(STDERR, '>', \$err);
        open(STDOUT, '>', \$out);
        $one->abort('foo');
    }

    is($err, "IPC Fatal Error: foo\n", "Got error");
    is($out, "not ok - IPC Fatal Error\n", "got 'not ok' on stdout");

    ($err, $out) = ("", "");

    {
        local *STDERR;
        local *STDOUT;
        open(STDERR, '>', \$err);
        open(STDOUT, '>', \$out);
        $one->abort_trace('foo');
    }

    is($out, "not ok - IPC Fatal Error\n", "got 'not ok' on stdout");
    like($err, qr/IPC Fatal Error: foo/, "Got error");
};

done_testing;
