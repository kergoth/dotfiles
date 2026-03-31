#!/usr/bin/env bash
# Setup script for FreeBSD linuxulator: Ubuntu Jammy chroot for glibc GUI apps.
#
# Installs 1Password and Vivaldi into /compat/ubuntu, creates host starter
# scripts that run Linux ELF binaries directly via the linuxulator (no chroot(8)
# needed — the kernel handles ELF execution transparently as the current user),
# and configures the Linux mount tree via /etc/fstab.
#
# Run as a non-root user with doas available:
#   bash ~/.dotfiles/scripts/setup-linuxulator-freebsd.sh
#
# Must be run on FreeBSD 14+. Tested with KDE Plasma desktop.
# See docs/implemented/2026-03-29-freebsd-linuxulator-hardening.md for the
# comparison between this approach and the Chimera distrobox pattern.

set -euo pipefail

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=./common.sh
. "$scriptdir/common.sh" || exit 1

ensure_sysctl_conf_setting()
{
    local key=$1
    local value=$2

    if doas test -f /etc/sysctl.conf \
        && doas grep -qE "^${key}=" /etc/sysctl.conf; then
        doas sed -i '' -E "s|^${key}=.*|${key}=${value}|" /etc/sysctl.conf
    else
        printf '%s=%s\n' "$key" "$value" | doas tee -a /etc/sysctl.conf >/dev/null
    fi
}

ensure_fstab_entry()
{
    local entry=$1

    if ! doas grep -qF "$entry" /etc/fstab; then
        printf '%s\n' "$entry" | doas tee -a /etc/fstab >/dev/null
    fi
}

main()
{
    local arch linux_libdir op_chroot_bin
    local machine
    machine=$(uname -m)
    case "$machine" in
        amd64|x86_64)
            arch=amd64
            linux_libdir=/compat/ubuntu/usr/lib/x86_64-linux-gnu
            ;;
        arm64|aarch64)
            arch=arm64
            linux_libdir=/compat/ubuntu/usr/lib/aarch64-linux-gnu
            ;;
        *)
            die "Unsupported architecture: $machine"
            ;;
    esac

    msg "Architecture: $arch"

    msg "Phase 1: Enabling linuxulator"

    ensure_sysctl_conf_setting compat.linux.emul_path /compat/ubuntu
    doas sysrc linux_enable=YES
    doas kldload -nq linux || true
    doas kldload -nq linux64 || true
    doas sysctl compat.linux.emul_path=/compat/ubuntu
    doas sysctl kern.elf32.fallback_brand=3 || true
    doas sysctl kern.elf64.fallback_brand=3 || true

    msg "Phase 2: Bootstrapping Ubuntu Jammy"

    if ! has debootstrap; then
        msg "Installing debootstrap"
        doas env ASSUME_ALWAYS_YES=YES pkg install debootstrap
    fi

    if [ ! -f /compat/ubuntu/.debootstrap-complete ]; then
        msg "Bootstrapping Ubuntu Jammy into /compat/ubuntu (this takes a while)"
        doas rm -rf /compat/ubuntu   # clean any partial install from a prior failed run
        doas debootstrap jammy /compat/ubuntu
        doas touch /compat/ubuntu/.debootstrap-complete
    else
        msg "Ubuntu chroot already bootstrapped, skipping debootstrap"
    fi

    msg "Phase 3: Configuring /compat/ubuntu mounts"

    ensure_fstab_entry "devfs           /compat/ubuntu/dev      devfs           rw,late                      0       0"
    ensure_fstab_entry "tmpfs           /compat/ubuntu/dev/shm  tmpfs           rw,late,size=1g,mode=1777    0       0"
    ensure_fstab_entry "fdescfs         /compat/ubuntu/dev/fd   fdescfs         rw,late,linrdlnk             0       0"
    ensure_fstab_entry "linprocfs       /compat/ubuntu/proc     linprocfs       rw,late                      0       0"
    ensure_fstab_entry "linsysfs        /compat/ubuntu/sys      linsysfs        rw,late                      0       0"
    ensure_fstab_entry "/tmp            /compat/ubuntu/tmp      nullfs          rw,late                      0       0"
    ensure_fstab_entry "/home           /compat/ubuntu/home     nullfs          rw,late                      0       0"

    doas mkdir -p \
        /compat/ubuntu/dev/shm \
        /compat/ubuntu/dev/fd \
        /compat/ubuntu/proc \
        /compat/ubuntu/sys \
        /compat/ubuntu/tmp \
        /compat/ubuntu/home

    doas service linux restart || doas service linux start || true
    doas mount -al || true   # mount newly added fstab entries; ignore already-mounted errors

    msg "Phase 4: Installing apps inside Ubuntu chroot"

    doas chroot /compat/ubuntu /bin/bash -s <<'CHROOT'
