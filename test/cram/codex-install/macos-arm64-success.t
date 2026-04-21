Migration from Homebrew installs the pinned local binary and removes the cask:

  $ . "$TESTDIR/helpers.sh"
  $ setup_codex_install_env
  $ make_codex_archive 0.122.0
  $ write_fake_fetch_verified pass
  $ write_fake_brew 1
  $ write_fake_rg
  $ run_install_codex
  Installing Codex 0.122.0 from pinned release asset
  Removing legacy Homebrew Codex install
  $ "$HOME/.local/bin/codex" --version
  codex 0.122.0
  $ cat "$WORKDIR/fetch-verified.log"
  -o */codex-aarch64-apple-darwin.tar.gz https://example.invalid/codex-aarch64-apple-darwin.tar.gz deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef (glob)
  $ cat "$WORKDIR/brew.log"
  list --cask codex
  uninstall --cask codex

An idempotent rerun skips the verified download path:

  $ : >"$WORKDIR/fetch-verified.log"
  $ write_fake_brew 0
  $ run_install_codex
  Codex 0.122.0 already installed
  $ test ! -s "$WORKDIR/fetch-verified.log"
