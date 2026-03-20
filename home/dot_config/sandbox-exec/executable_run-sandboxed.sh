#!/usr/bin/env bash
# Usage: run-sandboxed.sh [options] command [args...]
#
# Generate a launch-specific sandbox policy from the durable base profile,
# append concrete workdir and git-worktree grants, then execute the command.
#
# Options:
#     --workdir PATH           Use PATH as the selected workdir instead of pwd -P
#     --add-ro PATH            Append a read-only path grant (repeatable)
#     --add-rw PATH            Append a read/write path grant (repeatable)
#     --append-profile PATH    Append a profile fragment after dynamic grants
#     --keychain               Append the local keychain profile
#     -v                       Increase verbosity
#     -h                       Show this help message

set -euo pipefail

scriptname=${BASH_SOURCE[0]##*/}
base_policy="${HOME}/.config/sandbox-exec/agent.sb"
keychain_profile="${HOME}/.config/sandbox-exec/keychain.sb"
tmpdir=
workdir=
verbosity=0
command_args=()
append_profiles=()
extra_ro_paths=()
extra_rw_paths=()

usage() {
    sed -n '/^# Usage:/,/^#     -h /p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

msg() {
    local fmt=$1

    shift || true
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@" >&2
}

msg_verbose() {
    if [ "${verbosity}" -gt 0 ]; then
        msg "$@"
    fi
}

die() {
    msg "%s: %s" "${scriptname}" "$1"
    exit 1
}

cleanup() {
    if [ -n "${tmpdir:-}" ] && [ -d "${tmpdir}" ]; then
        rm -rf -- "${tmpdir}"
    fi
}

process_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --workdir=*)
                workdir=${1#--workdir=}
                shift
                ;;
            --workdir)
                [ $# -ge 2 ] || die "missing value for --workdir"
                workdir=$2
                shift 2
                ;;
            --append-profile=*)
                append_profiles+=("${1#--append-profile=}")
                shift
                ;;
            --append-profile)
                [ $# -ge 2 ] || die "missing value for --append-profile"
                append_profiles+=("$2")
                shift 2
                ;;
            --add-ro=*)
                extra_ro_paths+=("${1#--add-ro=}")
                shift
                ;;
            --add-ro)
                [ $# -ge 2 ] || die "missing value for --add-ro"
                extra_ro_paths+=("$2")
                shift 2
                ;;
            --add-rw=*)
                extra_rw_paths+=("${1#--add-rw=}")
                shift
                ;;
            --add-rw)
                [ $# -ge 2 ] || die "missing value for --add-rw"
                extra_rw_paths+=("$2")
                shift 2
                ;;
            --keychain)
                append_profiles+=("${keychain_profile}")
                shift
                ;;
            -v)
                verbosity=$((verbosity + 1))
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    [ $# -gt 0 ] || die "missing command"
    command_args=("$@")
}

resolve_dir() {
    local path=$1

    [ -d "$path" ] || die "directory does not exist: $path"
    (
        cd "$path"
        pwd -P
    )
}

