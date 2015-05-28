use Test::Stream;
use Test::Stream::Subtest qw/subtest_streamed subtest_buffered/;
use Test::Stream::Tester;

events_are(
    intercept {
        subtest_streamed 'foo' => sub {
            subtest_buffered 'bar' => sub {
                ok(1, "pass");
            };
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Subtest => sub {
                    event_field pass => 1;
                    event_field name => 'Subtest: bar';
                    event_field subevents => events {
                        event Ok => sub {
                            event_field name => 'pass';
                            event_field pass => 1;
                        };
                    };
                };
            };
        };
    },
    "Can nest subtests"
);

my @lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 4;
        subtest_streamed 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
            };
        };
    },
    "Got events for passing subtest"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 4;
        subtest_streamed 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(0, "fail");
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 0;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'fail';
                    event_field pass => 0;
                };
            };
        };
    },
    "Got events for failing subtest"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_streamed 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(1, "pass");
            done_testing;
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
                event Plan => { max => 1 };
                end_events;
            };
        };
    },
    "Can use done_testing"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_streamed 'foo' => sub {
            plan 1;
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Plan => { max => 1 };
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
                end_events;
            };
        };
    },
    "Can plan"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_streamed 'foo' => sub {
            skip_all 'bleh';
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Plan => { directive => 'SKIP', reason => 'bleh' };
                end_events;
            };
        };
    },
    "Can skip_all"
);

@lines = ();
events_are(
    intercept {
        subtest_streamed 'foo' => sub {
            BAIL_OUT 'cause';
            ok(1, "should not see this");
        };
    },
    events {
        event Note => { message => 'Subtest: foo' };
        event Bail => { reason => 'cause' };
        end_events;
    },
    "Can bail out"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 4;
        subtest_buffered 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
            };
        };
    },
    "Got events for passing subtest"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 4;
        subtest_buffered 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(0, "fail");
        };
    },
    events {
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 0;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'fail';
                    event_field pass => 0;
                };
            };
        };
    },
    "Got events for failing subtest"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_buffered 'foo' => sub {
            push @lines => __LINE__ + 1;
            ok(1, "pass");
            done_testing;
        };
    },
    events {
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
                event Plan => { max => 1 };
                end_events;
            };
        };
    },
    "Can use done_testing"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_buffered 'foo' => sub {
            plan 1;
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Plan => { max => 1 };
                event Ok => sub {
                    event_file __FILE__;
                    event_line $lines[1];
                    event_field name => 'pass';
                    event_field pass => 1;
                };
                end_events;
            };
        };
    },
    "Can plan"
);

@lines = ();
events_are(
    intercept {
        push @lines => __LINE__ + 5;
        subtest_buffered 'foo' => sub {
            skip_all 'bleh';
            push @lines => __LINE__ + 1;
            ok(1, "pass");
        };
    },
    events {
        event Subtest => sub {
            event_file __FILE__;
            event_line $lines[0];
            event_field pass => 1;
            event_field name => 'Subtest: foo';
            event_field subevents => events {
                event Plan => { directive => 'SKIP', reason => 'bleh' };
                end_events;
            };
        };
    },
    "Can skip_all"
);

@lines = ();
events_are(
    intercept {
        subtest_buffered 'foo' => sub {
            BAIL_OUT 'cause';
            ok(1, "should not see this");
        };
    },
    events {
        event Bail => { reason => 'cause' };
        end_events;
    },
    "Can bail out"
);

done_testing;
