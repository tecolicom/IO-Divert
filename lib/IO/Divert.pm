package IO::Divert;

use v5.14;
use warnings;
use utf8;
use Encode ();
use Carp;

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my %opt = (
	BUFFER    => '',
	encoding  => 'utf-8',
	autoprint => 1,
	@_
    );
    my $encoding = $opt{encoding};
    open $opt{FH}, ">:encoding($encoding)", \$opt{BUFFER}
	or croak "open: $!";
    $opt{STDOUT} = select $opt{FH}
	or croak "select: $!";
    bless \%opt, $class;
}

sub fh {
    my $obj = shift;
    $obj->{FH};
}

sub buffer {
    my $obj = shift;
    \$obj->{BUFFER};
}

sub content {
    my $obj = shift;
    $obj->flush;
    $obj->{BUFFER};
}

sub flush {
    my $obj = shift;
    $obj->fh->flush;
    $obj;
}

sub clear {
    my $obj = shift;
    $obj->flush;
    seek $obj->fh, 0, 0;
    $obj->fh->truncate(0);
    $obj->{BUFFER} = '';
    $obj;
}

sub DESTROY {
    my $obj = shift;
    $obj->fh->close;
    select $obj->{STDOUT};
    $obj->{BUFFER} // return;
    if (my $final = $obj->{FINAL}) {
	local $_ = $obj->{BUFFER};
	$final->();
	$obj->{BUFFER} = $_;
    }
    if ($obj->{autoprint}) {
	print Encode::decode($obj->{encoding}, $obj->{BUFFER});
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Divert - Divert STDOUT to capture and process output

=head1 SYNOPSIS

    use IO::Divert;

    # Basic usage - capture and auto-print on scope exit
    {
        my $divert = IO::Divert->new;
        print "Hello, World!\n";
        # Output is printed when $divert goes out of scope
    }

    # With post-processing
    {
        my $divert = IO::Divert->new(
            FINAL => sub { s/^/PREFIX: /mg }
        );
        print "Line 1\n";
        print "Line 2\n";
        # Output: "PREFIX: Line 1\nPREFIX: Line 2\n"
    }

    # Capture without auto-print
    my $captured;
    {
        my $divert = IO::Divert->new(autoprint => 0);
        print "captured text";
        $captured = $divert->content;
    }

=head1 DESCRIPTION

IO::Divert temporarily diverts STDOUT to an internal buffer.  When the
object is destroyed (typically at the end of scope), the captured
output is optionally processed and printed to the original STDOUT.

This is useful for:

=over 4

=item * Adding prefixes or suffixes to output

=item * Post-processing output (filtering, transformation)

=item * Capturing output for later use

=back

=head1 CONSTRUCTOR

=head2 new

    my $divert = IO::Divert->new(%options);

Creates a new IO::Divert object and begins capturing STDOUT.

Options:

=over 4

=item B<FINAL> => \&coderef

A subroutine to process the captured output before printing.
The captured text is available in C<$_> and should be modified
in place.

    FINAL => sub { s/foo/bar/g }

=item B<encoding> => $encoding

Character encoding for the buffer.  Default is C<utf-8>.

=item B<autoprint> => $bool

If true (default), automatically print the captured output when
the object is destroyed.  Set to false to capture without printing.

=back

=head1 METHODS

=head2 fh

    my $fh = $divert->fh;

Returns the filehandle used for capturing.

=head2 buffer

    my $bufref = $divert->buffer;

Returns a reference to the internal buffer string.

=head2 content

    my $text = $divert->content;

Returns the current captured content as a string.
This method flushes the buffer before returning.

=head2 flush

    $divert->flush;

Flushes the output buffer.  Returns the object for chaining.

=head2 clear

    $divert->clear;

Clears the captured content.  Returns the object for chaining.

=head1 EXAMPLES

=head2 Adding line numbers

    {
        my $n = 1;
        my $divert = IO::Divert->new(
            FINAL => sub { s/^/sprintf("%4d: ", $n++)/mge }
        );
        print "First line\n";
        print "Second line\n";
    }
    # Output:
    #    1: First line
    #    2: Second line

=head2 Conditional output

    {
        my $divert = IO::Divert->new(autoprint => 0);
        print "Some output\n";
        my $content = $divert->content;
        if ($should_print) {
            print $content;
        }
    }

=head1 SEE ALSO

L<Capture::Tiny>, L<IO::Capture::Stdout>

=head1 AUTHOR

Kazumasa Utashiro E<lt>kaz@utashiro.comE<gt>

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
