{{ if .secrets -}}
#!/bin/sh

if ! command -v gpg >/dev/null 2>&1; then
    echo >&2 "No 'gpg' command found"
    exit 1
fi
if ! command -v op >/dev/null 2>&1; then
    echo >&2 "No 'op' command found"
    exit 1
fi

eval "$(op signin)"

for key_id in A3F86002F03EE587 BCC304A4E9BFE3CF; do
    if [ -z "$(gpg --quiet --armor --export "$key_id")" ]; then
        op document get "GnuPG Secret Key: $key_id" | gpg --import -
    fi
done
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

gpg --list-secret-keys --keyid-format=long | tail -n +3 | grep -Ev '^(ssb|sec|uid|ssb) '|xargs | tr ' ' '\n' | sort >"$tmpdir/keys"
gpg --export-ownertrust | grep -v '^#' | sort >"$tmpdir/trust"
if [ -n "$(comm -23 "$tmpdir/keys" "$tmpdir/trust")" ]; then
    # Missing trust values for secret keys
    op document get "GnuPG Owner Trust" | gpg --quiet --import-ownertrust -
fi
{{ end -}}
