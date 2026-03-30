#!/bin/sh

set -eu

PATH="$HOME/.local/bin:$PATH"

. "$(dirname "$0")/chezmoi-diff.sh"

test "${DOTFILES_SECRETS:-0}" = "1"
test -f "$HOME/.config/chezmoi/age.key"
profile=$(
    chezmoi execute-template --no-tty --stdinisatty=false \
        '{{ if .personal }}personal{{ else if .work }}work{{ else }}none{{ end }}'
)
test "$profile" != "none"
check_clean_chezmoi_diff /tmp/chezmoi-diff.txt
printf 'ok-secrets\n'
