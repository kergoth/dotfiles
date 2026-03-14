#!/bin/sh

set -e
if [ "${RUN_TEST_TRACE:-0}" -eq 1 ]; then
    set -x
fi

: "${TEST_DOTFILES_DIR:?}"
: "${TEST_DISTRO:?}"
: "${TEST_USER:?}"
: "${TEST_UID:?}"
: "${TEST_SETUP_MODE:?}"
: "${TEST_ACTION:?}"

dotfiles_dir="$TEST_DOTFILES_DIR"
test_distro="$TEST_DISTRO"
test_user="$TEST_USER"
test_uid="$TEST_UID"
test_setup_mode="$TEST_SETUP_MODE"
test_action="$TEST_ACTION"
test_command="${TEST_COMMAND:-}"
host_gnupg_dir="${HOST_GNUPG_DIR:-/run/host-gnupg}"
user_gnupg=""

cd "$dotfiles_dir"

if [ -e /mounts/.codex/auth.json ] && ! [ -e "/home/$test_user/.codex/auth.json" ]; then
    mkdir -p "/home/$test_user/.codex"
    rm -f "/home/$test_user/.codex/auth.json"
    ln -s /mounts/.codex/auth.json "/home/$test_user/.codex/auth.json"
fi

xdg_runtime_dir="/tmp/xdg-$test_user"
mkdir -p "$xdg_runtime_dir"
chmod 700 "$xdg_runtime_dir"

"script/$test_distro/setup-root" "$test_user" "$test_uid" </dev/null
age_key_path="/home/$test_user/.config/chezmoi/age.key"
if [ -e "$age_key_path" ]; then
    find "/home/$test_user" -path "$age_key_path" -prune -o -exec chown -h "$test_user" {} +
else
    chown -hR "$test_user" "/home/$test_user"
fi

chown "$test_user" "$xdg_runtime_dir"

if [ -d /nix ]; then
    if ! [ -w /nix/store ] || ! [ -w /nix/var ]; then
        chown -R "$test_user" /nix
    fi
fi

if [ "${DOTFILES_TEST_GNUPG:-0}" -eq 1 ] || [ -n "${HOST_GNUPG_DIR:-}" ]; then
    if [ -d "$host_gnupg_dir" ]; then
        rm -rf "/home/$test_user/.gnupg"
        cp -a "$host_gnupg_dir" "/home/$test_user/.gnupg" 2>/dev/null || :
        chown -hR "$test_user" "/home/$test_user/.gnupg"
        user_gnupg="/home/$test_user/.gnupg"
    else
        echo "Error: host GNUPGHOME not found at $host_gnupg_dir" >&2
        exit 1
    fi
fi

if [ -n "$user_gnupg" ]; then
    GNUPGHOME="$user_gnupg"
fi

if [ -S /run/dbus/system_bus_socket ]; then
    :
elif command -v dbus-daemon >/dev/null 2>&1; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork --nopidfile
fi

user_script="/tmp/run-test-user"
cat >"$user_script" <<'EOF'
#!/bin/sh
set -e
if [ "${RUN_TEST_TRACE:-0}" -eq 1 ]; then
    set -x
fi

export DOTFILES_DIR="${DOTFILES_DIR:-$TEST_DOTFILES_DIR}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"
export CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-}"
export DOTFILES_EPHEMERAL="${DOTFILES_EPHEMERAL:-}"
export DOTFILES_HEADLESS="${DOTFILES_HEADLESS:-}"
export DOTFILES_SECRETS="${DOTFILES_SECRETS:-}"
export DOTFILES_SKIP_GPG_SECRET_IMPORT="${DOTFILES_SKIP_GPG_SECRET_IMPORT:-}"
export DOTFILES_PERSONAL="${DOTFILES_PERSONAL:-}"
export DOTFILES_WORK="${DOTFILES_WORK:-}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
export GNUPGHOME="${GNUPGHOME:-}"

cd "$DOTFILES_DIR"

