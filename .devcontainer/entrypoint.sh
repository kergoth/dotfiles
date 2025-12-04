#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${TARGET_USER:-vscode}"

# Resolve home directory for TARGET_USER
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6 || true)"
TARGET_HOME="${TARGET_HOME:-/home/${TARGET_USER}}"

# linuxserver.io-style env vars
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

CURRENT_UID="$(id -u "${TARGET_USER}")"
CURRENT_GID="$(id -g "${TARGET_USER}")"

# Update primary group
if [[ "${CURRENT_GID}" != "${PGID}" ]]; then
    if getent group "${PGID}" >/dev/null 2>&1; then
        # Reuse existing group with this GID
        EXISTING_GROUP="$(getent group "${PGID}" | cut -d: -f1)"
        usermod -g "${EXISTING_GROUP}" "${TARGET_USER}"
    else
        groupmod -o -g "${PGID}" "${TARGET_USER}"
    fi
fi

# Update user UID
if [[ "${CURRENT_UID}" != "${PUID}" ]]; then
    usermod -o -u "${PUID}" "${TARGET_USER}"
fi

# Fix ownership of the home directory
if [[ -d "${TARGET_HOME}" ]]; then
    chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}"
fi

# Optionally fix ownership of the workspace if mounted
if [[ -n "${WORKSPACE_PATH:-}" && -d "${WORKSPACE_PATH}" ]]; then
    chown -R "${TARGET_USER}:${TARGET_USER}" "${WORKSPACE_PATH}"
fi

# Run the actual container command as TARGET_USER
# Requires gosu (or su-exec) in the image.
exec gosu "${TARGET_USER}" "$@"
