# Adding Software to This Dotfiles Repository

This guide documents how to add software installations to this chezmoi-managed dotfiles repository. It covers supported platforms, install locations, template patterns, README inventory rules, and verification.

## Quick Reference: Decision Tree

```
Is this a GUI application?
├── Yes
│   ├── macOS (user) → Homebrew cask (scripts/macos/Brewfile.tmpl)
│   ├── macOS (admin) → Homebrew cask + mas (scripts/macos/Brewfile-admin.tmpl)
│   ├── Windows (user) → Scoop (home/.chezmoiscripts/windows/run_onchange_after_10_install-apps.ps1.tmpl)
│   ├── Windows (admin) → winget (scripts/setup-system-windows.ps1.tmpl)
│   ├── Linux (non-headless) → Flatpak (universal on all supported distros)
│   └── Linux (Chimera, glibc GUI app unavailable on Flathub or Flatpak sandbox inadequate) → distrobox container (Ubuntu 22.04)
└── No (CLI tool)
    ├── Requires root/system-level installation?
    │   └── Yes → Platform system-setup script (scripts/setup-system-*.tmpl)
    ├── Needs a pinned/review-first direct install?
    │   └── Yes → install-tools + git/fetch lock data (for example Claude Code or Codex)
    ├── Available in Nix? (check: https://search.nixos.org/packages)
    │   └── Yes → Add to home.nix.tmpl
    ├── macOS-only or Nix intentionally not used? → Homebrew formula (scripts/macos/Brewfile.tmpl)
    ├── Windows → Scoop (run_onchange_before_25_install-tools.ps1.tmpl)
    ├── Available via language package manager?
    │   ├── Rust (cargo) → install-tools only for approved gaps
    │   └── Python (uv) → install-tools for Python tools
    ├── Chimera (non-Nix): Available in apk repos?
    │   ├── Yes → system packages (scripts/setup-system-chimera.tmpl)
    │   └── No → eget via install-tools
    └── FreeBSD: Available in pkg/ports?
        └── Yes → system packages (scripts/setup-system-freebsd.tmpl)
```

## Preference Hierarchy

When multiple installation methods are available, prefer them in this order:

1. **User installation over system installation** - Avoid requiring sudo/admin when possible
2. **Reviewed, repeatable sources over floating installers** - Prefer package managers, pinned release assets, or lock-file-driven installers over unpinned downloads
3. **Nix over Homebrew for shared CLI tools** - Use Homebrew casks for GUI apps on macOS
4. **Language package managers only for approved gaps** - Use `uv`, `cargo`, or `npm` when the project already uses that path for the tool class or platform gap
5. **System packages when Nix is unavailable** - Chimera uses `apk`; FreeBSD uses pkg/ports
6. **eget for Chimera gaps** - Use GitHub release binaries only when the tool is unavailable through the preferred package sources

### Exception: Pinned or Freshness-Sensitive Tools

Some tools update often enough, or have packaging constraints specific enough, that the default CLI hierarchy is not enough. Treat these as explicit design choices, not as a general excuse to bypass Nix or system packages.

Current examples:

- **Claude Code**: pinned through `git-lock.yml`; POSIX and Windows install-tools use the official installer, and FreeBSD uses a pinned npm package.
- **Codex**: pinned through `git-lock.yml` plus verified release assets in `fetch-lock.yml`; POSIX and Windows install-tools use the direct installer path when a locked asset exists.
- **jujutsu (`jj`)**: installed through platform package managers. Homebrew is used on macOS because it tracks releases well enough for day-to-day use.

When adding a new tool in this class, document why the ordinary hierarchy is insufficient, add or update lock data when direct downloads are involved, and include a verification path that proves the pinned version renders into the installer template.

## Platform Support Matrix

> **Note:** This matrix documents our current preferred installation methods, not every
> available option. For example, Flatpak is our current approach for Linux GUI apps, but
> AppImage, Snap, or native packages could also work. The decision tree and hierarchy above
> guide which method to use when multiple options exist.

