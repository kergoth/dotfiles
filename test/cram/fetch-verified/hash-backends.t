The script falls back from sha256sum to shasum:

  $ . "$TESTDIR/helpers.sh"
  $ setup_fetch_verified_env
  $ printf 'payload\n' >"$WORKDIR/payload"
  $ write_fake_curl "$WORKDIR/payload"
  $ cat >"$BINDIR/shasum" <<'EOF'
  > #!/bin/sh
  > set -eu
  > printf '%s  %s\n' "0123012301230123012301230123012301230123012301230123012301230123" "$3"
  > EOF
  $ chmod +x "$BINDIR/shasum"
  $ run_fetch_verified https://example.invalid/file 0123012301230123012301230123012301230123012301230123012301230123 >/tmp/out 2>/tmp/err
