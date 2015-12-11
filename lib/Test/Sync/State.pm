package Test::Sync::State;
use strict;
use warnings;

use Carp qw/confess/;

use Test::Sync::HashBase(
    accessors => [qw{count failed ended bailed_out _passing _plan skip_reason}],
);

sub init {
    my $self = shift;

    $self->{+COUNT}    = 0 unless defined $self->{+COUNT};
    $self->{+FAILED}   = 0 unless defined $self->{+FAILED};
    $self->{+_PASSING} = 1 unless defined $self->{+_PASSING};
}

sub is_passing {
    my $self = shift;

    ($self->{+_PASSING}) = @_ if @_;

    # If we already failed just return 0.
    my $pass = $self->{+_PASSING} || return 0;
    return $self->{+_PASSING} = 0 if $self->{+FAILED};

    my $count = $self->{+COUNT};
    my $ended = $self->{+ENDED};
    my $plan = $self->{+_PLAN};

    return $pass if !$count && $plan && $plan =~ m/^SKIP$/;

    return $self->{+_PASSING} = 0
        if $ended && (!$count || !$plan);

    return $pass unless $plan && $plan =~ m/^\d+$/;

    if ($ended) {
        return $self->{+_PASSING} = 0 if $count != $plan;
    }
    else {
        return $self->{+_PASSING} = 0 if $count > $plan;
    }

    return $pass;
}

sub bump {
    my $self = shift;
    my ($pass) = @_;

    confess "Cannot change test count after test has ended"
        if $self->{+ENDED};

    $self->{+COUNT}++;
    return if $pass;

    $self->{+FAILED}++;
    $self->{+_PASSING} = 0;
}

sub bump_fail {
    my $self = shift;
    $self->{+FAILED}++;
    $self->{+_PASSING} = 0;
}

sub plan {
    my $self = shift;

    return $self->{+_PLAN} unless @_;

    my ($plan) = @_;

    confess "You cannot unset the plan"
        unless defined $plan;

    confess "You cannot change the plan"
        if $self->{+_PLAN} && $self->{+_PLAN} !~ m/^NO PLAN$/;

    confess "'$plan' is not a valid plan! Plan must be an integer greater than 0, 'NO PLAN', or 'SKIP'"
        unless $plan =~ m/^(\d+|NO PLAN|SKIP)$/;

    $self->{+_PLAN} = $plan;
}

sub finish {
    my $self = shift;
    my ($frame) = @_;

    if($self->{+ENDED}) {
        my (undef, $ffile, $fline) = @{$self->{+ENDED}};
        my (undef, $sfile, $sline) = @$frame;

        die <<"        EOT"
Test already ended!
First End:  $ffile line $fline
Second End: $sfile line $sline
        EOT
    }

    $self->{+ENDED} = $frame;
    $self->is_passing(); # Generate the final boolean.
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::State - Representation of the state of the testing

=head1 METHODS

=over 4

=item $num = $state->count

Get the number of tests that have been run.

=item $num = $state->failed

Get the number of failures (Not all failures come from a test fail, so this
number can be larger than the count).

=item $bool = $state->ended

True if the state has ended. This MAY return the stack frame of the tool that
ended the test, but that is not guarenteed.

=item $bool = $state->is_passing

=item $state->is_passing($bool)

Check if the overall state is a failure. Can also be used to set the pass/fail
status.

=item $state->bump($bool)

Increase the test count by one, C<$bool> should be true if the new test passed,
false if it failed.

=item $state->bump_fail

Increase the failure count, and set is_passing to false.

=item $state->plan($plan)

=item $plan = $state->plan

Get or set the plan. The plan must be an integer larger than 0, the string
'no_plan', or the string 'skip_all'.

=item $state->finish([$package, $file, $line])

This is used to finalize the state, no changes should be made to the state
after this is set.

=back

=head1 SOURCE

The source code repository for Test::Sync can be found at
F<http://github.com/Test-More/Test-Sync/>.

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

See F<http://dev.perl.org/licenses/>

=cut
