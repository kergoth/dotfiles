---
status: accepted
date: 2026-03-09
decision-makers: kergoth
---

# Chimera Linux glibc Compatibility via Ubuntu Distrobox

## Context and Problem Statement

Chimera Linux uses musl libc. Key GUI applications — 1Password, Vivaldi, and Zed — distribute glibc-linked binaries only and cannot run natively on Chimera. The stopgap was to install them via Flatpak, but Flatpak sandboxing broke two important integration points: 1Password's SSH agent socket (needed for `ssh-add` and agent forwarding) and browser-extension IPC between Vivaldi and 1Password (requires a Unix socket path that Flatpak does not expose). Zed's official Linux installer fails outright due to musl/BSD userland incompatibility and has no Flatpak package.

## Decision Drivers

* 1Password SSH agent and browser-extension IPC must work without user-visible friction
* Vivaldi must be able to connect to 1Password for credential autofill
* Zed must be installable and runnable on Chimera
* The solution must be idempotent and manageable via `chezmoi apply`
* No vendoring or patching of upstream binaries

## Considered Options

* Flatpak (previous stopgap)
* FreeBSD Linuxulator-style compat layer
* Ubuntu 22.04 distrobox (rootless Podman container, shared `$HOME`)

## Decision Outcome

Chosen option: "Ubuntu 22.04 distrobox", because it provides a full glibc environment with shared `$HOME` and host IPC namespace, which satisfies both the SSH agent socket requirement and the browser-extension integration requirement. Validated manually before adoption.

### Consequences

* Good, because 1Password SSH agent and browser-extension IPC work without configuration workarounds
* Good, because Zed installs via its standard installer inside the container
* Good, because exported `.desktop` files appear in the host KDE launcher transparently
* Good, because shared `$HOME` means dotfiles are immediately available inside the container without copying or mounting
* Bad, because container startup adds a small overhead on first use of each exported app
* Bad, because container must be kept consistent with the host setup; divergence is a maintenance concern
* Neutral, because Chimera does not have a FreeBSD-equivalent compat layer, so this option was not actually available

### Confirmation

After `chezmoi apply` on a non-headless, non-ephemeral Chimera system:
- `distrobox list` shows an `ubuntu` container
- Vivaldi, 1Password, and Zed appear in the KDE application launcher
- 1Password browser extension connects to the app without re-authentication
- A second `chezmoi apply` is idempotent (no script body emitted)

## More Information

Implementation: `home/.chezmoiscripts/linux/run_onchange_after_20_setup-distrobox.tmpl` and `scripts/setup-distrobox-chimera.sh`.

The distrobox runs only when `.containers`, `not .headless`, `not .ephemeral`, and `CONTAINER_ID` is unset — preventing the setup script from running recursively inside the container.

Inside-container logic always lives in `scripts/setup-distrobox-chimera.sh`, not inline in the template, so it can be run directly for development and debugging without a full `chezmoi apply`.

Related: GitHub issue #67 (closed).
