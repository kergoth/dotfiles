# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

```bash
# Apply dotfiles changes to home directory
chezmoi apply

# Edit a dotfile with live reload
chezmoi edit --watch ~/.config/zsh/.zshrc

# Update dotfiles and external dependencies
chezmoi update -R

# Full update including Home Manager packages
./script/update

# Setup (after cloning, applies dotfiles + user configuration)
./script/setup

# System-level setup (requires sudo, installs packages, nix, etc.)
./script/setup-system

# Inspect current template variables and flags
chezmoi data | less

# Preview what chezmoi would change
chezmoi diff

# Diagnose chezmoi configuration issues
chezmoi doctor
```

## Setup Entry Points

Scripts form a progression from OS installation to dotfiles application:

- `script/{distro}/os-install` — Install OS from live environment (Arch, Chimera)
- `script/{distro}/setup-root` — Root-level setup: create users, install base packages (Arch, Chimera, FreeBSD)
- `script/bootstrap` — Install prerequisites, clone repo, init chezmoi (run automatically by setup scripts)
- `script/setup-system` — System-level packages, Nix, prerequisites (non-root user with sudo)
- `script/setup` / `chezmoi apply` — Apply dotfiles and user-level packages
- `script/setup-full` — Runs `setup-system` then `setup`

- `script/update` — Update dotfiles, externals, and home-manager packages
- `script/test` - Runs dotfiles setup in container test environments

## Repository Architecture

This is a **chezmoi-managed dotfiles** repository supporting macOS, Linux (Arch, Debian, Ubuntu, Chimera, SteamOS), FreeBSD, and Windows.

### Directory Structure

- **`home/`** - Chezmoi source directory (set via `.chezmoiroot`). Contains all managed dotfiles.
- **`script/`** - User-facing entry-point scripts (`bootstrap`, `setup`, `setup-system`, `update`)
- **`scripts/`** - Supplementary scripts, libraries, and extras (internal helpers, platform configs, and optional user-facing tools)
  - `common.sh` - Shared bash functions (`has`, `run`, `msg`, `die`, `need_sudo`, package helpers)
  - `common.ps1` - PowerShell equivalent
  - `chezmoi-*` - Helper scripts for chezmoi operations
  - `macos/Brewfile*.tmpl` - Homebrew package definitions
- **`settings/`** - Shared settings files (GnuPG, PowerShell, etc.)

### Chezmoi Source Structure (`home/`)

- **`.chezmoi.toml.tmpl`** - Main config template with OS detection and feature flags
- **`.chezmoiexternal.toml.tmpl`** - External dependencies (tools, plugins, fonts)
- **`.chezmoiignore.tmpl`** - Conditional file exclusions by OS/feature
- **`.chezmoidata/`** - YAML data files (fonts, paths, UI settings per host)
- **`.chezmoiscripts/`** - Run scripts organized by platform:
  - `darwin/` - macOS-specific
  - `linux/` - Linux-specific
  - `freebsd/` - FreeBSD-specific
  - `windows/` - Windows PowerShell scripts
  - `posix/` - Unix-like systems (shared)
- **`.chezmoitemplates/`** - Reusable templates
  - `external/` - Modular external dependency templates

## Chezmoi Patterns

### Template Variables (from `.chezmoi.toml.tmpl`)

Key variables used throughout templates:

```go
// OS Detection
$osid       // "darwin", "linux", "linux-arch", "linux-chimera", "linux-debian", "linux-ubuntu", "linux-steamos", "freebsd", "windows"
$wsl2       // true if WSL2
$steamdeck  // true if Steam Deck
$devpod     // true if DevPod container

// Feature Flags
$ephemeral  // Temporary machine (VM, container)
$headless   // No GUI
$personal   // Personal machine with secrets
$work       // Work machine
$secrets    // Has access to secrets (personal or work, non-ephemeral)
$coding     // Development workstation
$containers // Needs container runtime
$use_nix    // Use Nix/home-manager
$user_setup // Full user setup vs dotfiles-only
```

### Script Naming Convention

Chezmoi run scripts follow this pattern:

- `run_onchange_before_*` - Run before dotfiles, when content changes
- `run_onchange_after_*` - Run after dotfiles, when content changes
- Numbered prefixes (00_, 10_, 20_, etc.) control execution order

### External Dependencies

Chezmoi externals download non-package-manager resources. Templates in `.chezmoitemplates/external/` define:

- Zsh plugins and themes
- Fonts (iA Writer, MesloLGS NF)
- Vim plugins
- Color schemes and app data

### Secrets Management

- **Age encryption** with identity key from 1Password
- Encrypted files use `.age` extension
- `chezmoi-edit-encrypted` script for editing encrypted files
- Bootstrap scripts retrieve age key from 1Password during setup

## Common Script Functions (from `scripts/common.sh`)

```bash
has <command>              # Check if command exists
run <command>              # Run command with logging
msg "text"                 # Print message
die "error"                # Print error and exit
need_sudo                  # Ensure sudo access
is_mac / is_freebsd        # OS detection
pacman_install <pkg>       # Install via pacman
brewfile_install <file>    # Install from Brewfile
uv_check <pkg>             # Install Python tool via uv
cargo_check <pkg>          # Install Rust tool via cargo
```

## Adding Software to This Repository

**See `docs/contributing-software.md` for comprehensive documentation on adding software.**

Quick reference:
- **GUI apps**: macOS (Homebrew cask), Windows (Scoop/winget), Linux (Flatpak or Nix)
- **CLI tools**: Prefer Nix > Homebrew (macOS) / Scoop (Windows) > system packages > install-tools (eget/cargo/uv)
- **Use `before_` scripts for CLI tools** (dotfiles may detect them)
- **Use `after_` scripts for GUI apps** (don't delay dotfiles for large installs)
- **Always check conditional flags**: `.coding`, `.containers`, `.ephemeral`, `.headless`, `.personal`, `.work`, etc.

## Removing Software from This Repository

See `docs/contributing-software.md` for platform-specific file paths to check.

1. Remove from all applicable installation files (Brewfile, home.nix, install-tools, scoop, system-setup)
2. Move README entry from "Installed" to "Formerly-Used" section (drop conditional/install notes, add replacement note)
3. Verify no remaining references that would break without the tool

## Platform-Specific Notes

- **macOS**: Uses Homebrew (prefix: `$HOME/.brew`), optional split admin user setup
- **macOS admin Homebrew**: Separate `Brewfile-admin.tmpl` for shared `/Users/Shared/homebrew` prefix (Mac App Store apps, admin-requiring casks)
- **Linux**: Nix/home-manager for packages when available; eget for Chimera gaps (no Nix); cargo/uv very limited
- **Windows**: Uses Scoop and winget, PowerShell scripts (`.ps1.tmpl`)
- **FreeBSD**: pkg/ports for tool installation

## README Documentation Patterns

### Entry Formatting

- **Installed CLI/GUI Software**: `- [Name](url) ([Open-Source](repo)): Description.` — no "Available via" notes
- **Conditional entries**: Append `_Conditional: flag description._` in italics
- **As-needed Software**: Include `Available via brew, nix, scoop, ...` for manual install guidance
- **Formerly-Used entries**: No conditional notes or install instructions; add replacement note if applicable
- **Third-Party Scripts section**: `- **name** ([source](url)): Description.` — bold name, source link in parens
- Entries within sections are ordered **alphabetically**
- Platform-specific subsections nest under the main section (e.g., `#### CLI Software on macOS`)