set -euo pipefail

arch=$(dpkg --print-architecture)   # amd64 or arm64

apt-get update -qq
apt-get install -y --no-install-recommends curl wget ca-certificates gpg xdg-utils

# Vivaldi (apt repo supports both amd64 and arm64)
if ! command -v vivaldi-stable >/dev/null 2>&1; then
    wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub \
        | gpg --dearmor \
        | dd of=/usr/share/keyrings/vivaldi-browser.gpg status=none
    echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=${arch}] \
https://repo.vivaldi.com/archive/deb/ stable main" \
        > /etc/apt/sources.list.d/vivaldi-archive.list
    apt-get update -qq
    apt-get install -y vivaldi-stable
fi

# 1Password: amd64 apt repo, arm64 tarball (same as setup-distrobox-chimera.sh)
if ! command -v 1password >/dev/null 2>&1 && [ ! -d /opt/1Password ]; then
    if [ "$arch" = "amd64" ]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc \
            | gpg --dearmor \
            | dd of=/usr/share/keyrings/1password-archive-keyring.gpg status=none
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
https://downloads.1password.com/linux/debian/amd64 stable main" \
            > /etc/apt/sources.list.d/1password.list
        apt-get update -qq
        apt-get install -y 1password
    else
        # arm64: official apt feed is amd64-only; use tarball
        curl -fsSL "https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz" \
            | tar -xz -C /opt
        mkdir -p /usr/share/desktop-directories /opt/1Password
        mv /opt/1password-*/* /opt/1Password
        /opt/1Password/after-install.sh
    fi
fi

# 1Password browser integration: allow Vivaldi
if [ -d /opt/1Password ] || command -v 1password >/dev/null 2>&1; then
    mkdir -p /etc/1password
    if ! grep -qFx "vivaldi-bin" /etc/1password/custom_allowed_browsers 2>/dev/null; then
        echo "vivaldi-bin" >> /etc/1password/custom_allowed_browsers
    fi
fi

ldconfig
CHROOT

    # The starter scripts exec Linux ELF binaries directly from the FreeBSD host
    # rather than via chroot(8). The linuxulator kernel layer handles ELF execution
    # transparently as the invoking user; LD_LIBRARY_PATH supplies the chroot libs.
    msg "Phase 5: Creating host starter scripts"

    if [ -d /compat/ubuntu/opt/1Password ]; then
        op_chroot_bin=/compat/ubuntu/opt/1Password/1password
    else
        op_chroot_bin=/compat/ubuntu/usr/bin/1password
    fi

    doas tee /usr/local/bin/vivaldi >/dev/null <<STARTER
#!/bin/sh
# Runs Vivaldi directly via linuxulator (no chroot(8) needed).
# Detects PulseAudio socket from sockstat(1) for audio support.
pulse_sock=\$(sockstat -u 2>/dev/null | awk -v u="\$(id -un)" '/pulseaudio.*native/ && \$1 == u {print \$NF; exit}')
[ -n "\$pulse_sock" ] && export PULSE_SERVER="unix:\$pulse_sock"
export LD_LIBRARY_PATH=${linux_libdir}:\${LD_LIBRARY_PATH:-}
export DISPLAY="\${DISPLAY:-:0}"
exec /compat/ubuntu/usr/bin/vivaldi-stable "\$@"
STARTER
    doas chmod 755 /usr/local/bin/vivaldi

    doas tee /usr/local/bin/1password >/dev/null <<STARTER
#!/bin/sh
# Runs 1Password directly via linuxulator (no chroot(8) needed).
# Detects PulseAudio socket from sockstat(1) for audio support.
pulse_sock=\$(sockstat -u 2>/dev/null | awk -v u="\$(id -un)" '/pulseaudio.*native/ && \$1 == u {print \$NF; exit}')
[ -n "\$pulse_sock" ] && export PULSE_SERVER="unix:\$pulse_sock"
export LD_LIBRARY_PATH=${linux_libdir}:\${LD_LIBRARY_PATH:-}
export DISPLAY="\${DISPLAY:-:0}"
exec $op_chroot_bin "\$@"
STARTER
    doas chmod 755 /usr/local/bin/1password

    msg "Phase 6: Installing .desktop files and icons"

    doas mkdir -p /usr/local/share/applications

    if [ -f /compat/ubuntu/usr/share/applications/vivaldi.desktop ]; then
        # Copy and rewrite Exec= to use the host wrapper
        doas sed -E \
            's|^(Exec=)[^ ]*|\1/usr/local/bin/vivaldi|' \
            /compat/ubuntu/usr/share/applications/vivaldi.desktop \
            | doas tee /usr/local/share/applications/vivaldi.desktop >/dev/null
    else
        doas tee /usr/local/share/applications/vivaldi.desktop >/dev/null <<'DESKTOP'
[Desktop Entry]
Version=1.0
Name=Vivaldi
Comment=Vivaldi Web Browser
Exec=/usr/local/bin/vivaldi %U
Icon=vivaldi
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;
DESKTOP
    fi

    if [ -f /compat/ubuntu/usr/share/applications/1password.desktop ]; then
        doas sed -E \
            's|^(Exec=).*1password|\1/usr/local/bin/1password|' \
            /compat/ubuntu/usr/share/applications/1password.desktop \
            | doas tee /usr/local/share/applications/1password.desktop >/dev/null
    elif [ -f /compat/ubuntu/opt/1Password/resources/1password.desktop ]; then
        doas sed -E \
            's|^(Exec=).*1password|\1/usr/local/bin/1password|' \
            /compat/ubuntu/opt/1Password/resources/1password.desktop \
            | doas tee /usr/local/share/applications/1password.desktop >/dev/null
    else
        doas tee /usr/local/share/applications/1password.desktop >/dev/null <<'DESKTOP'
[Desktop Entry]
Version=1.0
Name=1Password
Comment=1Password - Password Manager
Exec=/usr/local/bin/1password %U
Icon=1password
Terminal=false
Type=Application
Categories=Utility;Security;
DESKTOP
    fi

    # Copy icons from chroot (best-effort; KDE will fall back to theme icons)
    for icon_name in vivaldi 1password; do
        for icon_dir in /compat/ubuntu/usr/share/icons /compat/ubuntu/opt/1Password/resources/icons; do
            if [ -d "$icon_dir" ]; then
                find "$icon_dir" -name "${icon_name}*" -type f 2>/dev/null | while read -r src; do
                    rel="${src#/compat/ubuntu}"
                    dest_dir=$(dirname "/usr/local${rel#/usr}")
                    doas mkdir -p "$dest_dir"
                    doas cp -f "$src" "$dest_dir/" || true
                done
            fi
        done
    done

    msg "Linuxulator setup complete."
    msg ""
    msg "Verification steps:"
    msg "  1. cat /compat/ubuntu/etc/os-release   (should show Ubuntu 22.04)"
    msg "  2. sysctl compat.linux.emul_path       (should show /compat/ubuntu)"
    msg "  3. mount | egrep '/compat/ubuntu/(dev|proc|sys|tmp|home)'"
    msg "  4. vivaldi                             (should launch browser)"
    msg "  5. 1password                           (should launch password manager)"
    msg "  6. Check KDE launcher for app entries"
    msg "  7. Test 1Password browser extension in Vivaldi"
}

main "$@"
