#!/bin/sh

set -eu

REPO_ROOT=$(cd "$TESTDIR/../../.." && pwd)

setup_fetch_verified_env() {
    WORKDIR="$CRAMTMP/work"
    BINDIR="$CRAMTMP/bin"
    mkdir -p "$WORKDIR" "$BINDIR"
    export WORKDIR BINDIR
    export PATH="$BINDIR:/usr/bin:/bin"
}

write_fake_curl() {
    payload_file=$1
    cat >"$BINDIR/curl" <<'EOF'
#!/bin/sh
set -eu

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

[ -n "$outfile" ] || exit 97
cat "$FAKE_CURL_PAYLOAD" >"$outfile"
EOF
    chmod +x "$BINDIR/curl"
    export FAKE_CURL_PAYLOAD=$payload_file
}

write_fake_sha256sum() {
    digest=$1
    cat >"$BINDIR/sha256sum" <<EOF
#!/bin/sh
set -eu
printf '%s  %s\n' "$digest" "\$1"
EOF
    chmod +x "$BINDIR/sha256sum"
}

run_fetch_verified() {
    bash "$REPO_ROOT/scripts/fetch-verified" "$@"
}