| Platform | GUI Apps | CLI (Primary) | CLI (Fallback) | System-Level (admin/root) |
|----------|----------|---------------|----------------|---------------------------|
| macOS | Homebrew cask | Nix OR Homebrew formula | cargo/uv | Brewfile-admin (mas + casks), system config |
| Windows | Scoop | Scoop | cargo/uv | winget, system config (Sophia Script) |
| Linux (Arch) | Flatpak | Nix | cargo/uv | pacman, system services |
| Linux (Debian/Ubuntu) | Flatpak | Nix | cargo/uv | apt, system services |
| Linux (Chimera) | Flatpak → distrobox (Ubuntu 22.04) | apk (system) | eget → cargo/uv | apk, doas, system services |
| Linux (SteamOS) | N/A | Limited | cargo/uv | Minimal |
| FreeBSD | pkg/ports | pkg/ports | cargo/uv | pkg, ports, doas, system services |

## File Reference

See [Repository Architecture](repository-architecture.md) for the role of each
top-level directory and the source-to-rendered flow.

### User-Level Installation Files

| Purpose | File Path |
|---------|-----------|
| macOS Homebrew (user) | `scripts/macos/Brewfile.tmpl` |
| macOS Homebrew (admin) | `scripts/macos/Brewfile-admin.tmpl` |
| macOS App Store | `scripts/macos/Brewfile-admin.tmpl` (mas entries) |
| Windows GUI apps (user) | `home/.chezmoiscripts/windows/run_onchange_after_10_install-apps.ps1.tmpl` |
| Windows CLI tools (user) | `home/.chezmoiscripts/windows/run_onchange_before_25_install-tools.ps1.tmpl` |
| Linux GUI apps and GUI-adjacent installers | `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl` |
| Chimera distrobox (host) | `home/.chezmoiscripts/linux/run_onchange_after_20_setup-distrobox.tmpl` |
| Chimera distrobox (container) | `scripts/setup-distrobox-chimera.sh` |
| Nix packages | `home/dot_config/home-manager/home.nix.tmpl` |
| POSIX CLI tools and pinned direct installers | `home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl` |

### System-Level Installation Files

| Platform | File Path |
|----------|-----------|
| macOS | `scripts/setup-system-macos.tmpl` |
| Linux (shared) | `scripts/setup-system-linux.tmpl` |
| Arch Linux | `scripts/setup-system-arch.tmpl` |
| Debian | `scripts/setup-system-debian.tmpl` |
| Ubuntu | `scripts/setup-system-ubuntu.tmpl` |
| Fedora | `scripts/setup-system-fedora.tmpl` |
| Chimera Linux | `scripts/setup-system-chimera.tmpl` |
| SteamOS | `scripts/setup-system-steamos.tmpl` |
| FreeBSD | `scripts/setup-system-freebsd.tmpl` |
| Windows | `scripts/setup-system-windows.ps1.tmpl` (winget + direct MSIX) |

## Conditional Flags

