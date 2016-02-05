package Test::Stream::Plugin::Warnings;
use strict;
use warnings;

use Carp qw/croak/;
use Test::Stream::Util qw/protect/;

use Test::Stream::Exporter qw/import default_exports/;
default_exports qw/warning warns no_warnings/;
no Test::Stream::Exporter;

sub warning(&) {
    my $warnings = &warns(@_) || [];
    if (@$warnings != 1) {
        warn $_ for @$warnings;
        croak "Got " . scalar(@$warnings) . " warnings, expected exactly 1"
    }
    return $warnings->[0];
}

sub no_warnings(&) {
    my $warnings = &warns(@_);
    return 1 unless defined $warnings;
    warn $_ for @$warnings;
    return 0;
}

sub warns(&) {
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings => @_;
    };
    &protect(@_);
    return undef unless @warnings;
    return \@warnings;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::Warnings - Simple tools for testing code that may
generate warnings.

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 SYNOPSIS

    # Load the Warnings plugin, and Core cause we need that as well.
    use Test::Stream qw/Core Warnings/;

    # Returns undef if there are no warnings.
    ok(!warns { ... }, "Codeblock did not warn");

    is_deeply(
        warns { warn "foo\n"; warn "bar\n" },
        [
            "foo\n",
            "bar\n",
        ],
        "Got expected warnings"
    );

    # Dies if there are 0 warnings, or 2+ warnings, otherwise returns the 1 warning.
    like( warning { warn 'xxx' }, qr/xxx/, "Got expected warning");

=head1 EXPORTS

=over 4

=item $warnings = warns { ... }

If the codeblock issues any warnings they will be captured and returned in an
arrayref. If there were no warnings this will return undef. You can be sure
this will always be undef, or an arrayref with 1 or more warnings.

    # Returns undef if there are no warnings.
    ok(!warns { ... }, "Codeblock did not warn");

    is_deeply(
        warns { warn "foo\n"; warn "bar\n" },
        [
            "foo\n",
            "bar\n",
        ],
        "Got expected warnings"
    );

=item $warning = warning { ... }

Only use this for code that should issue exactly 1 warning. This will throw an
exception if there are no warnings, or if there are multiple warnings.

    like( warning { warn 'xxx' }, qr/xxx/, "Got expected warning");

These both die:

    warning { warn 'xxx'; warn 'yyy' };
    warning { return };

=item $bool = no_warnings { ... }

This will return true if there are no warnings in the codeblock. This will
return false, and print the warnings if any are encountered.

    ok(no_warnings { ... }, "Did not warn.");

This is sometimes more useful that checking C<!warns { ... }> since it lets you
see the warnings when it fails.

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
