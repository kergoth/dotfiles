#!/usr/bin/env bash

export NIXPKGS=${NIXPKGS:-https://nixos.org/channels/nixpkgs-unstable}
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$HOME/.brew}
export PATH="$HOMEBREW_PREFIX/bin:$XDG_DATA_HOME/../bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
OSX_ADMIN_LOGNAME="${OSX_ADMIN_LOGNAME-admin}"
HOMEBREW_ADMIN_PREFIX="${HOMEBREW_ADMIN_PREFIX:-/Users/Shared/homebrew}"
USER="${USER:-${LOGNAME:-$(whoami)}}"

has() {
    command -v "$@" >/dev/null 2>&1
}

printcmd() {
    python3 -c 'import subprocess,sys; print(subprocess.list2cmdline(sys.argv[1:]))' "$@"
}

run() {
    if has python3; then
        printf '❯ %s\n' "$(printcmd "$@")" >&2
    else
        printf '❯ %s\n' "$*" >&2
    fi
    "$@"
}

brewfile_cat() {
    local brewfile="$1"
    if echo "$brewfile" | grep -Fqx "-"; then
        cat
    elif [ -f "$brewfile.tmpl.age" ] || echo "$brewfile" | grep -q "\.tmpl.age$"; then
        cat "${brewfile%.tmpl.age}.tmpl.age" | chezmoi decrypt | chezmoi execute-template
    elif [ -f "$brewfile.tmpl" ] || echo "$brewfile" | grep -q "\.tmpl$"; then
        cat "${brewfile%.tmpl}.tmpl" | chezmoi execute-template
    elif [ -f "$brewfile.age" ] || echo "$brewfile" | grep -q "\.age$"; then
        cat "${brewfile%.age}.age" | chezmoi decrypt
    elif [ -f "$brewfile" ]; then
        cat "$brewfile"
    else
        msg_red "Brewfile $brewfile not found"
        return 1
    fi
}

is_mas_signed_in() {
    if ! command -v mas >/dev/null 2>&1; then
        return 1
    fi
    mas list >/dev/null 2>&1
}

brewfile_install() {
    local brewfile="$1"
    local brewfile_content
    brewfile_content=$(brewfile_cat "$brewfile")

    local mas_count
    mas_count=$(echo "$brewfile_content" | grep -c '^mas ' || true)

    if [ "$mas_count" -gt 0 ]; then
        if ! command -v mas >/dev/null 2>&1; then
            msg "Warning: mas CLI not installed, skipping $mas_count App Store app(s)"
            msg "Install mas with 'brew install mas' and re-run setup"
            brewfile_content=$(echo "$brewfile_content" | grep -v '^mas ')
        elif ! is_mas_signed_in; then
            msg "Warning: Not signed into App Store, skipping $mas_count App Store app(s)"
            msg "Sign in via the App Store app and re-run setup"
            brewfile_content=$(echo "$brewfile_content" | grep -v '^mas ')
        fi
    fi

    echo "$brewfile_content" | run "$HOMEBREW_PREFIX/bin/brew" bundle --no-upgrade install --file=-
}

check_child_script() {
    local script="$1"
    if command -v "$script" &>/dev/null; then
        command -v "$script"
    elif command -v "$script.tmpl" &>/dev/null; then
        command -v "$script.tmpl"
    else
        return 1
    fi
}

run_child_script() {
    local script
    if script=$(check_child_script "$1"); then
        msg "Running $script"
        "$script"
    else
        msg "No $script script found"
    fi
}

# shellcheck disable=SC3028,SC2034
case "${OSTYPE:-}" in
darwin*)
    DISTRO=
    DISTRO_LIKE=
    OS=macos
    ;;
*)
    case "$(uname -r)" in
    *Microsoft | *microsoft*)
        OSTYPE=WSL
        ;;
    esac

    if [ -f /etc/os-release ]; then
        DISTRO="$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')"
        DISTRO_LIKE="$(. /etc/os-release && echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
    else
        DISTRO=
        DISTRO_LIKE=
    fi
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ;;
esac

is_mac() {
    [ "$OS" = macos ]
}

