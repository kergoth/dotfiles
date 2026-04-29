# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Essential Commands

```bash
# Apply dotfiles changes to home directory
chezmoi apply

# Edit a dotfile with live reload
chezmoi edit --watch ~/.config/zsh/.zshrc

# Update dotfiles and external dependencies
chezmoi update -R

# Full update including Home Manager packages (bumps nixpkgs/nixpkgs-unstable inputs)
./script/update

# Apply home.nix changes, diff generations, commit, and switch (no version bump)
./script/home-manager-switch "Remove unused packages"

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

```bash
# Test dotfiles setup in containers (requires Docker)
./script/test           # all supported distros
./script/test arch      # specific distro only
./script/test -i arch   # drop into user shell after setup (debug)
./script/test -r -i arch   # stop after setup-root, then open a shell
./script/test -c 'chezmoi data' arch   # run a command after the selected setup phase
./script/test -S arch   # skip setup-system, only run setup
./script/test -b        # build container images only, don't run
./script/test -w arch   # workstation mode: DOTFILES_HEADLESS=0, DOTFILES_EPHEMERAL=0 (enables GUI app installs)
./script/test -G arch   # seed container GNUPGHOME from host ~/.gnupg (avoids interactive GPG passphrase)
./script/test -C arch   # skip shared nix store/cache volumes
./script/test debian ubuntu  # test multiple distros in one run (space-separated)

# Run the structured Cram regression suites (all suites, or scope to a path)
./test/run-cram                         # all Cram suites under test/cram/
./test/run-cram test/cram/container     # container-backed dotfiles scenarios
./test/run-cram test/cram/statusline    # statusline transcript tests

