#!/bin/sh

set -eu

TEST_ROOT=$(cd "$TESTDIR/../../.." && pwd)
HOST_HOME=${HOME:?}

all_headless_full_distros() {
    printf '%s\n' arch chimera debian fedora ubuntu
}

idempotent_distros() {
    printf '%s\n' debian fedora
}

replay_distros() {
    printf '%s\n' debian fedora
}

secrets_distros() {
    printf '%s\n' fedora
}

run_script_test() {
    distro=$1
    shift
    (
        cd "$TEST_ROOT"
        HOME=/tmp ./script/test "$@" "$distro"
    )
}

run_container_runner() {
    distro=$1
    shift
    (
        cd "$TEST_ROOT"
        HOME=/tmp ./test/containers/run-test "$@" "$distro"
    )
}

run_container_runner_with_host_home() {
    distro=$1
    shift
    (
        cd "$TEST_ROOT"
        HOME=$HOST_HOME ./test/containers/run-test "$@" "$distro"
    )
}

run_case_quietly() {
    log_file=$1
    shift

    if "$@" >"$log_file" 2>&1; then
        return 0
    else
        status=$?
        return "$status"
    fi
}

run_matrix() {
    scenario_name=$1
    distro_fn=$2
    shift 2

    "$distro_fn" | while IFS= read -r distro; do
        [ -n "$distro" ] || continue
        log_file="${CRAMTMP}/${scenario_name}-${distro}.log"
        printf '==> %s %s\n' "$scenario_name" "$distro"
        if run_case_quietly "$log_file" "$@" "$distro"; then
            printf 'ok %s %s\n' "$scenario_name" "$distro"
        else
            status=$?
            printf 'not ok %s %s status=%s\n' "$scenario_name" "$distro" "$status"
            cat "$log_file"
            return "$status"
        fi
    done
}

scenario_script_path() {
    printf '%s\n' "/home/testuser/.dotfiles/test/cram/container/scripts/$1"
}

run_headless_full_scenario() {
    distro=$1
    script_path=$(scenario_script_path container-headless-full.sh)
    run_container_runner "$distro" -c "sh $script_path"
}

run_idempotent_scenario() {
    distro=$1
    script_path=$(scenario_script_path container-idempotent.sh)
    run_container_runner "$distro" -c "sh $script_path"
}

run_replay_scenario() {
    distro=$1
    script_path=$(scenario_script_path container-replay.sh)
    run_container_runner "$distro" -c "sh $script_path"
}

run_secrets_scenario() {
    distro=$1
    script_path=$(scenario_script_path container-secrets.sh)
    DOTFILES_SECRETS=1 run_container_runner_with_host_home "$distro" -c "sh $script_path"
}

require_host_age_key() {
    test -f "$HOST_HOME/.config/chezmoi/age.key" || exit 80
}

run_script_test_smoke() {
    distro=$1
    log_file="${CRAMTMP}/script-test-smoke-${distro}.log"

    if run_case_quietly "$log_file" \
        run_script_test "$distro" -r -c 'getent passwd testuser >/dev/null && printf ok-script-test-smoke\n'
    then
        printf 'ok-script-test-smoke\n'
    else
        cat "$log_file"
        return 1
    fi
}