Software templates combine machine-role, capability, and workload flags to
select the narrowest applicable installation. See
[Data and Template Variables](chezmoi-authoring.md#data-and-template-variables)
for the complete flag reference and the intent behind each value.

Common software conditions appear in the examples below and in
[Common Conditional Patterns](#common-conditional-patterns).

## Code Examples by Installation Method

### 1. macOS Homebrew Cask (GUI Apps)

**File:** `scripts/macos/Brewfile.tmpl`

```go
# Unconditional GUI app
cask "obsidian"

# Conditional on feature flag
{{ if and .gaming (not .work) -}}
cask "steam"
{{- end }}

# Multiple conditions
{{ if and .coding .container_runtime (not .ephemeral) (not .headless) -}}
cask "devpod"
{{- end }}
```

### 2. macOS Homebrew Formula (CLI Tools)

**File:** `scripts/macos/Brewfile.tmpl`

```go
# Only when Nix isn't handling it
{{ if and .work (not .use_nix) -}}
brew "git-crypt"
{{- end }}
```

### 3. Mac App Store

**File:** `scripts/macos/Brewfile-admin.tmpl`

```ruby
# Syntax: mas "App Name", id: NUMERIC_ID
mas "Tailscale", id: 1475387142
mas "1Password for Safari", id: 1569813296

# Conditional
{{   if .music -}}
mas "MusicHarbor", id: 1440405750
{{-   end }}
```

### 4. Windows GUI apps (User Level)

**File:** `home/.chezmoiscripts/windows/run_onchange_after_10_install-apps.ps1.tmpl`

New additions use `find-tool` in the template header plus bare `scoop install` in the body. For apps unavailable on
Scoop, download directly from a reviewed source and install silently in the body. Use `Test-Path` on the known install
location for idempotency instead of `find-tool`. Add a `find-tool` check in the header only for Scoop-installed apps,
because those land in PATH; skip it for direct-download apps.

```powershell
{{/* HEADER: before the main {{ if and .user_setup (not .headless) }} guard */}}
{{- $appname := "" -}}
{{- if and .user_setup (not .headless) .feature_flag (not .work) -}}
{{-   $appname = includeTemplate "find-tool" (dict "root" . "tool" "appname") -}}
{{- end -}}

{{/* BODY: inside the conditional block for the feature flag */}}
{{      if and .feature_flag (not $appname) -}}
scoop install appname
{{-     end }}
```

**Legacy pattern** (`Install-Scoop-IfNotPresent <scoop-name> <winget-id>`): a winget-compatibility shim present in existing code. It checks if the app is already installed via winget before installing via Scoop. Do not use it for new additions; use `find-tool` plus `scoop install` instead.

### 4b. Windows winget (GUI Apps - Admin Level)

**File:** `scripts/setup-system-windows.ps1.tmpl`

For apps that require admin privileges or aren't available in Scoop:

```powershell
# Uses Install-WinGetPackageIfNotInstalled from scripts/common.ps1
Install-WinGetPackageIfNotInstalled -Mode Silent -Id AgileBits.1Password | Out-Null

# Microsoft Store apps
Install-WinGetPackageIfNotInstalled -Mode Silent -Source msstore -Id 9NBLGGH33N0N

# Conditional
{{  if and (not .work) (not .ephemeral) -}}
Install-WinGetPackageIfNotInstalled -Mode Silent -Id tailscale.tailscale | Out-Null
{{- end }}
```

This script self-elevates to administrator. Use for:
- Apps that require system-level installation
- Microsoft Store apps
- Apps not available in Scoop

### 5. Nix Home Manager

**File:** `home/dot_config/home-manager/home.nix.tmpl`

```nix
  home.packages = with pkgs; [
    # Unconditional packages
    git
    neovim

    # Conditional on feature flag
{{- if .container_runtime }}
    docker
    docker-compose
{{- end }}

  # Platform-specific (Linux only for GUI, macOS uses Homebrew)
  ] ++ lib.optionals stdenv.isLinux [
    glibcLocales
  {{- if and .coding .container_runtime (not .ephemeral) (not .headless) }}
    devpod
  {{- end }}
  ];
```

**Note:** For macOS, prefer Homebrew casks for GUI apps. Only add CLI tools to the main packages list that should be shared across platforms.

### 6. Linux Flatpak (GUI Apps)

**File:** `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl`

> **Critical: two-phase template.** The header computes `$need_install`; the script body only emits if `$need_install` is true. New app classes must affect the header so the script renders when something is missing. Flatpak apps use a map of app IDs plus `packagesForMissingTools`; direct installers such as Zed and kitty use their own detection variables.
>
> For flatpak-backed entries in this script, detection must use the exported flatpak app ID under `~/.local/share/flatpak/exports/bin` (for example `md.obsidian.Obsidian`), not a guessed short command such as `obsidian`.

```go
{{/* HEADER: add the app ID to the flatpak map inside the $flatpak guard */}}
{{-   if .feature_flag -}}
{{-     $_ := set $flatpak_apps "org.example.AppName" "org.example.AppName" -}}
{{-   end -}}
{{-   $flatpak_to_install = includeTemplate "packagesForMissingTools" (dict "root" . "packages" $flatpak_apps) | fromJson -}}
{{-   if gt (len $flatpak_to_install) 0 -}}{{- $need_install = true -}}{{- end -}}

{{/* BODY: the existing range installs missing flatpak app IDs */}}
{{-   range $flatpak_to_install }}
msg "Installing {{ . }} from Flathub"
flatpak install -y --user flathub {{ . }}
{{-   end }}
```

### 7. Pinned Direct CLI Installer

**File:** `home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl`

Use this path for CLI tools that need a review-first direct install instead of ordinary package-manager handling. The current model is Codex: the version comes from `git-lock.yml`, platform assets come from `fetch-lock.yml`, and the rendered script calls a checked helper with the expected tag, version, URL, and SHA-256.

```go
{{-     $tool := includeTemplate "find-tool" (dict "root" . "tool" "toolname") -}}
{{-     $tool_tag := index .git_lock "tool_source" -}}
{{-     $tool_version := trimPrefix "v" $tool_tag -}}
{{-     $tool_sha256 := index .fetch_lock "tool_linux_amd64_release" -}}
{{-     $tool_direct_install := and (not $tool) (eq (len $tool_sha256) 64) -}}

{{       if $tool_direct_install }}
"$scriptsdir/install-tool" \
    --tag "{{ $tool_tag }}" \
    --version "{{ $tool_version }}" \
    --url "https://github.com/owner/repo/releases/download/{{ $tool_tag }}/tool-linux-amd64.tar.gz" \
    --sha256 "{{ $tool_sha256 }}"
{{-   end }}
```

For new direct installers, prefer a small helper script under `scripts/` when checksum verification, archive layout, or migration from old install methods needs more than a few lines. Update `git-sources.yml`, `git-lock.yml`, `fetch-sources.yml`, and `fetch-lock.yml` as needed, then add tests for the helper or template behavior.

### 8. CLI Tools via install-tools

**File (POSIX):** `home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl`
**File (Windows):** `home/.chezmoiscripts/windows/run_onchange_before_25_install-tools.ps1.tmpl`

These scripts handle CLI tools that are not managed by Home Manager, platform system packages, or Homebrew. The POSIX script runs when `.user_setup` is true, including on Nix-capable hosts, because it also handles pinned direct installers and helper tools outside Home Manager. The Windows script is the primary user-level CLI install path and uses Scoop first.

POSIX tools are organized into several categories:

**eget tools**: GitHub release binaries for Chimera gaps, meaning tools not in apk repos:

```go
{{- $eget_tools := dict -}}
{{- if eq .osid "linux-chimera" -}}
{{-   $_ := set $eget_tools "choose" "theryangeary/choose" -}}
{{-   $_ := set $eget_tools "sd" "chmln/sd" -}}
{{-   $_ := set $eget_tools "shellcheck" "-a xz koalaman/shellcheck" -}}
{{-   {{/* ... */}} -}}
{{- end -}}
```

**cargo tools**: very limited, currently only `fclones` on non-amd64 Chimera:

```go
{{- $cargo_tools := dict -}}
{{- if and (eq .osid "linux-chimera") (ne .chezmoi.arch "amd64") -}}
{{-   $_ := set $cargo_tools "fclones" "fclones" -}}
{{- end -}}
```

**uv tools**: Python tools installed via `uv tool install`:

```go
{{- $uv_tools := dict "git-imerge" "git-imerge" "git-revise" "git-revise" -}}
```

**npm tools and direct installers**: limited to specific pinned or fallback flows, such as Codex fallback handling and Claude Code on FreeBSD.

Each package-manager map uses the `packagesForMissingTools` helper to skip already-installed tools. If eget isn't already present, the script bootstraps it before installing eget tools.

The Windows version follows the same pattern but installs Scoop packages as its primary tool source, with cargo and uv as secondary sources.

### 9. Chimera Linux Distrobox (glibc GUI Apps)

For glibc-linked GUI apps on Chimera that are either unavailable on Flathub or where Flatpak sandboxing is inappropriate (e.g., cross-app IPC, DE biometric integration, unrestricted filesystem access), use the Ubuntu 22.04 distrobox. The distrobox shares `$HOME` with the host and exports `.desktop` files so apps appear in the launcher.

Add apps to `scripts/setup-distrobox-chimera.sh`. The host script (`run_onchange_after_20_setup-distrobox.tmpl`) re-runs automatically when `setup-distrobox-chimera.sh` changes via sha256sum in the template header, so no changes to the host script are needed.

**Install block** (before the `distrobox-export` section):

```bash
if ! command -v appname >/dev/null 2>&1; then
    # Add apt repo keyring and source, then install
    curl -fsSL https://example.com/signing-key.asc \
        | gpg --dearmor \
        | sudo dd of=/usr/share/keyrings/appname.gpg status=none
    echo "deb [signed-by=/usr/share/keyrings/appname.gpg] https://example.com/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/appname.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y appname
fi
```

**Export block** (in the distrobox-export section):

```bash
if ! distrobox-export --app appname; then
    echo >&2 "Error: failed to export AppName"
    exit 1
fi
```

Conditions: host script runs only when `eq .osid "linux-chimera"` and `.container_runtime` (Podman/distrobox) and `not .headless` and `not .ephemeral` and not already inside a container (`not (env "CONTAINER_ID")`).

### 10. Chimera Linux (apk + Flatpak)

**File:** `scripts/setup-system-chimera.tmpl`

```bash
# System packages via apk
apk add --no-interactive package-name

# GUI apps via Flatpak (inside not .headless block)
{{   if and .feature_flag (not .ephemeral) -}}
msg "Installing AppName from Flathub"
flatpak install -y flathub org.example.AppName || true
{{-   end }}
```

## Helper Templates

The shared `find-tool`, `availableTools`, and `packagesForMissingTools`
templates determine which packages are missing before emitting installation
commands. Their path-selection rules and calling conventions are documented in
[Shared Template and Script Helpers](chezmoi-authoring.md#shared-template-and-script-helpers).

For software installation, use `find-tool` for a small number of independent
checks. Use `packagesForMissingTools` when one installer can process a larger
set or needs a complete install specification such as Cargo `--git` arguments.

## Common Conditional Patterns

```go
# GUI app with multiple requirements
{{ if and .coding .container_runtime (not .ephemeral) (not .headless) -}}

# Personal-only app (not for work machines)
{{ if and .personal (not .work) (not .ephemeral) -}}

# Work-only tool
{{ if .work -}}

# Skip when Nix handles it
{{ if not .use_nix -}}

# Platform-specific in Nix
] ++ lib.optionals stdenv.isLinux [
] ++ lib.optionals stdenv.isDarwin [
```

## Script Naming Conventions

See [Run Script Naming and Timing](chezmoi-authoring.md#run-script-naming-and-timing)
for chezmoi prefixes, execution semantics, and numeric phases.

For software changes, place CLI tool installation in a `before_` script when
rendered configuration may detect the command. Place GUI applications in an
`after_` script because they do not affect dotfile rendering and may take
longer to install.

Examples:

- `run_onchange_before_25_install-tools.tmpl`: POSIX CLI tools via eget,
  Cargo, or uv
- `run_onchange_before_25_install-tools.ps1.tmpl`: Windows CLI tools via
  Scoop, Cargo, or uv
- `run_onchange_after_10_install-apps.tmpl`: Linux GUI applications
- `run_onchange_after_10_install-apps.ps1.tmpl`: Windows GUI applications

## Software Inventory Documentation

Automatically installed software belongs in `docs/installed.md`. Software
kept only as a future installation reference belongs in `docs/as-needed.md`.
README links to those inventories rather than containing their entries.

### Section Selection

Use the most specific heading whose platform list matches where the software
is installed. When another platform gains the software, move the entry to a
broader heading rather than duplicating it.

Before editing, inspect the current headings in the destination file. Some
headings repeat for historical reasons; place an entry beside related software
or consolidate duplicate headings as a separate cleanup.

For `docs/installed.md`:

- `### Installed CLI Software` and `### Installed GUI Software` cover all
  supported platforms.
- Subheadings such as `#### CLI Software on Linux, macOS, and FreeBSD` exclude
  the platforms they do not name.
- Platform-specific and version-gated headings cover narrower installations.

For `docs/as-needed.md`, use the applicable CLI or GUI heading and include
installation guidance such as `Available via brew, nix, or scoop`.

When removing installed software, move its entry to `docs/formerly-used.md`
unless it was only an internal implementation detail.

### For Installed Software

```markdown
- [ToolName](https://example.com) ([Open-Source](https://github.com/owner/repo)): Brief description.
```

Append a conditional note when installation depends on a flag:

```markdown
- [ToolName](https://example.com): Description. _Conditional: Installed when the X flag is enabled._
```

### For As-Needed Software

Include installation instructions:

```markdown
- [ToolName](https://example.com): Description. Available via brew, nix, cargo, or [download](https://example.com/download).
```

### Description Sourcing (Required)

Software summary lines must be source-backed, not inferred.

- Use at least one verified source: official product page, official store listing (App Store, Homebrew formula/cask page, Scoop/Winget/Flathub entry), or upstream docs/README.
- Preserve official product naming and capitalization in package and `mas` entries.
- Prefer concise factual behavior statements over marketing language.
- If sources conflict or no reliable source is available, use neutral wording and call out uncertainty in the change notes instead of guessing.

## Verification Checklist

Pick the cheapest verification that covers the changed behavior. Agents should prefer render and template checks before live install checks; commands that apply changes to the current machine are manual unless the task explicitly asks for them.

Baseline checks:

- [ ] **Markdown-only docs**: inspect the changed section with `sed -n` or `rg -n`
- [ ] **Software summary provenance** (when adding/changing README software descriptions): verify wording against official source links and confirm naming/capitalization matches the source
- [ ] **Chezmoi template syntax**: `scripts/chezmoi-execute-template <template>`
- [ ] **Managed target rendering**: `chezmoi cat --source-path <source-path>`
- [ ] **Final rendered diff**: `chezmoi diff`
- [ ] **Shell scripts**: `sh -n <script>` plus `shellcheck` when available
- [ ] **PowerShell scripts**: render with `chezmoi execute-template`; run PSScriptAnalyzer when available
- [ ] **Python helpers**: `uv run --with pytest pytest scripts/tests/<test_file>.py -q`
- [ ] **Cram scenarios**: `./test/run-cram test/cram/<suite>`
- [ ] **Linux package-flow changes**: the narrowest matching container test, for example `./script/test <distro>` or `./script/test -w <distro>` for GUI app paths

Manual or apply-time checks:

- [ ] **macOS**: `brew info <package>`, `brew list <package>`, or check `~/Applications/`
- [ ] **Windows**: `scoop list`, `winget list <id>`, or the known install path
- [ ] **Linux (Nix)**: `which <cmd>` shows the expected Nix store path
- [ ] **Linux (direct user install)**: `~/.local/bin/<cmd> --version`
- [ ] **Linux (Flatpak)**: `flatpak list | rg '<app-id>'`
- [ ] **Chimera**: `apk info <package>` or `flatpak list`
- [ ] **FreeBSD**: `pkg info <package>`

## Research Resources

When adding new software, check availability:

- **Nix**: [NixOS package search](https://search.nixos.org/packages)
- **Homebrew**: [Homebrew Formulae](https://formulae.brew.sh/)
- **winget**: [winget.run](https://winget.run/) or [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)
- **Scoop**: [Scoop](https://scoop.sh/)
- **Flatpak**: [Flathub](https://flathub.org/)
- **Chimera Linux**: [Chimera package search](https://pkgs.chimera-linux.org/)
- **FreeBSD**: [FreshPorts](https://www.freshports.org/)
