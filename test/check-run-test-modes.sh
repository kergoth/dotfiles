#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

run_case() {
  (cd "$root" && HOME=/tmp ./test/containers/run-test "$@")
}

assert_contains() {
  haystack=$1
  needle=$2
  case "$haystack" in
    *"$needle"*) ;;
    *)
      echo "expected output to contain: $needle" >&2
      echo "actual output:" >&2
      printf '%s\n' "$haystack" >&2
      exit 1
      ;;
  esac
}

assert_fails() {
  if "$@"; then
    echo "expected command to fail: $*" >&2
    exit 1
  fi
}

output=$(run_case -n -r -c 'printf ok' debian 2>&1)
assert_contains "$output" "TEST_SETUP_MODE=root-only"
assert_contains "$output" "TEST_ACTION=command"
assert_contains "$output" "TEST_COMMAND=printf ok"

output_i=$(run_case -n -r -i debian 2>&1)
assert_contains "$output_i" "TEST_ACTION=shell"

assert_fails run_case -n -r -S debian >/dev/null 2>&1
assert_fails run_case -n -s debian >/dev/null 2>&1
assert_fails run_case -n -a -c 'printf ok' >/dev/null 2>&1
