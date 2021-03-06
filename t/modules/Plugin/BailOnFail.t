use Test::Stream qw/-V1 -Tester BailOnFail/;

like(
    intercept {
        ok(1, "pass");
        ok(0, "fail");
        ok(1, "Should not see");
    },
    array {
        event Ok => { name => "pass", pass => 1 };
        event Ok => { name => "fail", pass => 0 };
        event Bail => { reason => "(Bail On Fail)" };
        end;
    },
    "Bailed after the failure"
);

sub mok {
    my ($ok, $name) = @_;
    my $ctx = context();
    ok($ok, $name);
    diag "Should see this after failure";
    $ctx->release;
    return $ok;
}

like(
    intercept {
        ok(1, "pass");
        mok(0, "fail");
        ok(1, "Should not see");
    },
    array {
        event Ok => { name => "pass", pass => 1 };
        event Ok => { name => "fail", pass => 0 };
        event Diag => { message => "Should see this after failure" };
        event Bail => { reason => "(Bail On Fail)" };
        end;
    },
    "Tool had time to output the diag"
);

done_testing;
