# Adding Software to This Dotfiles Repository

This guide documents how to systematically add software installations to this chezmoi-managed dotfiles repository. It covers all supported platforms, installation methods, file locations, and conditional logic patterns.

## Quick Reference: Decision Tree

```
Is this a GUI application?
├── Yes
│   ├── macOS (user) → Homebrew cask (scripts/macos/Brewfile.tmpl)
│   ├── macOS (admin) → Homebrew cask + mas (scripts/macos/Brewfile-admin.tmpl)
│   ├── Windows (user) → Scoop (home/.chezmoiscripts/windows/run_onchange_after_10_install-scoop-packages.ps1.tmpl)
│   ├── Windows (admin) → winget (scripts/setup-system-windows.ps1.tmpl)
│   ├── Linux (non-headless) → Flatpak (universal on all supported distros)
│   └── Linux (Chimera, glibc GUI app unavailable on Flathub or Flatpak sandbox inadequate) → distrobox container (Ubuntu 22.04)
└── No (CLI tool)
    ├── Requires root/system-level installation?
    │   └── Yes → Platform system-setup script (scripts/setup-system-*.tmpl)
    ├── macOS → Homebrew formula (scripts/macos/Brewfile.tmpl)
    ├── Windows → Scoop (run_onchange_before_25_install-tools.ps1.tmpl)
    ├── Available in Nix? (check: https://search.nixos.org/packages)
    │   └── Yes → Add to home.nix.tmpl
    ├── Available via language package manager?
    │   ├── Rust (cargo) → install-tools (limited)
    │   └── Python (uv) → install-tools
    ├── Chimera (non-Nix): Available in apk repos?
    │   ├── Yes → system packages (scripts/setup-system-chimera.tmpl)
    │   └── No → eget via install-tools
    └── FreeBSD: Available in pkg/ports?
        └── Yes → system packages (scripts/setup-system-freebsd.tmpl)
```

## Preference Hierarchy

When multiple installation methods are available, prefer them in this order:

1. **User installation over system installation** - Avoid requiring sudo/admin when possible
2. **Package managers over manual downloads** - Easier updates and dependency management
3. **Nix over Homebrew for CLI tools** - But use Homebrew casks for GUI apps on macOS
4. **Language package managers (cargo/uv) over system packages** - Except on Chimera where apk is preferred since Nix is unavailable
5. **System packages when Nix is unavailable** - Chimera (apk), FreeBSD (pkg/ports)
6. **eget for Chimera gaps** - Tools not available in apk repos and not installable via cargo/uv

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
| Linux (SteamOS) | N/A | Nix | cargo/uv | Minimal |
| FreeBSD | pkg/ports | pkg/ports | cargo/uv | pkg, ports, doas, system services |

## File Reference

### User-Level Installation Files

| Purpose | File Path |
|---------|-----------|
| macOS Homebrew (user) | `scripts/macos/Brewfile.tmpl` |
| macOS Homebrew (admin) | `scripts/macos/Brewfile-admin.tmpl` |
| macOS App Store | `scripts/macos/Brewfile-admin.tmpl` (mas entries) |
| Windows GUI apps (user) | `home/.chezmoiscripts/windows/run_onchange_after_10_install-scoop-packages.ps1.tmpl` |
| Windows CLI tools (user) | `home/.chezmoiscripts/windows/run_onchange_before_25_install-tools.ps1.tmpl` |
| Linux GUI/CLI apps | `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl` |
| Chimera distrobox (host) | `home/.chezmoiscripts/linux/run_onchange_after_20_setup-distrobox.tmpl` |
| Chimera distrobox (container) | `scripts/setup-distrobox-chimera.sh` |
| Nix packages | `home/dot_config/home-manager/home.nix.tmpl` |
| CLI tools (eget/cargo/uv) | `home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl` |

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

Available flags from `.chezmoi.toml.tmpl` for conditional installation:

