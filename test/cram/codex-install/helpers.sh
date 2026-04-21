#!/bin/sh

set -eu

REPO_ROOT=$(cd "$TESTDIR/../../.." && pwd)

setup_codex_install_env() {
    WORKDIR="$CRAMTMP/work"
    BINDIR="$CRAMTMP/bin"
    HOME_DIR="$CRAMTMP/home"
    mkdir -p "$WORKDIR" "$BINDIR" "$HOME_DIR/.local/bin"
    export WORKDIR BINDIR HOME_DIR
    export HOME="$HOME_DIR"
    export PATH="$BINDIR:/usr/bin:/bin"
}

make_codex_archive() {
    version=$1
    stage="$WORKDIR/archive-stage"
    rm -rf "$stage"
    mkdir -p "$stage"
    cat >"$stage/codex-aarch64-apple-darwin" <<EOF
#!/bin/sh
printf 'codex %s\n' "$version"
EOF
    chmod +x "$stage/codex-aarch64-apple-darwin"
    tar -czf "$WORKDIR/codex-aarch64-apple-darwin.tar.gz" -C "$stage" codex-aarch64-apple-darwin
}

write_fake_fetch_verified() {
    mode=$1
    cat >"$BINDIR/fetch-verified" <<'EOF'
#!/bin/sh
set -eu
mode=$FAKE_FETCH_MODE
printf '%s\n' "$*" >>"$WORKDIR/fetch-verified.log"
if [ "$mode" = fail ]; then
    echo "fetch-verified: digest mismatch for $3" >&2
    exit 100
fi
outfile=
while [ $# -gt 0 ]; do
    case "$1" in
        -o)
            shift
            outfile=$1
            ;;
    esac
    shift
done
[ -n "$outfile" ]
cp "$FAKE_FETCH_ARCHIVE" "$outfile"
EOF
    chmod +x "$BINDIR/fetch-verified"
    export FAKE_FETCH_MODE=$mode
    export FAKE_FETCH_ARCHIVE="$WORKDIR/codex-aarch64-apple-darwin.tar.gz"
    : >"$WORKDIR/fetch-verified.log"
}

write_fake_brew() {
    present=$1
    cat >"$BINDIR/brew" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$WORKDIR/brew.log"
if [ "$1" = list ] && [ "$2" = --cask ] && [ "$3" = codex ]; then
    [ "$FAKE_BREW_PRESENT" = 1 ] && exit 0
    exit 1
fi
if [ "$1" = uninstall ] && [ "$2" = --cask ] && [ "$3" = codex ]; then
    exit 0
fi
exit 0
EOF
    chmod +x "$BINDIR/brew"
    export FAKE_BREW_PRESENT=$present
    : >"$WORKDIR/brew.log"
}

write_fake_rg() {
    cat >"$BINDIR/rg" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$BINDIR/rg"
}

run_install_codex() {
    bash "$REPO_ROOT/scripts/install-codex" \
        --tag rust-v0.122.0 \
        --version 0.122.0 \
        --url https://example.invalid/codex-aarch64-apple-darwin.tar.gz \
        --sha256 deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef
}
