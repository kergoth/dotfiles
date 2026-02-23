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
│   ├── Linux (non-headless with Flatpak) → Flatpak
│   └── Linux (non-headless without Flatpak) → curl/AppImage installer
└── No (CLI tool)
    ├── Requires root/system-level installation?
    │   └── Yes → Platform system-setup script (scripts/setup-system-*.tmpl)
    ├── macOS → Homebrew formula (scripts/macos/Brewfile.tmpl)
    ├── Windows → Scoop (run_onchange_before_25_install-scoop-tools.ps1.tmpl)
    ├── Linux: Available in Nix? (check: https://search.nixos.org/packages)
    │   └── Yes → Add to home.nix.tmpl
    ├── Linux (non-Nix): Available as GitHub release binary?
    │   └── Yes → Chezmoi externals (home/.chezmoitemplates/external/)
    └── Available via language package manager?
        ├── Rust (cargo) → run_onchange_before_25_install-cargo-tools.tmpl
        ├── Go → run_onchange_before_25_install-go-tools.tmpl
        └── Python → run_onchange_after_10_install-uv-tools.tmpl
```

## Preference Hierarchy

When multiple installation methods are available, prefer them in this order:

1. **User installation over system installation** - Avoid requiring sudo/admin when possible
2. **Package managers over manual downloads** - Easier updates and dependency management
3. **Nix over Homebrew for CLI tools** - But use Homebrew casks for GUI apps on macOS
4. **Chezmoi externals over language package managers** - Pre-built binaries are faster (Linux fallback when Nix unavailable)
5. **Language package managers (cargo/go/uv) as fallback** - When no binary available
6. **System packages only when necessary** - For core OS utilities

## Platform Support Matrix

> **Note:** This matrix documents our current preferred installation methods, not every
> available option. For example, Flatpak is our current approach for Linux GUI apps, but
> AppImage, Snap, or native packages could also work. The decision tree and hierarchy above
> guide which method to use when multiple options exist.

| Platform | GUI Apps | CLI (Primary) | CLI (Fallback) | System-Level (admin/root) |
|----------|----------|---------------|----------------|---------------------------|
| macOS | Homebrew cask | Nix OR Homebrew formula | Cargo/Go | Brewfile-admin (mas + casks), system config |
| Windows | Scoop | Scoop | Cargo/Go/UV | winget, system config (Sophia Script) |
| Linux (Arch) | Flatpak | Nix | Externals → Cargo/Go | pacman, system services |
| Linux (Debian/Ubuntu) | Flatpak | Nix | Externals → Cargo/Go | apt, system services |
| Linux (Chimera) | Flatpak | apk (system) | Cargo/Go | apk, doas, system services |
| Linux (SteamOS) | N/A | N/A | N/A | Minimal (symlinks only) |
| FreeBSD | pkg/ports | pkg/ports | Cargo/Go | pkg, ports, doas, system services |

## File Reference

### User-Level Installation Files

| Purpose | File Path |
|---------|-----------|
| macOS Homebrew (user) | `scripts/macos/Brewfile.tmpl` |
| macOS Homebrew (admin) | `scripts/macos/Brewfile-admin.tmpl` |
| macOS App Store | `scripts/macos/Brewfile-admin.tmpl` (mas entries) |
| Windows GUI apps (user) | `home/.chezmoiscripts/windows/run_onchange_after_10_install-scoop-packages.ps1.tmpl` |
| Windows CLI tools (user) | `home/.chezmoiscripts/windows/run_onchange_before_25_install-scoop-tools.ps1.tmpl` |
| Linux GUI/CLI apps | `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl` |
| Nix packages | `home/dot_config/home-manager/home.nix.tmpl` |
| Chezmoi externals | `home/.chezmoitemplates/external/*.toml.tmpl` |
| Cargo tools | `home/.chezmoiscripts/*/run_onchange_before_25_install-cargo-tools.tmpl` |
| Go tools | `home/.chezmoiscripts/*/run_onchange_before_25_install-go-tools.tmpl` |
| Python/UV tools | `home/.chezmoiscripts/posix/run_onchange_after_10_install-uv-tools.tmpl` |

### System-Level Installation Files

| Platform | File Path |
|----------|-----------|
| macOS | `scripts/setup-system-macos.tmpl` |
| Linux (shared) | `scripts/setup-system-linux.tmpl` |
| Arch Linux | `scripts/setup-system-arch.tmpl` |
| Debian | `scripts/setup-system-debian` |
| Ubuntu | `scripts/setup-system-ubuntu` |
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
| `.use_nix` | Nix is available | Skip externals when true |
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

```powershell
# Inside the {{ if not .headless }} block:

# App available in both Scoop and winget - use helper
Install-Scoop-IfNotPresent obsidian Obsidian.Obsidian | Out-Null

# App only available in Scoop - install directly
scoop install zed

# Conditional
{{    if and .coding .containers (not .ephemeral) -}}
Install-Scoop-IfNotPresent devpod LoftLabs.DevPod | Out-Null
{{    end -}}
```

**Two installation patterns:**

1. **`Install-Scoop-IfNotPresent <scoop-name> <winget-id>`** - For apps in both registries
   - Installs via Scoop (user-level, no admin required)
   - Skips if already present via winget

2. **`scoop install <scoop-name>`** - For Scoop-only apps
   - Use when the app is not available in winget
   - Example: Zed editor

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

### 6. Chezmoi Externals (GitHub Release Binaries)

**File:** `home/.chezmoitemplates/external/<category>.toml.tmpl`

#### Key Considerations

1. **Check platform availability first** - Not all tools have binaries for all platforms
2. **Handle different naming conventions** - Release files use varied naming schemes
3. **Consider archive structure** - Binary may be at root or nested in directories
4. **Handle version prefixes** - Some use `v1.0.0`, others use `1.0.0`

#### Standard Boilerplate

```go
{{- $os := .chezmoi.os -}}
{{- $arch := .chezmoi.arch -}}
{{- $binarch := $arch -}}
{{- if eq .chezmoi.arch "amd64" -}}
{{-   $binarch = "x86_64" -}}
{{- else if eq .chezmoi.arch "arm64" -}}
{{-   $binarch = "aarch64" -}}
{{- end -}}
{{- $binpath := ".local/bin" -}}
{{- $binsuffix := "" -}}
{{- if eq $os "windows" -}}
{{-   $binpath = "AppData/Local/Programs/bin" -}}
{{-   $binsuffix = ".exe" -}}
{{- end -}}
```

#### Pattern: Platform-Specific Target Strings

Use empty string for unsupported platforms, then check `(ne $target "")`:

```go
{{- $tool_version := (gitHubLatestRelease "owner/repo").TagName -}}
{{- $tool_target := "" -}}
{{- $tool_ext := "tar.gz" -}}
{{- if eq $os "darwin" -}}
{{-   if eq $arch "amd64" -}}
{{-     $tool_target = "x86_64-apple-darwin" -}}
{{-   else if eq $arch "arm64" -}}
{{-     $tool_target = "aarch64-apple-darwin" -}}
{{-   end -}}
{{- else if eq $os "linux" -}}
{{-   if eq $arch "amd64" -}}
{{-     $tool_target = "x86_64-unknown-linux-musl" -}}
{{-   else if eq $arch "arm64" -}}
{{-     $tool_target = "aarch64-unknown-linux-gnu" -}}
{{-   end -}}
{{- else if eq $os "windows" -}}
{{-   $tool_ext = "zip" -}}
{{-   if eq $arch "amd64" -}}
{{-     $tool_target = "x86_64-pc-windows-msvc" -}}
{{-   end -}}
{{- end -}}

{{/* Only install if target exists and not using Nix/FreeBSD/Chimera */}}
{{ if and (ne $tool_target "") (not (or .use_nix (eq .chezmoi.os "freebsd") (eq .osid "linux-chimera"))) }}
...
{{ end }}
```

#### Pattern: Simple Direct Binary Download

For tools with simple naming like `tool-os-arch`:

```go
["{{ $binpath }}/jq{{ $binsuffix }}"]
  type = "file"
  url = "https://github.com/jqlang/jq/releases/download/{{ $jq_version }}/jq-{{ $jq_os }}-{{ $arch }}{{ $binsuffix }}"
  executable = true
