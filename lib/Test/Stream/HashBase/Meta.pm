package Test::Stream::HashBase::Meta;
use strict;
use warnings;

use Test::Stream::Carp qw/confess/;

my %META;

sub PACKAGE() { 'package' }
sub FIELDS()  { 'fields'  }

sub package { $_[0]->{+PACKAGE} }
sub fields  { $_[0]->{+FIELDS}  }

sub get { $META{$_[-1]} }

sub new {
    my ($class, $pkg) = @_;
    $META{$pkg} ||= bless {
        PACKAGE() => $pkg,
        FIELDS()  => {},
    }, $class;
    return $META{$pkg};
}

sub add_accessors {
    my $self = shift;

    my $package = $self->{+PACKAGE};

    my $fields = $self->{+FIELDS};
    for my $name (@_) {
        confess "field '$name' already defined!"
            if $fields->{$name};

        my $const = uc $name;

        # Assign the constant to the fields hashref
        $fields->{$name} = eval <<"        EOT" || confess $@;
            package $package;
            sub $const    { '$name' }
            sub $name     { \$_[0]->{'$name'} };
            sub set_$name { \$_[0]->{'$name'} = \$_[1] };
            \\&$const;
        EOT
    }
}

sub subclass {
    my ($self, $base) = @_;

    my $package = $self->{+PACKAGE};
    my $fields  = $self->{+FIELDS};
    my $basef   = $base->{+FIELDS};

    for my $field (keys %$basef) {
        my $const = uc($field);
        $fields->{$field} = $basef->{$field};
        no strict 'refs';
        *{"$package\::$const"} = $fields->{$field};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::HashBase::Meta - Meta Object for HashBase objects.

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 SYNOPSIS

B<Note:> You probably do not want to directly use this object.

    my $meta = Test::Stream::HashBase::Meta->new('Some::Class');
    $meta->add_accessors('foo');

=head1 DESCRIPTION

This is the meta-object used by L<Test::Stream::HashBase>

=head1 FUNCTIONS

=over 4

=item $meta = Test::Stream::HashBase::Meta::get($package)

Get the meta object for the specified package. Returns C<undef> if there is
none initiated.

=back

=head1 METHODS

=over 4

=item $meta = $class->new($package)

Create a new meta object for the specified class. If one already exists that
instance is returned.

=item $package = $meta->package

Get the package the meta-object manages.

=item $hr = $meta->fields

This returns a hashref where each key is the name of a field in the package,
and each key is the constant sub that returns the field name.

=item $meta->export_constants($package)

Export all the constants defined by this meta-object into the specified
package.

=item $meta->add_accessors(@names)

Add accessors to the package. Also defines the C<"set_$NAME"> method, and the
C<uc($NAME)> constant for each accessor.

=item $meta->subclass($base_meta)

Add the constants from the base meta to the instance meta. This will also put
the constants into the instance meta's package.

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
