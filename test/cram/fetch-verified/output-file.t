An existing matching file short-circuits without running curl:

  $ . "$TESTDIR/helpers.sh"
  $ setup_fetch_verified_env
  $ printf 'kitten\n' >"$WORKDIR/kitty-installer.sh"
  $ write_fake_sha256sum "4e3f2c1b0a99887766554433221100ffeeddccbbaa99887766554433221100ff"
  $ cat >"$BINDIR/curl" <<'EOF'
  > #!/bin/sh
  > exit 99
  > EOF
  $ chmod +x "$BINDIR/curl"
  $ run_fetch_verified -o "$WORKDIR/kitty-installer.sh" https://example.invalid/kitty 4e3f2c1b0a99887766554433221100ffeeddccbbaa99887766554433221100ff
  $ test -f "$WORKDIR/kitty-installer.sh"

A mismatched existing file requires --force:

  $ rc=0; run_fetch_verified -o "$WORKDIR/kitty-installer.sh" https://example.invalid/kitty deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  101
  $ cat /tmp/err
  fetch-verified: existing file digest mismatch: */kitty-installer.sh (glob)

Non-regular existing destinations are rejected:

  $ rm -f "$WORKDIR/kitty-installer.sh"
  $ mkdir "$WORKDIR/not-a-file"
  $ rc=0; run_fetch_verified -o "$WORKDIR/not-a-file" https://example.invalid/kitty deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  101
  $ cat /tmp/err
  fetch-verified: destination must be a regular file: */not-a-file (glob)
