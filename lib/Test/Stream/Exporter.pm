package Test::Stream::Exporter;
use strict;
use warnings;

use Test::Stream::PackageUtil;
use Test::Stream::Exporter::Meta;

sub export;
sub exports;
sub default_export;
sub default_exports;

# Test::Stream::Carp uses this module.
sub croak   { require Carp; goto &Carp::croak }
sub confess { require Carp; goto &Carp::confess }

BEGIN { Test::Stream::Exporter::Meta->new(__PACKAGE__) };

sub import {
    my $class = shift;
    my $caller = caller;

    Test::Stream::Exporter::Meta->new($caller);

    export_to($class, $caller, @_);
}

default_exports qw/export exports default_export default_exports/;
exports         qw/export_to export_meta/;

default_export import => sub {
    my $class = shift;
    my $caller = caller;
    my @args = @_;

    my $stash = $class->can('before_import') ? $class->before_import($caller, \@args) : undef;;
    export_to($class, $caller, @args);
    $class->after_import($caller, $stash, @args) if $class->can('after_import');
};

sub export_meta {
    my $pkg = shift || caller;
    return Test::Stream::Exporter::Meta->get($pkg);
}

sub export_to {
    my $class = shift;
    my ($dest, @imports) = @_;

    my $meta = Test::Stream::Exporter::Meta->new($class);

    my (@include, %exclude);
    for my $import (@imports) {
        if (substr($import, 0, 1) eq '!') {
            $import =~ s/^!//g;
            $exclude{$import}++;
        }
        else {
            push @include => $import;
        }
    }

    @include = $meta->default unless @include;

    my $exports = $meta->exports;
    for my $name (@include) {
        next if $exclude{$name};

        my $ref = $exports->{$name}
            || croak qq{"$name" is not exported by the $class module};

        no strict 'refs';
        $name =~ s/^[\$\@\%\&]//;
        *{"$dest\::$name"} = $ref;
    }
}

sub cleanup {
    my $pkg = caller;
    package_purge_sym($pkg, map {(CODE => $_)} qw/export exports default_export default_exports/);
}

sub export {
    my ($name, $ref) = @_;
    my $caller = caller;

    my $meta = export_meta($caller) ||
        confess "$caller is not an exporter!?";

    $meta->add($name, $ref);
}

sub exports {
    my $caller = caller;

    my $meta = export_meta($caller) ||
        confess "$caller is not an exporter!?";

    $meta->add_bulk(@_);
}

sub default_export {
    my ($name, $ref) = @_;
    my $caller = caller;

    my $meta = export_meta($caller) ||
        confess "$caller is not an exporter!?";

    $meta->add_default($name, $ref);
}

sub default_exports {
    my $caller = caller;

    my $meta = export_meta($caller) ||
        confess "$caller is not an exporter!?";

    $meta->add_default_bulk(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Exporter - Declarative exporter for Test::Stream and friends.

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 DESCRIPTION

Test::Stream::Exporter is an internal implementation of some key features from
L<Exporter::Declare>. This is a much more powerful exporting tool than
L<Exporter>. This package is used to easily manage complicated EXPORT logic
across L<Test::Stream> and friends.

=head1 SYNOPSIS

    use Test::Stream::Exporter;

    # Export some named subs from the package
    default_exports qw/foo bar baz/;
    exports qw/fluxx buxx suxx/;

    # Export some anonymous subs under specific names.
    export         some_tool    => sub { ... };
    default_export another_tool => sub { ... };

    # Call this when you are done providing exports in order to cleanup your
    # namespace.
    Test::Stream::Exporter->cleanup;

    # Hooks for import()

    # Called before importing symbols listed in $args_ref. This gives you a
    # chance to munge the arguments.
    sub before_import {
        my $class = shift;
        my ($caller, $args_ref) = @_;
        ...

        return $stash; # For use in after_import, can be anything
    }

    # Chance to do something after import() is done
    sub after_import {
        my $class = shift;
        my ($caller, $stash, @args) = @_;
        ...
    }

=head1 EXPORTS

=head2 DEFAULT

=over 4

=item import

Your class needs this to function as an exporter.

=item export NAME => sub { ... }

=item default_export NAME => sub { ... }

These are used to define exports that may not actually be subs in the current
package.

=item exports qw/foo bar baz/

=item default_exports qw/foo bar baz/

These let you export package subs en mass.

=back

=head2 AVAILABLE

=over 4

=item export_to($from, $dest, @symbols)

=item $from->export_to($dest, @symbols)

Export from the C<$from> package into the C<$dest> package. The class-method
form only works if the method has been imported into the C<$from> package.

=item $meta = export_meta($package)

=item $meta = $package->export_meta()

Get the export meta object from the package. The class method form only works
if the package has imported it.

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