is_freebsd() {
    [ "$OS" = freebsd ]
}

# Check if a macOS app is running by process name
app_is_running() {
    local app_name="$1"
    local count
    count=$(osascript -e "tell application \"System Events\" to count (every process whose name is \"$app_name\")") 2>/dev/null || return 1
    [ "$count" -gt 0 ]
}

# Open an app only if not already running
# Usage: open_if_not_running "AppName" [process_name_to_check]
open_if_not_running() {
    local target="$1"
    local check_app="${2:-}"
    local app_name

    if [[ "$target" == *.app || "$target" == */*.app ]]; then
        app_name=$(basename "$target" .app)
    else
        app_name="$target"
    fi

    if [ -z "$check_app" ]; then
        check_app="$app_name"
    fi

    if ! app_is_running "$check_app"; then
        if [[ "$target" == /* ]]; then
            # Absolute path - open directly
            open -g -j "$target"
        else
            # App name - use -a flag
            open -g -j -a "$target"
        fi
    fi
}

if [ "$(id -u)" != "0" ]; then
    if has doas; then
        SUDO="doas "
    else
        SUDO="sudo "
    fi
else
    SUDO=
fi

msg() {
    fmt="$1"
    if [ $# -gt 1 ]; then
        shift
    fi
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@" >&2
}

die() {
    msg "$@"
    exit 1
}

SUDO_CHECKED=

need_sudo() {
    if [ "$(id -u)" != "0" ] && [ -z "$SUDO_CHECKED" ]; then
        SUDO_CHECKED=1
        if is_freebsd; then
            if has doas && [ -e /usr/local/etc/doas.conf ] && [ "$(doas -C /usr/local/etc/doas.conf pkg)" = permit ]; then
                return 0
            else
                die "Error: please run as root, or as a user that can run doas."
            fi
        elif has doas; then
            if ! doas true; then
                die "Error: please run as root, or as a user that can run doas."
            fi
        else
            msg "Running sudo, you may be prompted for your password."
            if ! sudo -v; then
                die "Error: please run as root, or as a user that can run sudo."
            else
                # Keep-alive: update existing `sudo` time stamp until finished
                while true; do
                    sudo -n true
                    sleep 60
                    kill -0 "$$" || exit
                done 2>/dev/null &
            fi
        fi
    fi
}

sudorun() {
    command $SUDO "$@"
}

pacman() {
    sudorun pacman --noconfirm --needed "$@"
}

pacman_install() {
    # shellcheck disable=SC2086
    for arg; do
        if ! pacman -Q "$arg" >/dev/null 2>&1; then
            echo "$arg"
        fi
    done | xargs $SUDO pacman --noconfirm --needed -S
}

admindo() {
    if [ -n "$OSX_ADMIN_LOGNAME" ]; then
        if [ "$LOGNAME" = "$OSX_ADMIN_LOGNAME" ]; then
            command "$@"
        else
            surun "$OSX_ADMIN_LOGNAME" "$@"
        fi
    fi
}

surun() {
    local username="$1"
    shift

    args="$(printcmd "$@")"
    echo >&2 "Running '$args' as $username, input $username's password"
    su - "$username" -c "cd $(printcmd "$PWD") && $args"
}

uvs=
uv_check() {
    pkg="$1"
    cmd="${2:-}"

    if [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    uvs="$uvs $pkg"
}

uvs_install() {
    if [ -n "$(echo "$uvs" | sed -e 's/^ *//; s/ *$//')" ]; then
        msg "Installing via uv: $uvs"
        echo "$uvs" | tr ' ' '\n' | sort -u | tr '\n' '\0' | xargs -0 --no-run-if-empty -o -n 1 uv tool install
    fi
}

cargos=
cargo_check() {
    pkg="$1"
    cmd="${2:-}"

    if [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    cargos="$cargos $pkg"
}

cargos_install() {
    if [ -n "$(echo "$cargos" | sed -e 's/^ *//; s/ *$//')" ]; then
        msg "Installing via cargo: $cargos"
        echo "$cargos" | tr ' ' '\n' | sort -u | tr '\n' '\0' | xargs -0 --no-run-if-empty -o cargo install --locked
    fi
}

gos=
go_check() {
    pkg="$1"
    cmd="${2:-}"

    if [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    gos="$gos $pkg"
}

gos_install() {
    if [ -n "$(echo "$gos" | sed -e 's/^ *//; s/ *$//')" ]; then
        msg "Installing via go: $gos"
        echo "$gos" | tr ' ' '\n' | sort -u | tr '\n' '\0' | xargs -0 --no-run-if-empty -o go install
    fi
}

eget_install() {
    local repo="$1"
    shift
    local cmd="${1:-$(basename "$repo")}"
    shift

    if [ ! -e "$HOME/.local/bin/$cmd" ]; then
        echo >&2 "Installing $cmd via $repo"
        if eget -a '^gnu' --to="$tmpdir/$cmd" "$@" "$repo"; then
            mv "$tmpdir/$cmd" "$HOME/.local/bin/$cmd"
        else
            echo >&2 "Error downloading and installing $cmd via $repo"
            return 1
        fi
    fi
}

install_nix() {
    if [ "$OSTYPE" = WSL ]; then
        if ! has nix; then
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
        fi
    elif [ "$DISTRO" = arch ]; then
        if ! has nix; then
            pacman -S nix
        fi

        if ! grep -q "^nix-users:.*$USER" /etc/group; then
            sudorun sed -i -e "/^nix-users:/s/\$/ $USER/; /^nix-users:/s/: /:/;" /etc/group
            if ! grep -q "^nix-users:.*$USER" /etc/group; then
                echo >&2 "Failed to add user to the nix-users group, please do so manually, then re-login"
            else
                echo >&2 "User has been added to the nix-users group, please re-login"
            fi
        fi

        sudorun systemctl enable nix-daemon
        sudorun systemctl start nix-daemon
    elif uname -n | grep -qF lima; then
        if ! has nix; then
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm -- --init none
        fi
    else
        if ! has nix; then
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
        fi
    fi
}

devpod_configure() {
    local dotfiles_url="${1:?dotfiles_url required}"
    local dotfiles_script="${2:?dotfiles_script required}"
    local ssh_config_path="${3:?ssh_config_path required}"
    local provider_name="${4:-docker}"
    local default_ide="${5:-}"

    if ! has devpod; then
        msg "devpod not found, skipping DevPod configuration"
        return 0
    fi

    if ! has jq; then
        msg "jq not found, skipping DevPod configuration"
        return 0
    fi

    msg "Configuring DevPod"

    local providers_json
    providers_json="$(devpod provider list --output json 2>/dev/null || true)"

    if [ -z "$providers_json" ]; then
        msg "Warning: Unable to read DevPod provider list, skipping provider configuration"
        return 0
    fi

    if ! jq -e --arg name "$provider_name" 'has($name)' >/dev/null <<<"$providers_json"; then
        msg "Adding DevPod provider '$provider_name'"
        devpod provider add "$provider_name" >/dev/null 2>&1 || {
            msg "Warning: Failed to add DevPod provider '$provider_name'"
            return 0
        }
        providers_json="$(devpod provider list --output json 2>/dev/null || true)"
    fi

    if ! jq -e --arg name "$provider_name" '.[$name].default == true' >/dev/null <<<"$providers_json"; then
        msg "Setting DevPod default provider to '$provider_name'"
        devpod provider use "$provider_name" >/dev/null 2>&1 || true
    fi

    devpod context set-options \
        -o "DOTFILES_URL=$dotfiles_url" \
        -o "DOTFILES_SCRIPT=$dotfiles_script" \
        -o "GPG_AGENT_FORWARDING=false" \
        -o "SSH_CONFIG_PATH=$ssh_config_path" \
        -o "SSH_INJECT_GIT_CREDENTIALS=true" \
        >/dev/null 2>&1 || msg "Warning: Failed to set some DevPod context options"

    if [ -n "$default_ide" ]; then
        msg "Setting DevPod default IDE to '$default_ide'"
        devpod ide use "$default_ide" >/dev/null 2>&1 || \
            msg "Warning: Failed to set DevPod default IDE to '$default_ide'"
    fi
}