```

#### Pattern: Archive with Binary at Root

When archive contains binary directly (no subdirectory):

```go
["{{ $binpath }}/sad{{ $binsuffix }}"]
  type = "archive-file"
  url = "https://github.com/ms-jpq/sad/releases/download/{{ $sad_version }}/{{ $sad_target }}.zip"
  path = "sad{{ $binsuffix }}"
  executable = true
  {{/* No stripComponents - binary is at archive root */}}
```

#### Pattern: Archive with Nested Binary

When archive contains a directory with the binary inside:

```go
["{{ $binpath }}/bat{{ $binsuffix }}"]
  type = "archive-file"
  url = "https://github.com/sharkdp/bat/releases/download/{{ $bat_version }}/bat-{{ $bat_version }}-{{ $bat_target }}.{{ $bat_ext }}"
  path = "bat{{ $binsuffix }}"
  executable = true
  stripComponents = 1  {{/* Skip the outer directory */}}
```

#### Pattern: Version Prefix Handling

Some releases use `v1.0.0`, others use `1.0.0`:

```go
{{/* Keep the v prefix */}}
{{- $version := (gitHubLatestRelease "owner/repo").TagName -}}

{{/* Remove the v prefix */}}
{{- $version := (gitHubLatestRelease "owner/repo").TagName | trimPrefix "v" -}}
```

#### Common Naming Conventions

| Style | Example | Typical Use |
|-------|---------|-------------|
| Simple | `tool-linux-amd64` | Go tools |
| Rust triple | `tool-x86_64-unknown-linux-musl` | Rust tools |
| Platform name | `tool-macos-arm64` | Various |
| Version in name | `tool-v1.0.0-linux-amd64.tar.gz` | Common |

#### Troubleshooting Externals

1. **Download the release manually** to inspect the archive structure
2. **Check if `stripComponents` is needed** - look for nested directories
3. **Verify the exact filename pattern** - case sensitivity matters
4. **Test on each platform** you want to support

### 7. Linux Flatpak (GUI Apps)

**File:** `home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl`

```go
{{/* Check if flatpak is available */}}
{{-   $flatpak = includeTemplate "find-tool" (dict "root" . "tool" "flatpak") -}}

