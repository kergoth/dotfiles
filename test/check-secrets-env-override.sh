#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
tmpl="$root/test/fixtures/secrets-env-override.tmpl"

run_case() {
  name=$1
  shift
  expected=$1
  shift
  output=$(cd "$root" && env "$@" scripts/chezmoi-execute-template "$tmpl")
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
  DOTFILES_SECRETS=0
