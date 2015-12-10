package Test::Sync::HashBase;
use strict;
use warnings;

use Carp qw/confess croak carp/;
use Scalar::Util qw/blessed reftype/;

$Carp::Internal{(__PACKAGE__)}++;

my (%META);

sub import {
    my ($class, %args) = @_;

    my $into = $args{into} || caller;
    my $meta = $META{$into} = $args{accessors} || [];

    # Use the comment to change the filename slightly so that Devel::Cover does
    # not try to cover the contents of the string eval.
    my $file = __FILE__;
    $file =~ s/(\.*)$/.eval$1/;
    my $eval = "# line 1 \"$file\"\npackage $into;\n";

    my $isa = do { no strict 'refs'; \@{"$into\::ISA"} };

    if(my @bmetas = map { $META{$_} or () } @$isa) {
        $eval .= "sub " . uc($_) . "() { '$_' };\n" for map { @{$_} } @bmetas;
    }

    if(my $base = $args{base}) {
        carp "'base' argument to HashBase is deprecated.";
        my $bmeta = $META{$base} || croak "Base class '$base' is not a HashBase class";

        unless ($into->isa($base)) {
            $eval .= "sub " . uc($_) . "() { '$_' };\n" for @$bmeta;
            push @$isa => $base;
        }
    }

    {
        $eval .= join '' => map {
            my $const = uc($_);
            <<"            EOT"
sub $const() { '$_' }
sub $_       { \$_[0]->{'$_'} }
sub set_$_   { \$_[0]->{'$_'} = \$_[1] }
sub clear_$_ { delete \$_[0]->{'$_'} }
            EOT
        } @$meta;
    }

    eval "${eval}1;" || die $@;

    return if $args{no_new};

    no strict 'refs';
    *{"$into\::new"} = \&_new;
}

sub _new {
    my ($class, %params) = @_;
    my $self = bless \%params, $class;
    $self->init if $self->can('init');
    $self;
}

sub gen_accessor {
    my $class = shift;
    my ($field) = @_;
    sub {
        my $self = shift;
        ($self->{$field}) = @_ if @_;
        $self->{$field};
    };
}

sub gen_getter {
    my $class = shift;
    my ($field) = @_;
    sub { $_[0]->{$field} };
}

sub gen_setter {
    my $class = shift;
    my ($field) = @_;
    sub { $_[0]->{$field} = $_[1] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sync::HashBase - Base class for classes that use a hashref
of a hash.

=head1 SYNOPSIS

A class:

    package My::Class;
    use strict;
    use warnings;

    use Test::Sync::HashBase accessors => [qw/foo bar baz/];

    # Chance to initialize defaults
    sub init {
        my $self = shift;    # No other args
        $self->{+FOO} ||= "foo";
        $self->{+BAR} ||= "bar";
        $self->{+BAZ} ||= "baz";
    }

    sub print {
        print join ", " => map { $self->{$_} } FOO, BAR, BAZ;
    }

Subclass it

    package My::Subclass;
    use strict;
    use warnings;

    # Note, you should subclass before loading HashBase.
    use base 'My::Class';
    use Test::Sync::HashBase accessors => ['bat'];

    sub init {
        my $self = shift;

        # We get the constants from the base class for free.
        $self->{+FOO} ||= 'SubFoo';
        $self->{+BAT} || = 'bat';

        $self->SUPER::init();
    }

use it:

    package main;
    use strict;
    use warnings;
    use My::Class;

    my $one = My::Class->new(foo => 'MyFoo', bar => 'MyBar');

    # Accessors!
    my $foo = $one->foo;    # 'MyFoo'
    my $bar = $one->bar;    # 'MyBar'
    my $baz = $one->baz;    # Defaulted to: 'baz'

    # Setters!
    $one->set_foo('A Foo');
    $one->set_bar('A Bar');
    $one->set_baz('A Baz');

    # Clear!
    $one->clear_foo;
    $one->clear_bar;
    $one->clear_baz;

    $one->{+FOO} = 'xxx';

=head1 DESCRIPTION

This package is used to generate classes based on hashrefs. Using this class
will give you a C<new()> method, as well as generating accessors you request.
Generated accessors will be getters, C<set_ACCESSOR> setters will also be
generated for you. You also get constants for each accessor (all caps) which
return the key into the hash for that accessor. Single inheritence is also
supported.

=head1 IMPORT ARGUMENTS

=over 4

=item accessors => [...]

This is how you define your accessors. See the ACCESSORS section below.

=item base => $class

B<*** DEPRECATED ***> Just C<use base 'Parent::Class';> before loading
HashBase.

This is how you subclass a Test::Sync::Hashbase class. This will give you all
the constants of the parent(s).

=item into => $class

This is a way to apply HashBase to another class.

    package My::Thing;

    sub import {
        my $caller = caller;
        Test::Sync::HashBase->import(@_, into => $class);
        ...
    }

=back

=head1 METHODS

=head2 PROVIDED BY HASH BASE

=over 4

=item $it = $class->new(@VALUES)

Create a new instance using key/value pairs.

=back

=head2 HOOKS

=over 4

=item $self->init()

This gives you the chance to set some default values to your fields. The only
argument is C<$self> with its indexes already set from the constructor.

=back

=head1 ACCESSORS

To generate accessors you list them when using the module:

    use Test::Sync::HashBase accessors => [qw/foo/];

This will generate the following subs in your namespace:

=over 4

=item foo()

Getter, used to get the value of the C<foo> field.

=item set_foo()

Setter, used to set the value of the C<foo> field.

=item clear_foo()

Clearer, used to completely remove the 'foo' key from the object hash.

=item FOO()

Constant, returs the field C<foo>'s key into the class hashref. Subclasses will
also get this function as a constant, not simply a method, that means it is
copied into the subclass namespace.

The main reason for using these constants is to help avoid spelling mistakes
and similar typos. It will not help you if you forget to prefix the '+' though.

=back

=head1 SUBCLASSING

You can subclass an existing HashBase class.

    use Test::Sync::HashBase
        base      => 'Another::HashBase::Class',
        accessors => [qw/foo bar baz/];

The base class is added to C<@ISA> for you, and all constants from base classes
are added to subclasses automatically.

=head1 UTILITIES

hashbase has a handful of class methods that can be used to generate accessors.
These methods B<ARE NOT> exported, and are not attached to objects created with
hashbase.

=over 4

=item $sub = Test::Sync::HashBase->gen_accessor($field)

This generates a coderef that acts as an accessor for the specified field.

=item $sub = Test::Sync::HashBase->gen_getter($field)

This generates a coderef that acts as a getter for the specified field.

=item $sub = Test::Sync::HashBase->get_setter($field)

This generates a coderef that acts as a setter for the specified field.

=back

These all work in the same way, except that getters only get, setters always
set, and accessors can get and/or set.

    my $sub = Test::Sync::HashBase->gen_accessor('foo');
    my $foo = $obj->$sub();
    $obj->$sub('value');

You can also add the sub to your class as a named method:

    *foo = Test::Sync::HashBase->gen_accessor('foo');

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

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