| Flag | Purpose | Typical Use |
|------|---------|-------------|
| `.ephemeral` | Temporary machine (VM, container) | Skip persistent/large apps |
| `.headless` | No GUI available | Skip all GUI apps |
| `.personal` | Personal machine with secrets | Personal-only apps |
| `.work` | Work machine | Work tools, skip personal |
| `.coding` | Development workstation | Dev tools (IDEs, DevPod) |
| `.containers` | Container runtime needed | Docker, Podman, DevPod |
| `.gaming` | Gaming machine | Steam, game clients |
| `.video` | Video playback needed | VLC, media players |
| `.music` | Music playback | Music apps |
| `.music_library` | Manage music library | MusicBrainz Picard |
| `.ebook_library` | Manage ebook library | Calibre |
| `.gaming_device_library` | Manage gaming device library | ScummVM, ROM tools |
| `.retro_computing` | Retro computing emulation | 86Box |
| `.use_nix` | Nix is available | Use Nix/home-manager for package management |
| `.user_setup` | Full user setup (not just dotfiles) | Skip package installation |
| `.secrets` | Has access to secrets | Encryption, 1Password |
| `.steamdeck` | Running on Steam Deck | SteamOS-specific setup |
| `.wsl2` | Running in WSL2 | WSL-specific setup |
| `.devpod` | Running in DevPod container | Skip GPG setup |

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
{{ if and .coding .containers (not .ephemeral) (not .headless) -}}
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

### 4. Windows Scoop (GUI Apps - User Level)

**File:** `home/.chezmoiscripts/windows/run_onchange_after_10_install-scoop-packages.ps1.tmpl`

New additions use `find-tool` in the template header + bare `scoop install` in the body:

```powershell
{{/* HEADER — before the main {{ if and .user_setup (not .headless) }} guard */}}
{{- $appname := "" -}}
{{- if and .user_setup (not .headless) .feature_flag (not .work) -}}
{{-   $appname = includeTemplate "find-tool" (dict "root" . "tool" "appname") -}}
{{- end -}}

{{/* BODY — inside the conditional block for the feature flag */}}
{{      if and .feature_flag (not $appname) -}}
scoop install appname
{{-     end }}
```

**Legacy pattern** (`Install-Scoop-IfNotPresent <scoop-name> <winget-id>`): a winget-compatibility shim present in existing code. It checks if the app is already installed via winget before installing via Scoop. Not used for new additions — use `find-tool` + `scoop install` instead.

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
{{- if .containers }}
    docker
    docker-compose
{{- end }}

  # Platform-specific (Linux only for GUI, macOS uses Homebrew)
  ] ++ lib.optionals stdenv.isLinux [
    glibcLocales
  {{- if and .coding .containers (not .ephemeral) (not .headless) }}
    devpod
  {{- end }}
  ];
```

**Note:** For macOS, prefer Homebrew casks for GUI apps. Only add CLI tools to the main packages list that should be shared across platforms.

### 6. Linux Flatpak (GUI Apps)

**File:** `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl`

> **Critical: two-phase template.** The header computes `$need_install`; the script body only emits if `$need_install` is true. New apps must be added to **both** the header (tool detection + `$need_install` trigger) and the body (flatpak install command). Adding only to the body means the script won't run when only that app is missing.

```go
{{/* HEADER — add tool detection and $need_install trigger (inside the user_setup guard) */}}
{{-   if .feature_flag -}}
{{-     $appname = includeTemplate "find-tool" (dict "root" . "tool" "appname") -}}
{{-   end -}}
{{-   if and .feature_flag (not $appname) $flatpak -}}{{- $need_install = true -}}{{- end -}}

{{/* BODY — add install command (inside the $need_install block) */}}
{{-   if and .feature_flag (not $appname) $flatpak }}
msg "Installing AppName from Flathub"
flatpak install -y --user flathub org.example.AppName || true
{{-   end }}
```

### 7. Linux curl Installer (CLI)

**File:** `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl`

```bash
{{-   if and .some_flag (not $existing_tool) }}
msg "Installing ToolName"
tool_arch="amd64"
case "$(uname -m)" in
    aarch64|arm64) tool_arch="arm64" ;;
