#!/usr/bin/env bash
set -euo pipefail

# Usage: configure-devpod.sh dotfiles_url dotfiles_script ssh_config_path [provider_name] [default_ide]
#
# Configures DevPod via CLI when devpod and jq are available. Exits 0 when
# devpod or jq is missing.

usage() {
    printf 'usage: %s dotfiles_url dotfiles_script ssh_config_path [provider_name] [default_ide]\n' \
        "${0##*/}" >&2
    exit 1
}

has() {
    command -v "$1" >/dev/null 2>&1
}

msg() {
    printf '%s\n' "$*" >&2
}

main() {
    if [ "$#" -lt 3 ]; then
        usage
    fi

    local dotfiles_url="$1"
    local dotfiles_script="$2"
    local ssh_config_path="$3"
    local provider_name="${4:-docker}"
    local default_ide="${5:-}"

    if ! has devpod; then
        msg "devpod not found, skipping DevPod configuration"
        exit 0
    fi

    if ! has jq; then
        msg "jq not found, skipping DevPod configuration"
        exit 0
    fi

    msg "Configuring DevPod"

    local providers_json
    providers_json="$(devpod provider list --output json 2>/dev/null || true)"

    if [ -z "$providers_json" ]; then
        msg "Warning: Unable to read DevPod provider list, skipping provider configuration"
        exit 0
    fi

    if ! jq -e --arg name "$provider_name" 'has($name)' >/dev/null <<<"$providers_json"; then
        msg "Adding DevPod provider '$provider_name'"
        devpod provider add "$provider_name" >/dev/null 2>&1 || {
            msg "Warning: Failed to add DevPod provider '$provider_name'"
            exit 0
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
        -o "TELEMETRY=false" \
        >/dev/null 2>&1 || msg "Warning: Failed to set some DevPod context options"

    if [ -n "$default_ide" ]; then
        msg "Setting DevPod default IDE to '$default_ide'"
        devpod ide use "$default_ide" >/dev/null 2>&1 || \
            msg "Warning: Failed to set DevPod default IDE to '$default_ide'"
    fi
}

main "$@"
