package Test::Stream::IPC::INET;
use strict;
use warnings;

use base 'Test::Stream::IPC';

use Test::Stream::HashBase(
    accessors => [qw/tid pid globals root hubmap/],
);

use Scalar::Util qw/blessed/;
use Digest::MD5  qw/md5_hex/;

use Test::Stream::Util qw/try get_tid USE_THREADS/;

my $ROOT;
my $GOOD;
sub is_viable {
    return $GOOD if defined $GOOD;
    my ($ok, $err) = try {
        require IO::Socket::INET;
        $ROOT = IO::Socket::INET->new(Listen => 1) || die "Could not open socket!";
    };
    $GOOD = $ok && $ROOT;
    return $GOOD;
}

sub init {
    my $self = shift;

    $self->{+TID} = get_tid();
    $self->{+PID} = $$;
    $self->{+GLOBALS} = {};
    $self->{+HUBMAP}  = {};
    $self->{+ROOT} = $ROOT || IO::Socket::INET->new(Listen => 1) || die "Could not open socket!";
    $ROOT = undef;

    return $self;
}

sub add_hub {
    my $self = shift;
    local $?;
    my ($hid) = @_;

    $self->abort_trace("hub '$hid' already registered")
        if $self->{+HUBMAP}->{$hid};

    my $listen;
    if (keys %{$self->{+HUBMAP}}) {
        $listen = IO::Socket::INET->new(Listen => 1) || $self->abort_trace("Could not open a listen socket!");
    }
    else {
        $listen = $self->{+ROOT};
    }

    $self->{+HUBMAP}->{$hid} = {
        pid    => $$,
        tid    => get_tid(),
        port   => $listen->sockport,
        listen => $listen,
    };

    unless ($listen == $self->{+ROOT}) {
        my $socket = IO::Socket::INET->new(
            PeerHost => 'localhost',
            PeerPort => $self->{+ROOT}->sockport,
        ) || $self->abort_trace("Could not connect to root server!");

        require Storable unless $INC{'Storable.pm'};
        my $msg = Storable::freeze({
            
        });
    }
}

sub drop_hub {
    my $self = shift;
    local $?;
    my ($hid) = @_;

    my $tdir = $self->{+TEMPDIR};
    my $hfile = File::Spec->canonpath("$tdir/HUB-$hid");

    $self->abort_trace("File for hub '$hid' does not exist")
        unless -e $hfile;

    open(my $fh, '<', $hfile) || $self->abort_trace("Could not open hub file '$hid': $!");
    my ($pid, $tid) = <$fh>;
    close($fh);

    $self->abort_trace("A hub file can only be closed by the process that started it\nExpected $pid, got $$")
        unless $pid == $$;

    $self->abort_trace("A hub file can only be closed by the thread that started it\nExpected $tid, got " . get_tid())
        unless get_tid() == $tid;

    if ($ENV{TS_KEEP_TEMPDIR}) {
        rename($hfile, File::Spec->canonpath("$hfile.complete")) || $self->abort_trace("Could not rename file '$hfile' -> '$hfile.complete'");
    }
    else {
        unlink($hfile) || $self->abort_trace("Could not remove file for hub '$hid'");
    }

    opendir(my $dh, $tdir) || $self->abort_trace("Could not open temp dir!");
    for my $file (readdir($dh)) {
        next if $file =~ m{\.complete$};
        next unless $file =~ m{^$hid};
        $self->abort_trace("Not all files from hub '$hid' have been collected!");
        last;
    }
    closedir($dh);
}

