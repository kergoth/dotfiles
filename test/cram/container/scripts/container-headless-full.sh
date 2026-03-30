#!/bin/sh

set -eu

PATH="$HOME/.local/bin:$PATH"

. "$(dirname "$0")/chezmoi-diff.sh"

test -d "$HOME/.local/share/chezmoi"
test -f "$HOME/.config/zsh/.zshrc"
test -f "$HOME/.config/git/config"
check_clean_chezmoi_diff /tmp/chezmoi-diff.txt
zsh -i -c '
command -v chezmoi >/dev/null 2>&1
command -v zsh >/dev/null 2>&1
command -v rg >/dev/null 2>&1
printf ok-headless-full\n
'
