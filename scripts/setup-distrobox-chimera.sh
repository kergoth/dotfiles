#!/usr/bin/env bash
# Setup script for the Chimera Linux distrobox (ubuntu:22.04 container).
# Run from the host via:
#   distrobox enter ubuntu -- bash "$HOME/.dotfiles/scripts/setup-distrobox-chimera.sh"
# Or run directly inside the container for iteration/debugging.

set -euo pipefail

arch=$(dpkg --print-architecture)   # amd64 or arm64

# ---------------------------------------------------------------------------
# Base packages
# ---------------------------------------------------------------------------
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    curl wget ca-certificates gpg xdg-utils nvi

# ---------------------------------------------------------------------------
# Vivaldi (apt repo supports both amd64 and arm64)
# ---------------------------------------------------------------------------
if ! command -v vivaldi-stable >/dev/null 2>&1; then
    wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub \
        | gpg --dearmor \
        | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg status=none
    echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=${arch}] \
https://repo.vivaldi.com/archive/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/vivaldi-archive.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y vivaldi-stable
fi

# ---------------------------------------------------------------------------
# 1Password (apt repo: amd64 only; tarball: arm64)
# Validated: tarball extracts to /opt/1password-<version>, then is moved to /opt/1Password/.
# after-install.sh is at /opt/1Password/after-install.sh
# ---------------------------------------------------------------------------
if ! command -v 1password >/dev/null 2>&1 && [ ! -d /opt/1Password ]; then
    if [ "$arch" = "amd64" ]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc \
            | gpg --dearmor \
            | sudo dd of=/usr/share/keyrings/1password-archive-keyring.gpg status=none
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
https://downloads.1password.com/linux/debian/amd64 stable main" \
            | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y 1password
    else
        # arm64: official apt feed is amd64-only; use tarball
        curl -fsSL "https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz" \
            | sudo tar -xz -C /opt
        sudo mkdir -p /usr/share/desktop-directories
        sudo mkdir -p /opt/1Password
        sudo mv /opt/1password-*/* /opt/1Password
        sudo /opt/1Password/after-install.sh
    fi
fi

# ---------------------------------------------------------------------------
# 1Password browser integration: allow Vivaldi
# Validated: Vivaldi binary is at /usr/bin/vivaldi-stable
# ---------------------------------------------------------------------------
if [ -d /opt/1Password ] || command -v 1password >/dev/null 2>&1; then
    sudo mkdir -p /etc/1password
    if ! grep -qFx "vivaldi-bin" /etc/1password/custom_allowed_browsers 2>/dev/null; then
        echo "vivaldi-bin" | sudo tee -a /etc/1password/custom_allowed_browsers >/dev/null
    fi
fi

# ---------------------------------------------------------------------------
# Zed (curl installer works in glibc ubuntu)
# Validated: installer creates ~/.local/share/applications/dev.zed.Zed.desktop
# Since $HOME is shared, this lands on the host — but the Exec= points to a
# glibc binary that will fail on the musl host. Export first (reads the
# original .desktop), then remove the original so the host doesn't try to run
# the glibc binary directly. The exported ubuntu-dev.zed.Zed.desktop wraps
# execution via distrobox-enter.
# ---------------------------------------------------------------------------
zed_desktop="$HOME/.local/share/applications/dev.zed.Zed.desktop"
if ! command -v zed >/dev/null 2>&1 || [ ! -f "$zed_desktop" ]; then
    curl -fsSL https://zed.dev/install.sh | sh
fi

# ---------------------------------------------------------------------------
# Export .desktop files to host launcher
# distrobox-export creates ubuntu-<appname>.desktop in ~/.local/share/applications/
# ---------------------------------------------------------------------------
if ! distrobox-export --app vivaldi-stable; then
    echo >&2 "Error: failed to export Vivaldi"
    exit 1
fi

if ! distrobox-export --app 1password; then
    echo >&2 "Error: failed to export 1Password"
    exit 1
fi

# Zed: export first (reads dev.zed.Zed.desktop), then remove the original
# so only the distrobox-wrapped ubuntu-dev.zed.Zed.desktop remains on the host
if distrobox-export --app "$zed_desktop"; then
    rm -f "$zed_desktop"
else
    echo >&2 "Error: failed to export Zed"
    exit 1
fi

# Export Zed CLI wrapper only when the host binary is the default installer symlink.
zed_bin="$HOME/.local/bin/zed"
zed_app_bin="$HOME/.local/zed.app/bin/zed"
if [ -L "$zed_bin" ] && [ "$(readlink "$zed_bin")" = "$zed_app_bin" ] && [ -x "$zed_app_bin" ]; then
    rm -f "$zed_bin"
    if ! distrobox-export -b "$zed_app_bin"; then
        echo >&2 "Error: failed to export Zed CLI"
        exit 1
    fi
fi

echo "Distrobox setup complete."
