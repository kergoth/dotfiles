Digest failure leaves the existing local binary unchanged:

  $ . "$TESTDIR/helpers.sh"
  $ setup_codex_install_env
  $ mkdir -p "$HOME/.local/bin"
  $ cat >"$HOME/.local/bin/codex" <<'EOF'
  > #!/bin/sh
  > printf 'codex 0.121.0\n'
  > EOF
  $ chmod +x "$HOME/.local/bin/codex"
  $ make_codex_archive 0.122.0
  $ write_fake_fetch_verified fail
  $ write_fake_brew 1
  $ write_fake_rg
  $ rc=0; run_install_codex >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  100
  $ "$HOME/.local/bin/codex" --version
  codex 0.121.0

Version mismatch after extraction fails closed:

  $ make_codex_archive 0.122.1
  $ write_fake_fetch_verified pass
  $ write_fake_brew 0
  $ rc=0; run_install_codex >/tmp/out 2>/tmp/err || rc=$?; printf '%s\n' "$rc"
  1
  $ cat /tmp/err
  install-codex: installed Codex version 0.122.1 does not match expected 0.122.0
  $ "$HOME/.local/bin/codex" --version
  codex 0.121.0
