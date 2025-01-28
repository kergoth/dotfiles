#!/usr/bin/env bash

NIXPKGS=${NIXPKGS:-https://nixos.org/channels/nixpkgs-unstable}
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$HOME/.brew}
export HOMEBREW_PREFIX
PATH="$HOMEBREW_PREFIX/bin:$XDG_DATA_HOME/../bin:$HOME/.nix-profile/bin:$PATH"

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

need_sudo() {
    if [ "$(id -u)" != "0" ]; then
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

NIXPKGS=${NIXPKGS:-https://nixos.org/channels/nixpkgs-unstable}

install_nix() {
    if [ "$OSTYPE" = WSL ]; then
        if ! has nix-env; then
            curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
        fi
    elif [ "$OS" = arch ]; then
        if ! has nix-env; then
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
        if ! has nix-env; then
            curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
        fi
    else
        if ! has nix-env; then
            curl -L https://nixos.org/nix/install | sh -s -- --daemon
        fi
    fi

    setup_nix_shell

    if [ -n "$NIXPKGS" ]; then
        nix-channel --add "$NIXPKGS" nixpkgs
        nix-channel --update
    fi
}

setup_nix_shell() {
    # shellcheck disable=SC1090
    for i in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ~/.nix-profile/etc/profile.d/nix-daemon.sh ~/.nix-profile/etc/profile.d/nix.sh; do
        if [ -e "$i" ]; then
            . "$i"
        fi
    done
}

setup_nix_shell