esac
curl -L -o /tmp/tool "https://github.com/owner/repo/releases/latest/download/tool-linux-$tool_arch"
install -c -m 0755 /tmp/tool "$HOME/.local/bin/tool"
rm -f /tmp/tool
{{-   end }}
```

### 8. CLI Tools via install-tools (eget/cargo/uv)

**File (POSIX):** `home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl`
**File (Windows):** `home/.chezmoiscripts/windows/run_onchange_before_25_install-tools.ps1.tmpl`

This unified script handles all non-package-manager CLI tool installation. It only runs when `.user_setup` is true and `.use_nix` is false (i.e., platforms without Nix). Tools are organized into three categories:

**eget tools** — GitHub release binaries for Chimera gaps (tools not in apk repos):

```go
{{- $eget_tools := dict -}}
{{- if eq .osid "linux-chimera" -}}
{{-   $_ := set $eget_tools "choose" "theryangeary/choose" -}}
{{-   $_ := set $eget_tools "sd" "chmln/sd" -}}
{{-   $_ := set $eget_tools "shellcheck" "-a xz koalaman/shellcheck" -}}
{{-   {{/* ... */}} -}}
{{- end -}}
```

**cargo tools** — very limited (currently only fclones on non-amd64 Chimera):

```go
{{- $cargo_tools := dict -}}
{{- if and (eq .osid "linux-chimera") (ne .chezmoi.arch "amd64") -}}
{{-   $_ := set $cargo_tools "fclones" "fclones" -}}
{{- end -}}
```

**uv tools** — Python tools installed via `uv tool install`:

```go
{{- $uv_tools := dict "git-imerge" "git-imerge" "git-revise" "git-revise" -}}
```

All three use the `packagesForMissingTools` helper to skip already-installed tools. If eget isn't already present, the script bootstraps it automatically before installing eget tools.

The Windows version follows the same pattern but installs Scoop packages as its primary tool source, with cargo and uv as secondary sources.

### 9. Chimera Linux Distrobox (glibc GUI Apps)

For glibc-linked GUI apps on Chimera that are either unavailable on Flathub or where Flatpak sandboxing is inappropriate (e.g., cross-app IPC, DE biometric integration, unrestricted filesystem access), use the Ubuntu 22.04 distrobox. The distrobox shares `$HOME` with the host and exports `.desktop` files so apps appear in the launcher.

Add apps to `scripts/setup-distrobox-chimera.sh` — the host script (`run_onchange_after_20_setup-distrobox.tmpl`) re-runs automatically when `setup-distrobox-chimera.sh` changes via sha256sum in the template header, so no changes to the host script are needed.

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

Conditions: host script runs only when `eq .osid "linux-chimera"` and `.containers` (Podman/distrobox) and `not .headless` and `not .ephemeral` and not already inside a container (`not (env "CONTAINER_ID")`).

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

All three helpers search path lists defined in `paths.yml` data — they do **not** use `lookPath`, so results are consistent regardless of the invoking shell's `$PATH`.

### find-tool

Locates a single executable. Accepts optional `home_paths` (bool, default true) and `system_paths` (bool, default true) to control which path sets are searched:

```go
{{- $tool := includeTemplate "find-tool" (dict "root" . "tool" "toolname") -}}
{{- if not $tool }}
# Tool not found, install it
{{- end }}

{{/* System-paths only (e.g. checking a system-installed binary) */}}
{{- $tool := includeTemplate "find-tool" (dict "root" . "tool" "toolname" "home_paths" false) -}}
```

### availableTools

Checks multiple tools at once. Same `home_paths`/`system_paths` arguments. Returns a dict of `cmd→path` (empty string if not found):

```go
{{- $results := includeTemplate "availableTools" (dict "root" . "tools" (list "zoxide" "atuin" "fzf")) | fromJson -}}
```

### packagesForMissingTools

Wraps `availableTools`. Takes a dict of `cmd→install-spec`, returns only the install specs whose commands are missing. The install spec is whatever string the caller needs — a bare package name, or a full argument string like `--git https://github.com/owner/repo` for cargo. Same `home_paths`/`system_paths` arguments. Prefer this over multiple `find-tool` calls when checking more than 2–3 tools:

```go
{{/* Package names */}}
{{- $tools := dict "cmd1" "pkg1" "cmd2" "pkg2" -}}

{{/* Cargo: install spec includes flags */}}
{{- $cargo_tools := dict "choose" "--git https://github.com/theryangeary/choose" -}}

{{- $to_install := includeTemplate "packagesForMissingTools" (dict "root" . "packages" $tools) | fromJson -}}
{{- range $to_install }}
# Install {{ . }}
{{- end }}
```

## Common Conditional Patterns

