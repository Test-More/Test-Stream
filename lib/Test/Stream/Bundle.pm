package Test::Stream::Bundle;
use strict;
use warnings;

use Carp qw/croak/;

use Test::Stream::Exporter qw/import default_export/;

# Here we are exporting a sub called 'import' that is not our 'import' method.
default_export import => sub {
    my $class = shift;
    my @caller = caller;

    my $bundle = $class;
    $bundle =~ s/^Test::Stream::Bundle::/-/;

    require Test::Stream;
    Test::Stream->load(\@caller, $bundle, @_);
};

no Test::Stream::Exporter;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Bundle - Tools to help you write custom bundles.

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

You can reduce your boilerplate by writing your own Test::Stream bundles. A
bundle is a set of plugins that get loaded all at once to your specifications.

=head1 SYNOPSIS

    package Test::Stream::Bundle::MyBundle;
    use strict;
    use warnings;

    # Gives us an 'import' method that allows this module to be used directly
    # if desired.
    use Test::Stream::Bundle qw/import/;

    sub plugins {
        return (
            qw{
                IPC
                TAP
                ExitSummary
                Core
                Context
                Exception
                Warnings
                Compare
                Mock
            },
        );
    }

=head1 EXPORTS

=over 4

=item $class->import()

This C<import()> method gets called when your plugin isused directly
C<use Test::Stream::Bundle::MyBundle>. Doing so will load all the specified
plugins.

=back

=head1 EXPECTED METHODS

=over 4

=item @list = $class->plugins()

The C<plugins()> method should return a list of plugins to load. It can also
return coderefs which will be run with the original caller arrayref as their
only argument.

    sub plugins {
        return (
            qw/Core TAP .../,
            sub {
                my $caller = shift;

                # Package, file, and line that requested the bundle be used.
                my ($pkg, $file, $line) = @$caller;

                ...
            },
        );
    }

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
