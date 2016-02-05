package Test::Stream::Event::Plan;
use strict;
use warnings;

use base 'Test::Stream::Event';
use Test::Stream::HashBase accessors => [qw/max directive reason/];

use Test::Stream::Formatter::TAP qw/OUT_STD/;
use Carp qw/confess/;

my %ALLOWED = (
    'SKIP'    => 1,
    'NO PLAN' => 1,
);

sub init {
    $_[0]->SUPER::init();

    if ($_[0]->{+DIRECTIVE}) {
        $_[0]->{+DIRECTIVE} = 'SKIP'    if $_[0]->{+DIRECTIVE} eq 'skip_all';
        $_[0]->{+DIRECTIVE} = 'NO PLAN' if $_[0]->{+DIRECTIVE} eq 'no_plan';

        confess "'" . $_[0]->{+DIRECTIVE} . "' is not a valid plan directive"
            unless $ALLOWED{$_[0]->{+DIRECTIVE}};
    }
    else {
        confess "Cannot have a reason without a directive!"
            if defined $_[0]->{+REASON};

        confess "No number of tests specified"
            unless defined $_[0]->{+MAX};

        confess "Plan test count '" . $_[0]->{+MAX}  . "' does not appear to be a valid positive integer"
            unless $_[0]->{+MAX} =~ m/^\d+$/;

        $_[0]->{+DIRECTIVE} = '';
    }
}

sub to_tap {
    my $self = shift;

    my $max       = $self->{+MAX};
    my $directive = $self->{+DIRECTIVE};
    my $reason    = $self->{+REASON};

    return if $directive && $directive eq 'NO PLAN';

    my $plan = "1..$max";
    if ($directive) {
        $plan .= " # $directive";
        $plan .= " $reason" if defined $reason;
    }

    return [OUT_STD, "$plan\n"];
}

sub update_state {
    my $self = shift;
    my ($state) = @_;

    $state->plan($self->{+DIRECTIVE} || $self->{+MAX});
    $state->set_skip_reason($self->{+REASON});
}

sub terminate {
    my $self = shift;
    # On skip_all we want to terminate the hub
    return 0 if $self->{+DIRECTIVE} && $self->{+DIRECTIVE} eq 'SKIP';
    return undef;
}

sub global {
    my $self = shift;
    return 0 unless $self->{+DIRECTIVE};
    return 0 unless $self->{+DIRECTIVE} eq 'SKIP';
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Plan - The event of a plan

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

Plan events are fired off whenever a plan is declared, done testing is called,
or a subtext completes.

=head1 SYNOPSIS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Plan;

    my $ctx = context();

    # Plan for 10 tests to run
    my $event = $ctx->plan(10);

    # Plan to skip all tests (will exit 0)
    $ctx->plan(0, skip_all => "These tests need to be skipped");

=head1 ACCESSORS

=over 4

=item $num = $plan->max

Get the number of expected tests

=item $dir = $plan->directive

Get the directive (such as TODO, skip_all, or no_plan).

=item $reason = $plan->reason

Get the reason for the directive.

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