```go
# GUI app with multiple requirements
{{ if and .coding .containers (not .ephemeral) (not .headless) -}}

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

Format: `run_[onchange_][before|after]_NN_description[.ps1].tmpl`

| Prefix | Meaning |
|--------|---------|
| `run_` | Always runs |
| `run_onchange_` | Runs only when content changes |
| `before_` | Before dotfiles applied |
| `after_` | After dotfiles applied |

### Critical: CLI vs GUI Timing

**CLI tools should use `before_` scripts** because:
- Dotfile templates may use `find-tool` to detect CLI tools
- Tool availability affects generated configuration
- CLI tools are typically small and fast to install

**GUI apps should use `after_` scripts** because:
- GUI apps don't affect dotfile templates
- GUI apps are often large and slow to install
- Delaying dotfiles for GUI installation is unnecessary

**Examples:**
- `run_onchange_before_25_install-tools.tmpl` - CLI tools via eget/cargo/uv (POSIX)
- `run_onchange_before_25_install-tools.ps1.tmpl` - CLI tools via Scoop/cargo/uv (Windows)
- `run_onchange_after_10_install-apps.tmpl` - GUI apps (Zed, DevPod)
- `run_onchange_after_10_install-scoop-packages.ps1.tmpl` - GUI apps on Windows

| Number | Purpose |
|--------|---------|
| `00_` | Bootstrap (1Password, age key) |
| `10_` | Early setup (homebrew install), GUI apps |
| `20_` | Package managers (home-manager) |
| `25_` | CLI tools (eget, cargo, uv) |
| `30_` | Configuration |
| `40_` | Updates |
| `50_` | Final setup (shell, SSH) |

## README Documentation

When adding software, update `README.md` in the appropriate section:

### Section Selection

Use the **most specific section whose platform list matches where the software is actually installed**. When a platform is added, move the entry up to the broader section rather than duplicating it. No entry should appear in more than one section.

**CLI Software** (`### Installed CLI Software` and subsections):
- Main section — all supported platforms
- `#### CLI Software on Linux, macOS, and FreeBSD` — excludes Windows
- `#### CLI Software on Linux and macOS` — excludes FreeBSD and Windows
- `#### CLI Software on Linux (non-Chimera), macOS, FreeBSD, and Windows` — excludes Chimera
- Narrower subsections — single platform or distro (FreeBSD, macOS, Windows, Linux, Arch, WSL2, Chimera)

**GUI Software** (`### Installed GUI Software` and subsections):
- Main section — all supported platforms including FreeBSD
- `#### GUI Software on Windows, macOS, and Linux` — excludes FreeBSD
- `#### GUI Software on Windows and macOS` — excludes Linux and FreeBSD
- Platform-specific subsections — single platform, or macOS version-gated

**As-Needed Software** (`### As needed CLI Software`): not auto-installed. Include `Available via brew, nix, scoop, ...` install guidance instead of conditional notes.

### For Always-Installed Software

```markdown
### Installed CLI Software

- [ToolName](https://example.com) ([Open-Source](https://github.com/owner/repo)): Brief description.
```

### For Conditional Software

```markdown
- [ToolName](https://example.com): Description. _Conditional: This is installed when the X flag is enabled._
```

### For As-Needed Software (not auto-installed)

Include installation instructions:

```markdown
- [ToolName](https://example.com): Description. Available via brew, nix, cargo, or [download](https://example.com/download).
```

## Verification Checklist

After adding software, verify on each applicable platform:

- [ ] **macOS**: `brew info <package>` or check `~/Applications/`
- [ ] **Windows**: `winget list <id>` or `scoop list`
- [ ] **Linux (Nix)**: `which <cmd>` shows Nix store path
- [ ] **Linux (non-Nix)**: `~/.local/bin/<cmd> --version`
- [ ] **Linux (Flatpak)**: `flatpak list | grep <app>`
- [ ] **Linux container test**: `./script/test -w <distro>` (workstation mode: enables GUI app installs; omit `-w` for headless/CLI-only changes)
- [ ] **Chimera**: `apk info <package>` or `flatpak list`
- [ ] **FreeBSD**: `pkg info <package>`

## Research Resources

When adding new software, check availability:

- **Nix**: https://search.nixos.org/packages
- **Homebrew**: https://formulae.brew.sh/
- **winget**: https://winget.run/ or https://github.com/microsoft/winget-pkgs
- **Scoop**: https://scoop.sh/
- **Flatpak**: https://flathub.org/
- **Chimera Linux**: https://pkgs.chimera-linux.org/
- **FreeBSD**: https://www.freshports.org/