{{/* Install via flatpak when available and not headless */}}
{{-   if and (not .headless) $flatpak }}
msg "Installing AppName from Flathub"
flatpak install -y --user flathub org.example.AppName || true
{{-   end }}
```

### 8. Linux curl Installer (CLI)

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

### 9. Cargo Tools (Rust)

**File:** `home/.chezmoiscripts/linux/run_onchange_before_25_install-cargo-tools.tmpl`

```go
{{- if and .user_setup (not .use_nix) (eq .osid "linux-chimera") -}}
{{-   $cargo_tools := dict "toolcmd" "crate-name" -}}
{{-   $to_install := includeTemplate "packagesForMissingTools" (dict "root" . "packages" $cargo_tools) | fromJson -}}
{{-   if $to_install -}}
{{-     $cargo := includeTemplate "find-tool" (dict "root" . "tool" "cargo") -}}
{{-     if $cargo -}}
#!/bin/sh
set -eu
{{-       range $to_install }}
echo >&2 "Installing {{ . }}"
"{{ $cargo }}" install --locked {{ . }}
{{-       end }}
{{-     end }}
{{-   end }}
{{- end }}
```

### 10. Go Tools

**File:** `home/.chezmoiscripts/linux/run_onchange_before_25_install-go-tools.tmpl`

```go
{{-   $go_tools := dict "cmdname" "github.com/owner/repo/...@latest" -}}
{{-   $to_install := includeTemplate "packagesForMissingTools" (dict "root" . "packages" $go_tools) | fromJson -}}
```

### 11. Python/UV Tools

**File:** `home/.chezmoiscripts/posix/run_onchange_after_10_install-uv-tools.tmpl`

```go
{{-   $uv_tools := dict "cmdname" "package-name" -}}
{{-   $to_install := includeTemplate "packagesForMissingTools" (dict "root" . "packages" $uv_tools) | fromJson -}}
```

### 12. Chimera Linux (apk + Flatpak)

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

### find-tool

Locates executables across standard paths:

```go
{{- $tool := includeTemplate "find-tool" (dict "root" . "tool" "toolname") -}}
{{- if not $tool }}
# Tool not found, install it
{{- end }}
```

### packagesForMissingTools

Returns list of packages needed for missing tools:

```go
{{- $tools := dict "cmd1" "pkg1" "cmd2" "pkg2" -}}
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

**Exception: UV tools use `after_`** because UV itself is installed via chezmoi externals on some platforms. Since externals are processed during dotfiles application, UV tools must wait until after.

**Examples:**
- `run_onchange_before_25_install-cargo-tools.tmpl` - CLI tools via cargo
- `run_onchange_before_25_install-go-tools.tmpl` - CLI tools via go
- `run_onchange_after_10_install-uv-tools.tmpl` - Python tools (UV installed via externals)
- `run_onchange_after_10_install-apps.tmpl` - GUI apps (Zed, DevPod)
- `run_onchange_after_10_install-scoop-packages.ps1.tmpl` - GUI apps on Windows

| Number | Purpose |
|--------|---------|
| `00_` | Bootstrap (1Password, age key) |
| `10_` | Early setup (homebrew install), GUI apps |
| `20_` | Package managers (home-manager) |
| `25_` | Language tools (cargo, go) - CLI |
| `30_` | Configuration |
| `40_` | Updates |
| `50_` | Final setup (shell, SSH) |

## README Documentation

When adding software, update `README.md` in the appropriate section:

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
