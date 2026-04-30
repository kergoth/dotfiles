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

run_container_runner_dry_raw() {
    (
        cd "$TEST_ROOT"
        GITHUB_TOKEN= CLAUDE_CODE_OAUTH_TOKEN= HOME=/tmp ./test/containers/run-test -n "$@"
    )
}

print_run_test_docker_tty() {
    log_file=$1
    docker_line=$(sed -n '/ docker run /{p;q;}' "$log_file")

    case $docker_line in
    *" docker run "*" --rm "*)
        docker_args=${docker_line#* docker run }
        docker_prefix="docker run ${docker_args%% --rm *}"
        ;;
    *)
        docker_prefix=
        ;;
    esac

    set -- $docker_prefix
    while [ $# -gt 0 ]; do
        if [ "$1" = "docker" ] && [ "${2:-}" = "run" ]; then
            shift 2
            break
        fi
        shift
    done

    while [ $# -gt 0 ]; do
        case $1 in
        -it)
            printf 'docker-tty=-it\n'
            return 0
            ;;
        -i)
            printf 'docker-tty=-i\n'
            return 0
            ;;
        esac
        shift
    done

    printf 'docker-tty=missing\n'
}

print_run_test_dry_contract() {
    log_file=$1
    shift

    print_run_test_docker_tty "$log_file"
    sed -n "s/.*'TEST_ACTION=\([^']*\)'.*/TEST_ACTION=\1/p" "$log_file"
    sed -n "s/.*'TEST_INTERACTIVE=\([^']*\)'.*/TEST_INTERACTIVE=\1/p" "$log_file"

    if grep -F "TEST_COMMAND=" "$log_file" >/dev/null; then
        while [ $# -gt 0 ]; do
            case $1 in
            -c)
                shift
                if [ $# -gt 0 ]; then
                    printf 'TEST_COMMAND=%s\n' "$1"
                fi
                return 0
                ;;
            -c?*)
                printf 'TEST_COMMAND=%s\n' "${1#-c}"
                return 0
                ;;
            esac
            shift
        done
    fi
}

run_container_runner_dry_contract() {
    log_file="${CRAMTMP}/run-test-dry-contract.log"

    if run_container_runner_dry_raw "$@" >"$log_file" 2>&1; then
        print_run_test_dry_contract "$log_file" "$@"
    else
        cat "$log_file"
        return 1
    fi
}

run_container_runner_dry_fails_with() {
    expected=$1
    shift
    log_file="${CRAMTMP}/run-test-dry-failure.log"

    if run_container_runner_dry_raw "$@" >"$log_file" 2>&1; then
        cat "$log_file"
        printf 'expected failure containing: %s\n' "$expected"
        return 1
    fi

    if grep -F "$expected" "$log_file" >/dev/null; then
        printf '%s\n' "$expected"
    else
        cat "$log_file"
        return 1
    fi
}
