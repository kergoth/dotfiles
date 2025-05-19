#!/usr/bin/env bash

NIXPKGS=${NIXPKGS:-https://nixos.org/channels/nixpkgs-unstable}
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$HOME/.brew}
export HOMEBREW_PREFIX
PATH="$HOMEBREW_PREFIX/bin:$XDG_DATA_HOME/../bin:$HOME/.nix-profile/bin:$PATH"
OSX_ADMIN_LOGNAME="${OSX_ADMIN_LOGNAME-admin}"
HOMEBREW_ADMIN_PREFIX="${HOMEBREW_ADMIN_PREFIX:-/Users/Shared/homebrew}"

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

brewfile_install() {
    local brewfile="$1"
    if [ -f "$brewfile" ]; then
        run "$HOMEBREW_PREFIX/bin/brew" bundle --no-upgrade install --file="$brewfile"
    elif [ -f "$brewfile.tmpl" ]; then
        cat "$brewfile.tmpl" | chezmoi execute-template | run "$HOMEBREW_PREFIX/bin/brew" bundle --no-upgrade install --file=-
    else
        msg "No $brewfile found"
        return 1
    fi
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

NIXPKGS=${NIXPKGS:-https://nixos.org/channels/nixpkgs-unstable}

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
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm --init none
        fi
    else
        if ! has nix; then
            curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
        fi
    fi
}
