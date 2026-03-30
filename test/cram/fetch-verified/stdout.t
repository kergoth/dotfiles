Stdout mode emits bytes only after verification succeeds:

  $ . "$TESTDIR/helpers.sh"
  $ setup_fetch_verified_env
  $ printf 'hello\n' >"$WORKDIR/payload"
  $ write_fake_curl "$WORKDIR/payload"
  $ write_fake_sha256sum "5891b5b522d5df086d0ff0b110fbfdb95e0a4e1a0a4f2c86bdf8b68c6c4f8d5b"
  $ run_fetch_verified https://example.invalid/file 5891b5b522d5df086d0ff0b110fbfdb95e0a4e1a0a4f2c86bdf8b68c6c4f8d5b
  hello

Digest mismatch returns the dedicated verification code:

  $ rc=0; run_fetch_verified https://example.invalid/file deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  100
  $ cat /tmp/err
  fetch-verified: digest mismatch for https://example.invalid/file

Empty downloads are rejected before any output is emitted:

  $ : >"$WORKDIR/empty"
  $ write_fake_curl "$WORKDIR/empty"
  $ rc=0; run_fetch_verified https://example.invalid/file deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  101
  $ cat /tmp/err
  fetch-verified: curl produced empty output
  $ test ! -s /tmp/out
