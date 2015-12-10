use Test::Sync -V1;

use Test::Sync::Table qw/table/;

use Test::Sync::Capabilities qw/CAN_FORK CAN_REALLY_FORK CAN_THREAD/;

diag "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
diag(join "\n", table(rows => [[ 'perl', $] ]]));

diag(
    join "\n",
    table(
        header => [qw/CAPABILITY SUPPORTED/],
        rows   => [
            ['CAN_FORK',        CAN_FORK        ? 'Yes' : 'No'],
            ['CAN_REALLY_FORK', CAN_REALLY_FORK ? 'Yes' : 'No'],
            ['CAN_THREAD',      CAN_THREAD      ? 'Yes' : 'No'],
        ],
    )
);

{
    my @depends = qw{
        B Carp File::Spec File::Temp List::Util PerlIO
        Scalar::Util Storable Test::Harness overload utf8
    };

    my @rows;
    for my $mod (sort @depends) {
        my $installed = eval "require $mod; $mod->VERSION";
        push @rows => [ $mod, $installed || "N/A" ];
    }

    my @table = table(
        header => [ 'DEPENDENCY', 'VERSION' ],
        rows => \@rows,
    );

    diag(join "\n", @table);
}

{
    my @options = qw{
        Sub::Name Sub::Util Term::ReadKey Unicode::GCString Unicode::LineBreak
        Trace::Mask
    };

    my @rows;
    for my $mod (sort @options) {
        my $installed = eval "require $mod; $mod->VERSION";
        push @rows => [ $mod, $installed || "N/A" ];
    }

    my @table = table(
        header => [ 'OPTIONAL', 'VERSION' ],
        rows => \@rows,
    );

    diag(join "\n", @table);
}

pass;
done_testing;
