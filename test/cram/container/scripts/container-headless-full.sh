#!/bin/sh

set -eu

PATH="$HOME/.local/bin:$PATH"

. "$(dirname "$0")/chezmoi-diff.sh"

test -d "$HOME/.local/share/chezmoi"
test -f "$HOME/.config/zsh/.zshrc"
command -v zsh >/dev/null 2>&1
check_clean_chezmoi_diff /tmp/chezmoi-diff.txt
zsh -lc 'printf ok-headless-full\n'
