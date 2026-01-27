# IO::Divert - AI Agent Notes

## Module Purpose

IO::Divert temporarily diverts STDOUT to an internal buffer using Perl's
`select()` function. When the object goes out of scope (DESTROY), the
captured output is optionally processed and printed to the original STDOUT.

## Origin

Derived from `App::sdif::Divert` used in sdif/cdif tools. Released as
independent module for general use.

## Key Design Decisions

### RAII Pattern
- Object creation starts capture
- DESTROY automatically restores STDOUT and prints
- No explicit close/restore needed

### Encoding Handling
- Internal buffer uses `:encoding($encoding)` layer
- DESTROY decodes buffer before printing to original STDOUT
- Default encoding: utf-8

### FINAL Callback
- Operates on `$_` (localized copy of buffer)
- Applied before autoprint
- Common use: add prefixes, filter lines, transform text

## API

```perl
# Constructor options
IO::Divert->new(
    encoding  => 'utf-8',  # buffer encoding
    autoprint => 1,        # print on destroy
    FINAL     => sub {},   # post-process callback
);

# Methods
$obj->content;   # get captured text (with flush)
$obj->buffer;    # get reference to buffer
$obj->fh;        # get filehandle
$obj->flush;     # flush buffer
$obj->clear;     # clear buffer
```

## Test Notes

UTF-8 test requires `Encode::decode()` on output scalar because:
1. Test's STDOUT opened with `:encoding(utf-8)` to scalar
2. Scalar receives UTF-8 encoded bytes
3. Comparison with character string needs decode

## Related Work

- Capture::Tiny - heavier, captures process-wide
- IO::Capture::Stdout - not RAII pattern
- App::sdif::Divert - original implementation

## Failed Experiments (Context)

Attempted fork-less function execution combining IO::Divert with
Command::Run. Failed because Perl's `<>` operator has global state
that cannot be localized with `local *STDIN`.
