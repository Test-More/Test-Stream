package Test::Stream::HashBase::Meta;
use strict;
use warnings;

use Test::Stream::Carp qw/confess/;

my %META;

sub package { shift->{package} }
sub parent  { shift->{parent} }
sub locked  { shift->{locked} }
sub fields  { ({%{shift->{fields}}}) }
sub order   { [@{shift->{order}}] }

sub new {
    my $class = shift;
    my ($pkg) = @_;

    $META{$pkg} ||= bless {
        package => $pkg,
        locked  => 0,
    }, $class;

    return $META{$pkg};
}

sub get {
    my $class = shift;
    my ($pkg) = @_;

    return $META{$pkg};
}

sub baseclass {
    my $self = shift;
    $self->{parent} = 'Test::Stream::HashBase';
    $self->{fields} = {};
    $self->{order}  = [];
}

sub subclass {
    my $self = shift;
    my ($parent) = @_;
    confess "Already a subclass of $self->{parent}! Tried to sublcass $parent" if $self->{parent};

    my $pmeta = $self->get($parent) || die "$parent is not a HashBase object!";
    $pmeta->{locked} = 1;

    $self->{parent} = $parent;
    $self->{fields} = $pmeta->fields; #Makes a copy
    $self->{order}  = $pmeta->order;  #Makes a copy

    my $ex_meta = Test::Stream::Exporter::Meta->get($self->{package});

    # Put parent constants into the subclass
    for my $field (@{$self->{order}}) {
        my $const = uc $field;
        no strict 'refs';
        *{"$self->{package}\::$const"} = $parent->can($const) || confess "Could not find constant '$const'!";
        $ex_meta->add($const);
    }
}

{
    no warnings 'once';
    *add_accessor = \&add_accessors;
}

sub add_accessors {
    my $self = shift;

    confess "Cannot add accessor, metadata is locked due to a subclass being initialized ($self->{parent}).\n"
        if $self->{locked};

    my $ex_meta = Test::Stream::Exporter::Meta->get($self->{package});

    for my $name (@_) {
        confess "field '$name' already defined!"
            if exists $self->{fields}->{$name};

        $self->{fields}->{$name} = 1;
        push @{$self->{order}} => $name;

        my $const = uc $name;
        my $gname = lc $name;
        my $sname = "set_$gname";

        my $cname = $name;
        my $csub = sub() { $cname };

        {
            no strict 'refs';
            *{"$self->{package}\::$const"} = $csub;
            *{"$self->{package}\::$gname"} = sub { $_[0]->{$name} };
            *{"$self->{package}\::$sname"} = sub { $_[0]->{$name} = $_[1] };
        }

        $ex_meta->{exports}->{$const} = $csub;
        push @{$ex_meta->{polist}} => $const;
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
    $meta->add_accessor('foo');

=head1 DESCRIPTION

This is the meta-object used by L<Test::Stream::HashBase>

=head1 METHODS

=over 4

=item $meta = $class->new($package)

Create a new meta object for the specified class. If one already exists that
instance is returned.

=item $meta = $class->get($package)

Get the meta object for the specified class. Returns C<undef> if there is none
initiated.

=item $package = $meta->package

Get the package the meta-object manages.

=item $package = $meta->parent

Get the parent package to the one being managed.

=item $bool = $meta->locked

True if the package has been locked. Locked means no new accessors can be
added. A package is locked once something else subclasses it.

=item $hr = $meta->fields

Get a hashref defining the fields on the package. This is primarily for
internal use, it is not very useful outside.

=item $ar = $meta->order

All fields for the class in order starting with fields from base classes.

=item $meta->baseclass

Make the package inherit from HashBase directly.

=item $meta->subclass($package)

Set C<$package> as the base class of the managed package.

=item $meta->add_accessor($name)

Add an accessor to the package. Also defines the C<"set_$name"> method, and the
C<uc($name)> constant.

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
