package Test::Stream::Plugin::Is;
use strict;
use warnings;

use Test::Stream::Exporter;
default_exports qw/is is_deeply/;
no Test::Stream::Exporter;

use Scalar::Util qw/blessed/;

use Test::Stream::Compare qw/-all/;
use Test::Stream::Context qw/context/;
use Test::Stream::Util qw/rtype/;

use Test::Stream::Compare::Array;
use Test::Stream::Compare::Hash;
use Test::Stream::Compare::Scalar;
use Test::Stream::Compare::String;
use Test::Stream::Compare::Wildcard;

use Test::Stream::Plugin::Compare();

sub is($$;$@) {
    my ($got, $exp, $name, @diag) = @_;
    my $ctx = context();

    my @caller = caller;

    my $delta = compare($got, $exp, \&flat_convert);

    if ($delta) {
        $ctx->ok(0, $name, [$delta->table, @diag]);
    }
    else {
        $ctx->ok(1, $name);
    }

    $ctx->release;
    return !$delta;
}

sub is_deeply($$;$@) {
    my ($got, $exp, $name, @diag) = @_;
    my $ctx = context();

    my @caller = caller;

    my $delta = compare($got, $exp, \&Test::Stream::Plugin::Compare::strict_convert);

    if ($delta) {
        $ctx->ok(0, $name, [$delta->table, @diag]);
    }
    else {
        $ctx->ok(1, $name);
    }

    $ctx->release;
    return !$delta;
}

sub flat_convert {
    my ($thing) = @_;

    if ($thing && blessed($thing) && $thing->isa('Test::Stream::Compare')) {
        return $thing unless $thing->isa('Test::Stream::Compare::Wildcard');
        my $newthing = flat_convert($thing->expect);
        $newthing->set_builder($thing->builder) unless $newthing->builder;
        $newthing->set_file($thing->_file)      unless $newthing->_file;
        $newthing->set_lines($thing->_lines)    unless $newthing->_lines;
        return $newthing;
    }

    return Test::Stream::Compare::String->new(input => $thing);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::Is - Classing (Test::More) style is and is_deeply.

=head1 DESCRIPTION

This provides C<is()> and C<is_deeply()> functions that behave close to the way
they did in L<Test::More>, unlike the L<Test::Stream::Plugin::Compare> plugin
which has enhanced them (or ruined them, depending on who you ask).

=head1 SYNOPSIS

    use Test::Stream 'Is';

    is($got, $expect, "these are the same when stringified");

    is_deeply($got, $expect, "These structures are same when checked deeply");

=head1 EXPORTS

=over 4

=item $bool = is($got, $expect)

=item $bool = is($got, $expect, $name)

=item $bool = is($got, $expect, $name, @diag)

This does a string comparison of the 2 arguments. If the 2 arguments are the
same after stringification the test passes. The test will also pas sif both
arguments are undef.

The test C<$name> is optional.

The test C<@diag> is optional, it is extra diagnostics messages that will be
displayed if the test fails. The diagnostics are ignored if the test passes.

It is important to note that this tool considers C<"1"> and C<"1.0"> to not be
equal as it uses a string comparison.

See L<Test::Stream::Plugin::Compare> if you want a C<is()> function that tries
to be smarter for you.

=item $bool = is_deeply($got, $expect)

=item $bool = is_deeply($got, $expect, $name)

=item $bool = is_deeply($got, $expect, $name, @diag)

This does a deep check, it compares the structures in C<$got> with those in
C<$expect>. It will recurse into hashrefs, arrayrefs, and scalar refs. All
other values will be stringified and compared as strings. It is important to
note that this tool considers C<"1"> and C<"1.0"> to not be equal as it uses a
string comparison.

See L<Test::Stream::Plugin::Compare> if you want a C<is()> function that tries
to be smarter for you.

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

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
