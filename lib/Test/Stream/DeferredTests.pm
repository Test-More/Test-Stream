package Test::Stream::DeferredTests;
use strict;
use warnings;

use Carp qw/croak/;
use Test::Stream::Util qw/get_tid/;

use Test::Stream::Exporter qw/import default_exports/;
default_exports qw/def do_def/;
no Test::Stream::Exporter;

my %TODO;

sub def {
    my ($func, @args) = @_;

    my @caller = caller(0);

    $TODO{$caller[0]} ||= [];
    push @{$TODO{$caller[0]}} => [$func, \@args, \@caller];
}

sub do_def {
    my $for = caller;
    my $tests = delete $TODO{$for} or croak "No tests to run!";

    for my $test (@$tests) {
        my ($func, $args, $caller) = @$test;

        my ($pkg, $file, $line) = @$caller;

# Note: The '&' below is to bypass the prototype, which is important here.
        eval <<"        EOT" or die $@;
package $pkg;
# line $line "(eval in DeferredTests) $file"
\&$func(\@\$args);
1;
        EOT
    }
}

sub _verify {
    return if Test::Stream::Sync->pid != $$;
    return if Test::Stream::Sync->tid != get_tid();
    my $not_ok = 0;
    for my $pkg (keys %TODO) {
        delete $TODO{$pkg};
        print STDOUT "not ok - deferred tests were not run!\n" unless $not_ok++;
        print STDERR "# '$pkg' has deferred tests that were never run!\n";
        $? ||= 255;
    }
}

END { _verify() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::DeferredTests - Write tests that get executaed at a later time

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

Sometimes you need to test things BEFORE loading L<Test::Stream>. This module
lets you do that. You can write tests, and then have them run later, after
Test::Stream is loaded. You tell it what test function to run, and what
arguments to give it. The function name and arguments will be stored to be
executed later. When ready run C<do_def()> to kick them off once the functions
are defined.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Test::Stream::DeferredTests;

    BEGIN {
        def ok => (1, 'pass');
        def is => ('foo', 'foo', 'runs is');
        ...
    }

    use Test::Stream qw/Core/;

    do_def(); # Run the tests

    # Declare some more tests to run later:
    def ok => (1, "another pass");
    ...

    do_def(); # run the new tests

    done_testing;

=head1 EXPORTS

=over 4

=item def function => @args;

This will store the function name, and the arguments to be run later. Note that
each package has a separate store of tests to run.

=item do_def()

This will run all the stored tests. It will also reset the list to be empty so
you can add more tests to run even later.

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

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
