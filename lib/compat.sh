# shellcheck shell=bash
# Platform shims so the rest of lib/ (and the drop-ins) works on GNU/Linux and macOS/BSD.
# Detected once at source time, then called as plain functions.

# _mtime <file> — file modification time as a Unix epoch.
if stat -c %Y / >/dev/null 2>&1; then
    _mtime() { stat -c %Y "$1"; }   # GNU coreutils (Linux)
else
    _mtime() { stat -f %m "$1"; }   # BSD stat (macOS)
fi

# _sha256 — read stdin, print "<hex>  -". Output format matches across both,
# so `cut -d ' ' -f 1` works either way.
if command -v sha256sum >/dev/null 2>&1; then
    _sha256() { sha256sum; }        # GNU coreutils (Linux)
else
    _sha256() { shasum -a 256; }    # macOS / Perl shasum
fi
