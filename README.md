
# NAME

IO::Divert - Divert STDOUT to capture and process output

# SYNOPSIS

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

# DESCRIPTION

IO::Divert temporarily diverts STDOUT to an internal buffer.  When the
object is destroyed (typically at the end of scope), the captured
output is optionally processed and printed to the original STDOUT.

This is useful for:

- Adding prefixes or suffixes to output
- Post-processing output (filtering, transformation)
- Capturing output for later use

# CONSTRUCTOR

## new

    my $divert = IO::Divert->new(%options);

Creates a new IO::Divert object and begins capturing STDOUT.

Options:

- **FINAL** => \\&coderef

    A subroutine to process the captured output before printing.
    The captured text is available in `$_` and should be modified
    in place.

        FINAL => sub { s/foo/bar/g }

- **encoding** => $encoding

    Character encoding for the buffer.  Default is `utf-8`.

- **autoprint** => $bool

    If true (default), automatically print the captured output when
    the object is destroyed.  Set to false to capture without printing.

# METHODS

## fh

    my $fh = $divert->fh;

Returns the filehandle used for capturing.

## buffer

    my $bufref = $divert->buffer;

Returns a reference to the internal buffer string.

## content

    my $text = $divert->content;

Returns the current captured content as a string.
This method flushes the buffer before returning.

## flush

    $divert->flush;

Flushes the output buffer.  Returns the object for chaining.

## clear

    $divert->clear;

Clears the captured content.  Returns the object for chaining.

# EXAMPLES

## Adding line numbers

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

## Conditional output

    {
        my $divert = IO::Divert->new(autoprint => 0);
        print "Some output\n";
        my $content = $divert->content;
        if ($should_print) {
            print $content;
        }
    }

# SEE ALSO

[Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny), [IO::Capture::Stdout](https://metacpan.org/pod/IO%3A%3ACapture%3A%3AStdout)

# AUTHOR

Kazumasa Utashiro <kaz@utashiro.com>

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
