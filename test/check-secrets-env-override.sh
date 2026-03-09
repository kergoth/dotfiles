#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

render_config() {
  (cd "$root" && env "$@" chezmoi execute-template --init -f home/.chezmoi.toml.tmpl)
}

extract_values() {
  awk '
    /^\[data\]/ { in_data=1; next }
    /^\[/ { in_data=0 }
    in_data && $1 == "personal" { personal=$3 }
    in_data && $1 == "work" { work=$3 }
    in_data && $1 == "secrets" { secrets=$3 }
    END { printf "secrets=%s personal=%s work=%s\n", secrets, personal, work }
  '
}

run_case() {
  name=$1
  shift
  expected=$1
  shift
  output=$(render_config "$@" | extract_values)
  if [ "$output" != "$expected" ]; then
    echo "FAIL: $name" >&2
    echo "expected: $expected" >&2
    echo "actual:   $output" >&2
    exit 1
  fi
}

run_case "secrets-forced-personal" \
  "secrets=true personal=true work=false" \
  DOTFILES_SECRETS=1 DOTFILES_PERSONAL=1

run_case "secrets-forced-work" \
  "secrets=true personal=false work=true" \
  DOTFILES_SECRETS=1 DOTFILES_WORK=1

run_case "secrets-disabled" \
  "secrets=false personal=false work=false" \
  DOTFILES_SECRETS=0 DOTFILES_PERSONAL=0 DOTFILES_WORK=0