resolve_existing_path() {
    local path=$1
    local dir
    local base

    [ -e "$path" ] || die "path does not exist: $path"

    if [ -d "$path" ]; then
        resolve_dir "$path"
        return 0
    fi

    dir=$(cd "$(dirname "$path")" && pwd -P)
    base=${path##*/}
    printf '%s/%s\n' "$dir" "$base"
}

resolve_user_path() {
    local raw_path=$1
    local candidate

    case "$raw_path" in
        /*)
            candidate=$raw_path
            ;;
        *)
            candidate="$(pwd -P)/$raw_path"
            ;;
    esac

    resolve_existing_path "$candidate"
}

emit_path_ancestor_literals() {
    local path=$1
    local label=$2
    local current=
    local trimmed
    local part

    cat <<EOF
;; Generated ancestor directory literals for ${label}: ${path}
;;
;; Why file-read* with literal:
;; Keep ancestor access narrow while still allowing directory traversal and
;; readdir() on the path chain, following Safehouse's render-time behavior.
(allow file-read*
    (literal "/")
EOF

    trimmed=${path#/}
    IFS='/' read -r -a parts <<< "${trimmed}"
    for part in "${parts[@]}"; do
        [ -n "$part" ] || continue
        current="${current}/${part}"
        printf '    (literal "%s")\n' "$current"
    done

    printf ')\n\n'
}

emit_ro_grant() {
    local path=$1
    local label=$2

    emit_path_ancestor_literals "$path" "$label"
    if [ -d "$path" ]; then
        printf '(allow file-read* (subpath "%s"))\n\n' "$path"
    else
        printf '(allow file-read* (literal "%s"))\n\n' "$path"
    fi
}

emit_rw_grant() {
    local path=$1
    local label=$2

    emit_path_ancestor_literals "$path" "$label"
    if [ -d "$path" ]; then
        printf '(allow file-read* file-write* (subpath "%s"))\n\n' "$path"
    else
        printf '(allow file-read* file-write* (literal "%s"))\n\n' "$path"
    fi
}

git_is_worktree_root() {
    local path=$1
    local top

    top=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || true)
    [ -n "$top" ] || return 1
    [ "$(resolve_dir "$top")" = "$path" ]
}

emit_linked_worktree_grants() {
    local selected=$1
    local line
    local sibling

    if ! git_is_worktree_root "$selected"; then
        return 0
    fi

    while IFS= read -r line; do
        case "$line" in
            worktree\ *)
                sibling=${line#worktree }
                sibling=$(resolve_dir "$sibling")
                if [ "$sibling" != "$selected" ]; then
                    printf ';; Safehouse-style linked worktree snapshot: %s\n' "$sibling"
                    emit_ro_grant "$sibling" "linked git worktree"
                fi
                ;;
        esac
    done < <(git -C "$selected" worktree list --porcelain 2>/dev/null || true)
}

emit_worktree_common_dir_grant() {
    local selected=$1
    local git_dir
    local common_dir

    if ! git_is_worktree_root "$selected"; then
        return 0
    fi

    git_dir=$(git -C "$selected" rev-parse --git-dir 2>/dev/null || true)
    common_dir=$(git -C "$selected" rev-parse --git-common-dir 2>/dev/null || true)

    [ -n "$git_dir" ] || return 0
    [ -n "$common_dir" ] || return 0

    git_dir=$(resolve_existing_path "$selected/$git_dir")
    common_dir=$(resolve_existing_path "$selected/$common_dir")

    case "$common_dir" in
        "$selected"/*)
            return 0
            ;;
    esac

    printf ';; Safehouse-style linked worktree common-dir grant: %s\n' "$common_dir"
    emit_rw_grant "$common_dir" "git worktree common dir"
}

append_optional_profiles() {
    local profile

    for profile in "${append_profiles[@]}"; do
        profile=$(resolve_existing_path "$profile")
        printf ';; Appended profile: %s\n\n' "$profile"
        cat "$profile"
        printf '\n'
    done
}

append_extra_path_grants() {
    local path

    for path in "${extra_ro_paths[@]}"; do
        path=$(resolve_user_path "$path")
        printf ';; Appended extra read-only path: %s\n' "$path"
        emit_ro_grant "$path" "extra read-only path"
    done

    for path in "${extra_rw_paths[@]}"; do
        path=$(resolve_user_path "$path")
        printf ';; Appended extra read/write path: %s\n' "$path"
        emit_rw_grant "$path" "extra read/write path"
    done
}

main() {
    local effective_workdir
    local policy_file

    process_arguments "$@"

    [ -f "$base_policy" ] || die "base policy not found: $base_policy"

    if [ -n "${workdir:-}" ]; then
        effective_workdir=$(resolve_dir "$workdir")
    else
        effective_workdir=$(pwd -P)
    fi

    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/agent-sandbox.XXXXXX")
    trap cleanup EXIT

    policy_file="${tmpdir}/policy.sb"
    cp "$base_policy" "$policy_file"

    {
        printf '\n'
        printf ';; ---------------------------------------------------------------------------\n'
        printf ';; Launch-Time Dynamic Grants\n'
        printf ';; Selected workdir: %s\n' "$effective_workdir"
        printf ';; ---------------------------------------------------------------------------\n\n'
        emit_rw_grant "$effective_workdir" "selected workdir"
        emit_linked_worktree_grants "$effective_workdir"
        emit_worktree_common_dir_grant "$effective_workdir"
        append_extra_path_grants
        append_optional_profiles
    } >> "$policy_file"

    msg_verbose "policy: %s" "$policy_file"
    msg_verbose "workdir: %s" "$effective_workdir"

    exec sandbox-exec -f "$policy_file" -- "${command_args[@]}"
}

main "$@"
