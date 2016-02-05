package Test::Stream::Formatter::TAP;
use strict;
use warnings;

use Test::Stream::Util qw/protect/;
use Test::Stream::HashBase(
    accessors => [qw/no_numbers no_header no_diag handles _encoding/],
);

sub OUT_STD()  { 0 }
sub OUT_ERR()  { 1 }
sub OUT_TODO() { 2 }

use Test::Stream::Exporter qw/import exports/;
exports qw/OUT_STD OUT_ERR OUT_TODO/;
no Test::Stream::Exporter;

_autoflush(\*STDOUT);
_autoflush(\*STDERR);

sub init {
    my $self = shift;

    $self->{+HANDLES} ||= $self->_open_handles;
    if(my $enc = delete $self->{encoding}) {
        $self->encoding($enc);
    }
}

sub encoding {
    my $self = shift;

    if (@_) {
        my ($enc) = @_;
        my $handles = $self->{+HANDLES};

        # https://rt.perl.org/Public/Bug/Display.html?id=31923
        # If utf8 is requested we use ':utf8' instead of ':encoding(utf8)' in
        # order to avoid the thread segfault.
        if ($enc =~ m/^utf-?8$/i) {
            binmode($_, ":utf8") for @$handles;
        }
        else {
            binmode($_, ":encoding($enc)") for @$handles;
        }
        $self->{+_ENCODING} = $enc;
    }

    return $self->{+_ENCODING};
}

if ($^C) {
    no warnings 'redefine';
    *write = sub {};
}
sub write {
    my ($self, $e, $num) = @_;

    return if $self->{+NO_DIAG}   && $e->isa('Test::Stream::Event::Diag');
    return if $self->{+NO_HEADER} && $e->isa('Test::Stream::Event::Plan');

    $num = undef if $self->{+NO_NUMBERS};
    my @tap = $e->to_tap($num);

    my $handles = $self->{+HANDLES};
    my $nesting = $e->nested || 0;
    my $indent = '    ' x $nesting;

    return if $nesting && $e->isa('Test::Stream::Event::Bail');

    local($\, $", $,) = (undef, ' ', '');
    for my $set (@tap) {
        no warnings 'uninitialized';
        my ($hid, $msg) = @$set;
        next unless $msg;
        my $io = $handles->[$hid] or next;

        $msg =~ s/^/$indent/mg if $nesting;
        print $io $msg;
    }
}

sub _open_handles {
    my $self = shift;

    open( my $out, ">&STDOUT" ) or die "Can't dup STDOUT:  $!";
    open( my $err, ">&STDERR" ) or die "Can't dup STDERR:  $!";

    _autoflush($out);
    _autoflush($err);

    return [$out, $err, $out];
}

sub _autoflush {
    my($fh) = pop;
    my $old_fh = select $fh;
    $| = 1;
    select $old_fh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Formatter::TAP - Standard TAP formatter

=head1 DEPRECATED

B<This distribution is deprecated> in favor of L<Test2>, L<Test2::Suite>, and
L<Test2::Workflow>.

See L<Test::Stream::Manual::ToTest2> for a conversion guide.

=head1 DESCRIPTION

This is what takes events and turns them into TAP.

=head1 SYNOPSIS

    use Test::Stream::Formatter::TAP;
    my $tap = Test::Stream::Formatter::TAP->new();

    # Switch to utf8
    $tap->encoding('utf8');

    $tap->write($event, $number); # Output an event

=head1 EXPORTS

=over 4

=item OUT_STD

=item OUT_ERR

=item OUT_TODO

These are constants to identify filehandles. These constants are used by events
to direct text to the correct filehandle.

=back

=head1 METHODS

=over 4

=item $bool = $tap->no_numbers

=item $tap->set_no_numbers($bool)

Use to turn numbers on and off.

=item $bool = $tap->no_header($bool)

=item $tap->set_no_header($bool)

When true, the plan will not be rendered.

=item $bool = $tap->no_diag

=item $tap->set_no_diag($bool)

When true, diagnostics will not be rendered.

=item $arrayref = $tap->handles

=item $tap->set_handles(\@handles);

Can be used to get/set the filehandles. Indexes are identified by the
C<OUT_STD, OUT_ERR, OUT_TODO> constants.

=item $encoding = $tap->encoding

=item $tap->encoding($encoding)

Get or set the encoding. By default no encoding is set, the original settings
of STDOUT and STDERR are used.

This directly modifies the stored filehandles, it does not create new ones.

=item $tap->write($e, $num)

Write an event to the console.

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

See F<http://dev.perl.org/licenses/>

=cut
