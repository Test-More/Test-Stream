use Test::Stream '-V1', 'Compare' => ['-all'];

imported qw{
    describe cases
    tests it
    case
    before_each after_each around_each
    before_all  after_all  around_all
    before_case after_case around_case
};

my $depth = 3;

# Declare the structure
do_it($depth);

Test::Stream::Plugin::Spec->unimport;

ok(my $unit = Test::Stream::Workflow::Meta->get(__PACKAGE__)->unit, "got our unit");
isa_ok($unit, 'Test::Stream::Workflow::Unit');

# Compare the unit generated by so_it() with the structure we expect as
# produced by build_it().
is(
    $unit,
    object {
        prop blessed    => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
        call name       => 'main';                              # package name
        call start_line => 1000;
        call end_line   => 'EOF';
        call file       => 'example.t';
        call meta       => {};
        call modify     => undef;
        call buildup    => undef;
        call teardown   => undef;
        call post       => undef;
        call type       => 'group';
        call primary    => array { build_it($depth); end };
    },
    "Compiled structure is correct"
);

done_testing;


# Recursive function to created the nested structure that should be the end
# result of the compilation at the bottom.
sub build_it {
    my $count = shift;
    return undef unless $count--;

    item object {
        prop blessed    => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
        call name       => 'stuff';
        call start_line => 1005;
        call end_line   => 1026;
        call file       => 'example.t';
        call type       => 'group';
        call post       => undef;
        call modify     => undef;
        call meta       => {};
        call buildup => array {
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'first';
                call start_line => 1014;
                call end_line   => 1014;
            };
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'second';
                call start_line => 1015;
                call end_line   => 1015;
            };
            end;
        };
        call teardown => array {
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'pre_last';
                call type       => 'single';
                call buildup    => undef;
                call teardown   => undef;
                call modify     => undef;
                call post       => undef;
                call meta       => {};
                call start_line => 1016;
                call end_line   => 1016;
            };
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'last';
                call type       => 'single';
                call buildup    => undef;
                call teardown   => undef;
                call modify     => undef;
                call post       => undef;
                call meta       => {};
                call start_line => 1017;
                call end_line   => 1017;
            };
            end;
        };
        call primary => array {
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'vanilla';
                call name       => 'vanilla';
                call type       => 'single';
                call post       => undef;
                call meta       => {};
                call modify     => undef;
                call start_line => 1006;
                call end_line   => 1008;
                call buildup => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix1';
                            call name       => 'prefix1';
                            call type       => 'single';
                            call buildup    => undef;
                            call teardown   => undef;
                            call modify     => undef;
                            call post       => undef;
                            call meta       => {};
                            call start_line => 1019;
                            call end_line   => 1019;
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix2';
                            call name       => 'prefix2';
                            call type       => 'single';
                            call buildup    => undef;
                            call teardown   => undef;
                            call modify     => undef;
                            call post       => undef;
                            call meta       => {};
                            call start_line => 1020;
                            call end_line   => 1020;
                        };
                    }
                    end;
                };
                call teardown => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix1';
                            call name     => 'postfix1';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix2';
                            call name     => 'postfix2';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                    }
                    end;
                };
            };
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'skip';
                call name       => 'skip';
                call type       => 'single';
                call post       => undef;
                call meta       => {skip => 'will fail'};
                call modify     => undef;
                call start_line => 1010;
                call end_line   => 1010;
                call buildup => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix1';
                            call name     => 'prefix1';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix2';
                            call name     => 'prefix2';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                    }
                    end;
                };
                call teardown => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix1';
                            call name     => 'postfix1';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix2';
                            call name     => 'postfix2';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                    }
                    end;
                };
            };
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call name => 'todo';
                call type => 'single';
                call sub { $_[0]->primary->() } => 'todo';
                call post    => undef;
                call meta    => {todo => 'testing todo'};
                call modify  => undef;
                call buildup => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix1';
                            call name     => 'prefix1';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'prefix2';
                            call name     => 'prefix2';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                    }
                    end;
                };
                call teardown => array {
                    for (1 .. ($depth - $count)) {
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix1';
                            call name     => 'postfix1';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                        item object {
                            prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                            call sub { $_[0]->primary->() } => 'postfix2';
                            call name     => 'postfix2';
                            call type     => 'single';
                            call buildup  => undef;
                            call teardown => undef;
                            call modify   => undef;
                            call post     => undef;
                            call meta     => {};
                        };
                    }
                    end;
                };
            };

            # Recurse to nest it several times to make sure inheritence is sane.
            build_it($count);
            end;
        };
    };

    item object {
        prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
        call name       => 'more_stuff';
        call start_line => 1028;
        call end_line   => 1033;
        call meta       => {};
        call buildup    => undef;
        call teardown   => undef;
        call post       => undef;
        call modify   => array {
            item object {
                call sub { $_[0]->primary->() } => 'a';
            };
            item object {
                call sub { $_[0]->primary->() } => 'b';
            };
            item object {
                call sub { $_[0]->primary->() } => 'c';
            };
            end;
        };
        call primary => array {
            item object {
                prop blessed => check('isa' => 'Test::Stream::Workflow::Unit', sub { $_[0]->isa($_[2]) });
                call sub { $_[0]->primary->() } => 'the tests';
                call name   => 'the_tests';
                call post   => undef;
                call modify => undef;
            };
            end;
        };
    };
}

# This is a recursive function that declares a nested structure.
# This is down here so that line numbers are predictable, and non-conflicting
# line 1000 "example.t"
use Test::Stream::Plugin::Spec;
sub do_it {                                                     #line 1001
    my $count = shift;                                          #line 1002
    return unless $count--;                                     #line 1003

    describe stuff => sub {                                     #line 1005
        tests vanilla => sub {                                  #line 1006
            'vanilla'                                           #line 1007
        };                                                      #line 1008

        tests skip => {skip => 'will fail'}, sub { 'skip' };    #line 1010

        tests todo => {todo => 'testing todo'}, sub { 'todo' }; #line 1012

        before_all first   => sub { 'first' };                  #line 1014
        before_all second  => sub { 'second' };                 #line 1015
        after_all pre_last => sub { 'pre_last' };               #line 1016
        after_all last     => sub { 'last' };                   #line 1017

        before_each prefix1 => sub { 'prefix1' };               #line 1019
        before_each prefix2 => sub { 'prefix2' };               #line 1020

        after_each postfix1 => sub { 'postfix1' };              #line 1022
        after_each postfix2 => sub { 'postfix2' };              #line 1023
        # Recurse to nest it several times to make sure inheritence is sane.
        do_it($count);                                          #line 1025
    };                                                          #line 1026

    cases more_stuff => {}, sub {                               #line 1028
        tests the_tests => sub { 'the tests' };                 #line 1029
        case a          => sub { 'a' };                         #line 1020
        case b          => sub { 'b' };                         #line 1031
        case c          => sub { 'c' };                         #line 1032
    };                                                          #line 1033
}