# Re-exec under a session bus if we don't have one yet.
if [ "${1:-}" != "--in-session" ] && [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if command -v dbus-run-session >/dev/null 2>&1; then
        exec dbus-run-session -- "$0" --in-session
    elif command -v dbus-daemon >/dev/null 2>&1; then
        dbus_address=$(dbus-daemon --session --fork --print-address)
        export DBUS_SESSION_BUS_ADDRESS="$dbus_address"
    fi
fi

case "$TEST_SETUP_MODE" in
    root-only)
        ;;
    user-only)
        if [ "${RUN_TEST_TRACE:-0}" -eq 1 ]; then
            bash -x ./script/setup </dev/null
        else
            ./script/setup </dev/null
        fi
        ;;
    full)
        if [ "${RUN_TEST_TRACE:-0}" -eq 1 ]; then
            bash -x ./script/setup-full </dev/null
        else
            ./script/setup-full </dev/null
        fi
        ;;
    *)
        echo "Error: unknown TEST_SETUP_MODE: $TEST_SETUP_MODE" >&2
        exit 1
        ;;
esac

case "$TEST_ACTION" in
    run)
        ;;
    shell)
        exec zsh --login
        ;;
    command)
        exec sh -lc "$TEST_COMMAND"
        ;;
    *)
        echo "Error: unknown TEST_ACTION: $TEST_ACTION" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$user_script"

sh_quote() {
    printf "%s" "$1" | sed "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
}

env_cmd="env RUN_TEST_TRACE=$(sh_quote "${RUN_TEST_TRACE:-0}")"
env_cmd="$env_cmd TEST_DOTFILES_DIR=$(sh_quote "$dotfiles_dir")"
env_cmd="$env_cmd TEST_SETUP_MODE=$(sh_quote "$test_setup_mode")"
env_cmd="$env_cmd TEST_ACTION=$(sh_quote "$test_action")"
env_cmd="$env_cmd DOTFILES_DIR=$(sh_quote "$dotfiles_dir")"
env_cmd="$env_cmd GITHUB_TOKEN=$(sh_quote "${GITHUB_TOKEN:-}")"
env_cmd="$env_cmd CLAUDE_CODE_OAUTH_TOKEN=$(sh_quote "${CLAUDE_CODE_OAUTH_TOKEN:-}")"
env_cmd="$env_cmd DOTFILES_EPHEMERAL=$(sh_quote "${DOTFILES_EPHEMERAL:-}")"
env_cmd="$env_cmd DOTFILES_HEADLESS=$(sh_quote "${DOTFILES_HEADLESS:-}")"
env_cmd="$env_cmd DOTFILES_SECRETS=$(sh_quote "${DOTFILES_SECRETS:-}")"
env_cmd="$env_cmd DOTFILES_SKIP_GPG_SECRET_IMPORT=$(sh_quote "${DOTFILES_SKIP_GPG_SECRET_IMPORT:-}")"
env_cmd="$env_cmd DOTFILES_PERSONAL=$(sh_quote "${DOTFILES_PERSONAL:-}")"
env_cmd="$env_cmd DOTFILES_WORK=$(sh_quote "${DOTFILES_WORK:-}")"
env_cmd="$env_cmd XDG_RUNTIME_DIR=$(sh_quote "$xdg_runtime_dir")"
env_cmd="$env_cmd GNUPGHOME=$(sh_quote "${GNUPGHOME:-}")"
env_cmd="$env_cmd TEST_COMMAND=$(sh_quote "$test_command")"

ret=0

if command -v doas >/dev/null 2>&1; then
    doas -u "$test_user" sh -c "$env_cmd sh $(sh_quote "$user_script")" || ret=$?
elif command -v su >/dev/null 2>&1; then
    su - "$test_user" -c "$env_cmd sh $(sh_quote "$user_script")" || ret=$?
else
    echo "Error: need su or doas in container to run as user" >&2
    exit 1
fi

if [ "$ret" -eq 0 ]; then
    echo >&2 "Test completed for distro: $test_distro"
else
    echo >&2 "Setup failed for distro: $test_distro (status $ret)"
fi

exit "$ret"
