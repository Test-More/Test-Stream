use Test::Sync -V1, -Tester, 'Defer';

use Test::Sync::Hub::Subtest;

my $ran = 0;
my $event;

my $one = Test::Sync::Hub::Subtest->new(
    nested => 3,
);

isa_ok($one, 'Test::Sync::Hub::Subtest', 'Test::Sync::Hub');

{
    my $mock = mock 'Test::Sync::Hub' => (
        override => [
            process => sub { $ran++; (undef, $event) = @_; 'P!' },
        ],
    );

    my $ok = Test::Sync::Event::Ok->new(
        pass => 1,
        name => 'blah',
        debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']),
    );

    def is => ($one->process($ok), 'P!', "processed");
    def is => ($ran, 1, "ran the mocked process");
    def is => ($event, $ok, "got our event");
    def is => ($event->nested, 3, "nested was set");
    def is => ($one->bailed_out, undef, "did not bail");

    $ran = 0;
    $event = undef;

    my $bail = Test::Sync::Event::Bail->new(
        message => 'blah',
        debug => Test::Sync::DebugInfo->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']),
    );

    def is => ($one->process($bail), 'P!', "processed");
    def is => ($ran, 1, "ran the mocked process");
    def is => ($event, $bail, "got our event");
    def is => ($event->nested, 3, "nested was set");
    def is => ($one->bailed_out, $event, "bailed");
}

do_def;

$ran = 0;

TS_SUBTEST_WRAPPER: {
    $ran++;
    $one->terminate(100);
    $ran++;
}

is($ran, 1, "did not get past the terminate");

done_testing;
