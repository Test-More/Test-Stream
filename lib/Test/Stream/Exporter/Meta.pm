package Test::Stream::Exporter::Meta;
use strict;
use warnings;

use Test::Stream::PackageUtil;

# Test::Stream::Carp uses this module.
sub croak   { require Carp; goto &Carp::croak }
sub confess { require Carp; goto &Carp::confess }

sub exports { $_[0]->{exports} }
sub default { @{$_[0]->{pdlist}} }
sub all     { @{$_[0]->{polist}} }

sub add {
    my $self = shift;
    my ($name, $ref) = @_;

    confess "Name is mandatory" unless $name;

    confess "$name is already exported"
        if $self->exports->{$name};

    $ref ||= package_sym($self->{package}, $name);

    confess "No reference or package sub found for '$name' in '$self->{package}'"
        unless $ref && ref $ref;

    $self->exports->{$name} = $ref;
    push @{$self->{polist}} => $name;
}

sub add_default {
    my $self = shift;
    my ($name, $ref) = @_;

    $self->add($name, $ref);
    push @{$self->{pdlist}} => $name;

    $self->{default}->{$name} = 1;
}

sub add_bulk {
    my $self = shift;
    for my $name (@_) {
        confess "$name is already exported"
            if $self->exports->{$name};

        my $ref = package_sym($self->{package}, $name)
            || confess "No reference or package sub found for '$name' in '$self->{package}'";

        $self->{exports}->{$name} = $ref;
    }

    push @{$self->{polist}} => @_;
}

sub add_default_bulk {
    my $self = shift;

    for my $name (@_) {
        confess "$name is already exported by $self->{package}"
            if $self->exports->{$name};

        my $ref = package_sym($self->{package}, $name)
            || confess "No reference or package sub found for '$name' in '$self->{package}'";

        $self->{exports}->{$name} = $ref;
        $self->{default}->{$name} = 1;
    }

    push @{$self->{polist}} => @_;
    push @{$self->{pdlist}} => @_;
}

my %EXPORT_META;

sub new {
    my $class = shift;
    my ($pkg) = @_;

    confess "Package is required!"
        unless $pkg;

    unless($EXPORT_META{$pkg}) {
        # Grab anything set in @EXPORT or @EXPORT_OK
        my (@pdlist, @polist);
        {
            no strict 'refs';
            @pdlist = @{"$pkg\::EXPORT"};
            @polist = @{"$pkg\::EXPORT_OK"};

            @{"$pkg\::EXPORT"}    = ();
            @{"$pkg\::EXPORT_OK"} = ();
        }

        my $meta = bless({
            exports => {},
            default => {},
            pdlist  => do { no strict 'refs'; no warnings 'once'; \@{"$pkg\::EXPORT"} },
            polist  => do { no strict 'refs'; no warnings 'once'; \@{"$pkg\::EXPORT_OK"} },
            package => $pkg,
        }, $class);

        $meta->add_default_bulk(@pdlist);
        my %seen = map {$_ => 1} @pdlist;
        $meta->add_bulk(grep {!$seen{$_}++} @polist);

        $EXPORT_META{$pkg} = $meta;
    }

    return $EXPORT_META{$pkg};
}

sub get {
    my $class = shift;
    my ($pkg) = @_;

    confess "Package is required!"
        unless $pkg;

    return $EXPORT_META{$pkg};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Exporter::Meta - Meta object for exporters.

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

L<Test::Stream::Exporter> uses this package to manage exports.

Every package that uses C<Test::Stream::Exporter> has a
C<Test::Stream::Exporter::Meta> object created for it which contains the
metadata about the available exports and the kind of export they are.

=head1 METHODS

=over 4

=item Test::Stream::Exporter::Meta->new( $PACKAGE )

Constructs a C<metaobject> for C<$PACKAGE> and returns it. If one already
exists, it is returned.

=item Test::Stream::Exporter::Meta->get( $PACKAGE )

Returns a C<metaobject> for C<$PACKAGE> if one exists. Returns C<undef> if one
does not exist.

=item metaobject->add( $SUBNAME )

=item metaobject->add( $SUBNAME => $SUBREF )

Declares an optional export called C<$SUBNAME>. If C<$SUBREF> is not specified,
then the exported subroutine is automatically retrieved from the C<$PACKAGE>
associated with the C<metaobject> of the same C<sub> name.

=item metaobject->add_default( $SUBNAME )

=item metaobject->add_default( $SUBNAME => $SUBREF )

Declares a default export called C<$SUBNAME>. Semantics otherwise identical to
C<< metaobject->add >>

=item metaobject->add_bulk( $SUBNAME, $SUBNAME, ... )

Declare a list of optional exports that are all available as package
subroutines by the same name.

=item metaobject->add_default_bulk( $SUBNAME, $SUBNAME, ... )

Declare a list of default exports that are all available as package subroutines
by the same name.

=item metaobject->default()

Returns the list of C<$SUBNAME> values that represent symbols that are exported
by this exporter which will be exported by default.

=item metaobject->all()

Returns the list of all C<$SUBNAME> values that represent symbols that are
exported by this exporter.

=item metaobject->exports()

Returns a C<HASHREF> of C<< $SUBNAME => $CODEREF >> values of all avialable
exports.

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

=item Kent Fredric E<lt>kentnl@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