# Validate template rendering without applying
scripts/chezmoi-execute-template home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl
# Optional for managed files: chezmoi cat --source-path home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl
```

Env vars for secrets-enabled testing (pass to `./script/test`):

- `DOTFILES_SECRETS=1` — mount host age key; enables chezmoi secret decryption
- `DOTFILES_PERSONAL=1` — force personal profile (auto-detected from host if unset)
- `DOTFILES_WORK=1` — force work profile
- `DOTFILES_SKIP_GPG_SECRET_IMPORT=1` — skip interactive GPG secret key import

## Setup Entry Points

Scripts form a progression from OS installation to dotfiles application:

- `script/{distro}/os-install` — Install OS from live environment (Arch, Chimera)
- `script/{distro}/setup-root` — Root-level setup: create users, install base packages (Arch, Chimera, FreeBSD)
- `script/bootstrap` — Install prerequisites, clone repo, init chezmoi (run automatically by setup scripts)
- `script/setup-system` — System-level packages, Nix, prerequisites (non-root user with sudo)
- `script/setup` / `chezmoi apply` — Apply dotfiles and user-level packages
- `script/setup-full` — Runs `setup-system` then `setup`

- `script/update` — Update dotfiles, externals, and bump home-manager flake inputs (nixpkgs/nixpkgs-unstable)
- `script/home-manager-switch [--update-inputs "..."] ["subject"]` — Apply home.nix changes, diff generations, commit all changes under `home/dot_config/home-manager/`, and switch. Called by `script/update`; also useful standalone when editing `home.nix`.

Container-based test runners (`script/test`, `test/run-cram`) are documented in Essential Commands above.

## Repository Architecture

This is a **chezmoi-managed dotfiles** repository supporting macOS, Linux (Arch, Debian, Ubuntu, Chimera, SteamOS), FreeBSD, and Windows.

### Directory Structure

- **`home/`** - Chezmoi source directory (set via `.chezmoiroot`). Contains all managed dotfiles.
- **`script/`** - User-facing entry-point scripts (`bootstrap`, `setup`, `setup-system`, `update`, `home-manager-switch`)
- **`scripts/`** - Supplementary scripts, libraries, and extras (internal helpers, platform configs, and optional user-facing tools)
  - `common.sh` - Shared bash functions (`has`, `run`, `msg`, `die`, `need_sudo`, package helpers)
  - `common.ps1` - PowerShell equivalent
  - `chezmoi-*` - Helper scripts for chezmoi operations
  - `macos/Brewfile*.tmpl` - Homebrew package definitions
- **`.github/`** - GitHub repository automation and metadata
  - `workflows/` - GitHub Actions workflows for repo maintenance and validation
  - `labels.yml` - Declarative GitHub label definitions synced by the labels workflow
- **`settings/`** - Shared settings files (GnuPG, PowerShell, agent rules, etc.)
  - `agents/rules/` - Private agent rule templates (personal, work) included by `render-agent-rules.md.tmpl`
  - `agents/` - Encrypted data blobs for work-only agent configuration
- **`test/`** - Test infrastructure
  - `containers/` - Per-distro Dockerfiles and the `run-test` driver script
  - `cram/` - Structured Cram suites and helpers
    - `container/` - Container-backed dotfiles scenario tests
    - `statusline/` - Statusline transcript tests
  - `run-cram` - Wrapper around `uvx cram`

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
- `run_once_*` - Run once per machine (tracks state in chezmoi)
- Numbered prefixes (00_, 10_, 20_, etc.) control execution order

**Timing rule:** CLI tools use `before_` (dotfiles may detect them via `find-tool`); GUI apps use `after_` (don't delay dotfiles for large installs). See `docs/contributing-software.md` for full timing guidance.

### External Dependencies

Chezmoi externals download non-package-manager resources. Templates under `.chezmoitemplates/external/` cover tooling, agent content, editor assets, fonts, and other app data. Shared Git/fetch pinning supports the repo's review-first update flow, used by externals, install/update scripts, and any template consuming upstream content.

Sources and locks (in `home/.chezmoidata/`):

- `git-sources.yml` / `git-lock.yml` — Git sources with resolution and review metadata; lock stores SHA (branch-tracked) or tag name (tagged).
- `fetch-sources.yml` / `fetch-lock.yml` — pinned single-file fetches; lock stores SHA-256 of bytes.

Update tooling:

- `scripts/update-git-lock.py --dry-run --json` — resolves candidate updates; emits structured metadata for downstream tooling.
- `scripts/update-fetch-lock.py` — resolves current bytes for `fetch-sources.yml`; writes `fetch-lock.yml`.
- `script/update` / `script/update.ps1` — orchestrate review-first flow: resolve, review each candidate, prompt before apply, write locks, commit.
- `scripts/show-git-changes.py` — review surface for a candidate: fetches old/new range, shows log/shortlog/diff, may run AI review. For `kind=tag` GitHub sources, also includes release notes in the AI prompt.

Per-source review metadata:

- `review_note` — repo-specific instructions for AI review. Treat release notes as narrative context, not a substitute for diff review.
- `review_paths` — hard-scopes fetched log/diff; useful for large repos or release-tracking sources where only part of the tree matters.

### Secrets Management

- **Age encryption** with identity key from 1Password
- Encrypted files use `.age` extension
- `chezmoi-edit-encrypted` script for editing encrypted files
- Bootstrap scripts retrieve age key from 1Password during setup
- **Encrypted fragment inclusion**: non-managed `.age` files can be spliced into templates via `include | decrypt` (e.g., `joinPath .chezmoi.sourceDir ".chezmoitemplates/external/agent-content-work.toml.age" | include | decrypt`). Used for work-only chezmoi externals where the content (repo URLs) must stay encrypted in the public repo.

### Agent Configuration

Agent rules, skills, and subagent configs are managed through a shared pipeline:

- **Rules**: `home/dot_agents/rules/*.md.tmpl` are sorted alphabetically and rendered by `render-agent-rules.md.tmpl` with an `agent` parameter. Each agent tool gets its own output file:
  - Claude: `~/.claude/CLAUDE.md` (via `home/dot_claude/CLAUDE.md.tmpl`)
  - Codex: `~/.codex/AGENTS.md` (via `home/dot_codex/AGENTS.md.tmpl`)
  - Cursor: `~/.cursor/rules/agent-rules.mdc` (via `home/dot_cursor/rules/agent-rules.mdc.tmpl`) — uses `.mdc` format with `alwaysApply: true` frontmatter
- **Skills**: All agent tools symlink to `~/.agents/skills/` (e.g., `~/.claude/skills → ~/.agents/skills`). Skills come from three sources:
  - Symlinks to external archives (superpowers, anthropic, astral) in `~/.agents/external-sources/`
  - Local skills in `home/dot_agents/skills/` (obsidian-cli, shell-script-style)
  - Work-only skills symlinked by `run_onchange_after_40_link-work-agent-content.tmpl` from encrypted repos cloned to `~/Workspace/`
- **Agents** (Claude Code only): `~/.claude/agents → ~/.agents/agents/`. Subagent configs (markdown files with YAML frontmatter) come from two sources:
  - Static symlinks in `home/dot_agents/agents/` — curated, flat (top-level). Use subdirectories named after the source only to resolve name collisions.
  - Work-only agents linked by `run_onchange_after_40_link-work-agent-content.tmpl` into repo-name subdirectories (e.g., `~/.agents/agents/ai-resources/`). Claude Code discovers agents recursively.
- **Agent-specific conditionals**: Templates can branch on the `agent` parameter (e.g., `{{ eq $agent "claude" }}`) for tool-specific guidance

### Ensuring Directories Exist

- Create the directory under `home/` with chezmoi naming (e.g., `home/dot_local/share/wget/`) — chezmoi will create it on apply
- Add a `.keep` file inside so git tracks the empty directory (git cannot track empty directories)
- If the directory holds unmanaged runtime files (state, caches, tool-generated data), whitelist the directory in `.chezmoiignore.tmpl` with `!path` and ignore contents with `path/*` — this prevents chezmoi from trying to manage files created by the tool at runtime
- See `.local/state/zsh` and `.local/share/wget` for examples
- Do NOT use `mkdir -p` in run scripts for directories chezmoi should manage

### File Removal and Cleanup

- `.chezmoiremove.tmpl` triggers **interactive confirmation prompts** — avoid for files that may reappear (e.g., tool-generated state files)
- Prefer `rm -f` in `run_onchange_after_00_migrate-xdg-paths` for cleaning up old XDG paths — runs non-interactively
- Reserve `.chezmoiremove` for one-time removal of obsolete managed files that won't be recreated

### Linux GUI App Install Pattern (`run_onchange_after_10_install-apps.tmpl`)

Two-phase: template header computes `$need_install` via `find-tool` checks (renders script empty if nothing to do); body emits install commands only when needed. New GUI apps need entries in **both** the header (tool detection + `$need_install` trigger) and the body (flatpak install command).

### Chimera Linux Distrobox Pattern (`run_onchange_after_20_setup-distrobox.tmpl`)

Chimera uses musl libc — glibc-linked binaries (1Password, Vivaldi, Zed) can't run natively. The solution is an Ubuntu 22.04 distrobox: `run_onchange_after_20_setup-distrobox.tmpl` creates/updates the container from the host; `scripts/setup-distrobox-chimera.sh` runs inside to install apps and export `.desktop` files via `distrobox-export`. Only runs when `.containers`, `not .headless`, `not .ephemeral`, and not already inside a container. Use this for glibc GUI apps on Chimera that are unavailable on Flathub or where Flatpak sandboxing is inappropriate (cross-app IPC, DE biometric integration, unrestricted filesystem access).

### Template Helpers: `find-tool` / `availableTools` / `packagesForMissingTools`

- All three accept `home_paths` (bool, default true) and `system_paths` (bool, default true) to control which path sets are searched. Either is appropriate for user or system package detection.
- None use `lookPath` — search is path-list-only (from `paths.yml` data) for consistent behavior independent of shell `$PATH`.
- `packagesForMissingTools` wraps `availableTools`: takes a dict of `cmd→install-spec` (bare pkg name, or full arg string like `--git https://...` for cargo), returns only the specs whose commands are missing.
- Individual `find-tool` calls scale fine for 1–3 tools; prefer `packagesForMissingTools` for larger sets. Multi-package install scripts will likely migrate to this pattern.

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

## Troubleshooting

**Template errors during `chezmoi apply`:**
```bash
# Render a template to see exact output (catches syntax errors, missing vars)
scripts/chezmoi-execute-template home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl

# For managed files, use chezmoi's built-in command
chezmoi cat --source-path ~/.config/zsh/.zshrc
```

**Find where a variable is set:**
```bash
chezmoi data | grep -A2 'ephemeral'  # Check current value and source
# Variables come from: .chezmoi.toml.tmpl, .chezmoidata/*.yml, or environment
```

**Script fails during apply:**
```bash
# Re-run a non-templated script manually with verbose output
bash -x "$(chezmoi source-path)/home/.chezmoiscripts/posix/run_onchange_after_50_setup-shell"

# Render and run a templated script with debug output
scripts/chezmoi-execute-template home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl | bash -x

# Check if script is being skipped (content hash unchanged)
chezmoi status | grep run_onchange
```

**External dependency fails to download:**
```bash
# Check what externals chezmoi would fetch
chezmoi managed --include=externals

# Force re-fetch of externals
chezmoi apply --refresh-externals
```

## Adding/Removing Software

See `docs/contributing-software.md` for the full guide: platform paths (Brewfile, home.nix, install-tools, scoop, system-setup), package-manager preference order, timing rules (`before_` vs `after_`), conditional flags, README entry formatting, and the verification checklist. On removal, README entries move from "Installed" to "Formerly-Used".

## Platform-Specific Notes

- **macOS**: Uses Homebrew (prefix: `$HOME/.brew`), optional split admin user setup
- **macOS admin Homebrew**: Separate `Brewfile-admin.tmpl` for shared `/Users/Shared/homebrew` prefix (Mac App Store apps, admin-requiring casks)
- **Linux**: Nix/home-manager for packages when available; eget for Chimera gaps (no Nix); cargo/uv very limited
- **Windows**: Uses Scoop and winget, PowerShell scripts (`.ps1.tmpl`). `Install-Scoop-IfNotPresent` is a legacy winget-compat shim being phased out — new GUI app installs use `find-tool` in the template header + bare `scoop install` in the body (see `run_onchange_before_25_install-tools.ps1.tmpl` for the pattern).
- **FreeBSD**: pkg/ports for tool installation