sub send {
    my $self = shift;
    local $?;
    my ($hid, $e) = @_;

    my $tempdir = $self->{+TEMPDIR};

    my $global = $hid eq 'GLOBAL';

    my $hfile = File::Spec->canonpath("$tempdir/HUB-$hid");

    $self->abort("hub '$hid' is not available! Failed to send event!\n")
        unless $global || -f $hfile;

    my @type = split '::', blessed($e);
    my $name = join('-', $hid, $$, get_tid(), $self->{+EVENT_ID}++, @type);
    my $file = File::Spec->canonpath("$tempdir/$name");

    my $ready = File::Spec->canonpath("$file.ready");

    $self->globals->{"$name.ready"}++ if $global;

    require Storable unless $INC{'Storable.pm'};
    my ($ok, $err) = try {
        Storable::store($e, $file);
        rename($file, $ready) || die "Could not rename file '$file' -> '$ready'\n";
    };
    if (!$ok) {
        my $src_file = __FILE__;
        $err =~ s{ at \Q$src_file\E.*$}{};
        chomp($err);
        my $tid = get_tid();
        my $type = blessed($e);
        my $trace = $e->debug->trace;

        $self->abort(<<"        EOT");

*******************************************************************************
There was an error writing an event:
Destination: $hid
Origin PID:  $$
Origin TID:  $tid
Event Type:  $type
Event Trace: $trace
File Name:   $file
Ready Name:  $ready
Error: $err
*******************************************************************************

        EOT
    }
}

sub cull {
    my $self = shift;
    local $?;
    my ($hid) = @_;

    my $tempdir = $self->{+TEMPDIR};

    require Storable unless $INC{'Storable.pm'};
    opendir(my $dh, $tempdir) || $self->abort("could not open IPC temp dir ($tempdir)!");

    my @out;
    my @files = sort readdir($dh);
    for my $file (@files) {
        next if $file =~ m/^\.+$/;
        next unless $file =~ m/^(\Q$hid\E|GLOBAL)-.*\.ready$/;
        my $global = $1 eq 'GLOBAL';
        next if $global && $self->globals->{$file}++;

        # Untaint the path.
        my $full = File::Spec->canonpath("$tempdir/$file");
        ($full) = ($full =~ m/^(.*)$/gs);

        my $obj = Storable::retrieve($full);
        $self->abort("Empty event object recieved") unless $obj;
        $self->abort("Event '$obj' has unknown type! Did you forget to load the event package in the parent process?")
            unless $obj->isa('Test::Stream::Event');

        # Do not remove global events
        unless ($global) {
            my $complete = File::Spec->canonpath("$full.complete");
            if ($ENV{TS_KEEP_TEMPDIR}) {
                rename($full, $complete)
                    || warn "Could not rename IPC file '$full', '$complete'\n";
            }
            else {
                unlink($full) || warn "Could not unlink IPC file: $file\n";
            }
        }

        push @out => $obj;
    }

    closedir($dh);
    return @out;
}

sub waiting {
    my $self = shift;
    local $?;
    require Test::Stream::Event::Waiting;
    $self->send(
        GLOBAL => Test::Stream::Event::Waiting->new(
            debug => Test::Stream::DebugInfo->new(frame => [caller()]),
        )
    );
    return;
}

sub DESTROY {
    my $self = shift;
    local $?;

    return unless defined $self->pid;
    return unless defined $self->tid;

    return unless $$        == $self->pid;
    return unless get_tid() == $self->tid;

    my $tempdir = $self->{+TEMPDIR};

    if ($ENV{TS_KEEP_TEMPDIR}) {
        print STDERR "# Not removing temp dir: $tempdir\n";
        return;
    }

    opendir(my $dh, $tempdir) || $self->abort("Could not open temp dir! ($tempdir)");
    while(my $file = readdir($dh)) {
        next if $file =~ m/^\.+$/;
        next if $file =~ m/\.complete$/;
        my $full = File::Spec->canonpath("$tempdir/$file");

        if ($file =~ m/^(GLOBAL|HUB-)/) {
            $file =~ m/^(.*)$/;
            $file = $1; # Untaint it
            next if $ENV{TS_KEEP_TEMPDIR};
            unlink($full) || warn "Could not unlink IPC file: $full";
            next;
        }

        $self->abort("Leftover files in the directory ($full)!\n");
    }
    closedir($dh);

    return if $ENV{TS_KEEP_TEMPDIR};

    rmdir($tempdir) || warn "Could not remove IPC temp dir ($tempdir)";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::IPC::INET

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

=head1 SYNOPSIS

    use Test::Stream::IPC::INET;

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
