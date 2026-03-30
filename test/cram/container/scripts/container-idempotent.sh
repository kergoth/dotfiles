#!/bin/sh

set -eu

PATH="$HOME/.local/bin:$PATH"

. "$(dirname "$0")/chezmoi-diff.sh"

# This scenario intentionally checks repeated user-level apply behavior on an
# already bootstrapped container. It does not rerun setup-system.
./script/setup </dev/null
./script/setup </dev/null
check_clean_chezmoi_diff /tmp/chezmoi-diff.txt
printf 'ok-idempotent\n'
