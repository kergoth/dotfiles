# Authoring Chezmoi Configuration

This guide records the intent behind repository-specific template data and
source patterns. `chezmoi data` is authoritative for values resolved on the
current machine. It cannot explain why a flag exists or what behavior it
should control.

## Edit Source, Not Rendered Files

Edit files in this repository, not rendered targets under `$HOME`. Chezmoi
will overwrite direct target edits on the next apply.

These commands inspect source and rendered output before the live home
directory is changed:

```console
# Resolve a managed target to its repository source.
chezmoi source-path ~/.config/zsh/.zshrc

# Render a managed target without applying it.
chezmoi cat --source-path ~/.config/zsh/.zshrc

# Render a source template directly.
scripts/chezmoi-execute-template home/dot_config/zsh/dot_zprofile.tmpl

# Review all changes that chezmoi would apply.
chezmoi diff
```

`chezmoi apply` changes the live home directory and may run setup scripts. Use
it when the rendered change is ready to become active on the current machine.

## Data and Template Variables

`.chezmoi.toml.tmpl` computes machine-specific state and publishes it under
`[data]`. Templates read those values as `.name`, for example `.headless`.
Some values come from platform detection, known-host defaults, prompts, prior
chezmoi data, or `DOTFILES_*` environment overrides.

### Platform Detection

| Variable | Intent |
| --- | --- |
| `.osid` | Distinguish the OS and, on Linux, the distribution. Values include `darwin`, `freebsd`, `windows`, and `linux-<id>`. |
| `.hostname` | Select known-host defaults and host-specific data. |
| `.wsl2` | Gate behavior that differs inside Windows Subsystem for Linux. |
| `.steamdeck` | Select SteamOS and handheld-specific setup. |
| `.devpod` | Identify a DevPod development container and avoid host-oriented setup. |
| `.has_init` | Report whether service-management commands can be used. |
| `.systemd_user_services` | Enable persistent systemd user units only where systemd, Nix, and a non-ephemeral Linux host are all available. |

macOS also publishes `.macos_major_version`, `.macos_version`,
`.macos_split_user`, and `.macos_admin_user`. These select version-gated
settings and the optional split administrator account. Steam Deck systems add
emulator choices and paths only when applicable.

### Machine Roles and Capabilities

| Variable | Intent |
| --- | --- |
| `.ephemeral` | Mark short-lived VMs, containers, cloud hosts, and sandboxes where persistent jobs or large long-lived setup is inappropriate. |
| `.headless` | Mark machines without a display or local input so GUI setup can be skipped. This is independent of `.ephemeral`. |
| `.personal` | Select personal configuration and permit personal secret access when other safety conditions allow it. |
| `.work` | Select work configuration and the work identity. It is mutually exclusive with `.personal` when explicitly overridden. |
| `.secrets` | Report that the machine may decrypt its selected secret set. By default this requires a personal or work role on a persistent, non-Steam-Deck host. |
| `.user_setup` | Distinguish full user setup from dotfiles-only rendering. Package installation should be gated by this flag. |
| `.use_nix` | Select Nix and Home Manager where the platform supports them. |
| `.container_runtime` | Request installation and configuration of a container runtime. |
| `.container_runtime_crossarch` | Request cross-architecture container support in addition to the base runtime. |

`.skip_gpg` and `.skip_gpg_secret_import` suppress GPG work in environments
where an agent socket already exists or a test explicitly disables secret-key
import.

### Software Use Case Flags

| Variable | Intent |
| --- | --- |
| `.coding` | Install development tools beyond basic shell scripting support. |
| `.gaming` | Install game clients and gaming configuration. |
| `.video` | Install local video playback software. |
| `.music` | Install music playback software. |
| `.music_library` | Install tools for managing a music collection. |
| `.ebook_library` | Install tools for managing an ebook collection. |
| `.gaming_device_library` | Install tools for managing handheld and other gaming-device libraries. |
| `.retro_computing` | Install retro-computing emulators and related tools. |

Combine role, capability, and software use case flags narrowly. For example, a
GUI development tool may require `.coding`, a non-headless host, and a
supported installation method. The [software contribution guide](contributing-software.md)
contains installation-specific examples.

## Run Script Naming and Timing

Chezmoi interprets run-script names:

| Name component | Meaning |
| --- | --- |
| `run_` | Run whenever the script is included in an apply. |
| `run_once_` | Run once for a given script identity. |
| `run_onchange_` | Run when the rendered script content changes. |
| `before_` | Run before managed files are applied. |
| `after_` | Run after managed files are applied. |
| `NN_` | Order scripts numerically within a phase. |

The repository uses names such as
`run_onchange_before_25_install-tools.tmpl` and
`run_onchange_after_10_install-apps.tmpl`. CLI tools normally install in a
`before_` script because templates may detect them while rendering dependent
configuration. GUI applications normally install in an `after_` script
because they do not affect rendered dotfiles and can take longer to install.

Use existing numeric phases before creating another:

| Prefix | Existing purpose |
| --- | --- |
| `00_` | Bootstrap or migration |
| `05_` to `12_` | Credentials and early prerequisites |
| `20_` to `25_` | Package managers and tools |
| `30_` to `35_` | Configuration |
| `40_` | Updates and linked external content |
| `50_` | Final agent, shell, and SSH configuration |

## Shared Template and Script Helpers

Maintained shell scripts should source `scripts/common.sh`. PowerShell scripts
should use `scripts/common.ps1`. Inspect those files before adding a helper so
the implementation does not acquire a second copy of existing package,
logging, privilege, or platform behavior.

Three chezmoi templates locate tools using path lists from `paths.yml`, not
the invoking shell's `$PATH`:

- `find-tool` locates one executable.
- `availableTools` returns paths for several executable names.
- `packagesForMissingTools` maps missing commands to caller-provided install
  specifications.

All accept `home_paths` and `system_paths` booleans, both true by default.
Disable one when installation scope matters, such as checking only system
paths before a system package operation.

For one tool:

```go-template
{{- $tool := includeTemplate "find-tool" (dict "root" . "tool" "toolname") -}}
{{- if not $tool }}
# Install toolname.
{{- end }}
```

For a package set:

```go-template
{{- $packages := dict "cmd1" "pkg1" "cmd2" "pkg2" -}}
{{- $missing := includeTemplate "packagesForMissingTools" (dict "root" . "packages" $packages) | fromJson -}}
```

Use individual `find-tool` calls for one to three commands. Use
`packagesForMissingTools` when a package installer handles a larger set.

## Secrets

The README describes age encryption and identity bootstrap. Non-managed
encrypted fragments can be included and decrypted inside a template. Work-only
external definitions use this pattern so private source locations are not
exposed in the public repository.

Use the repository's encrypted-file editor rather than decrypting secrets into
an untracked plaintext file.

## Runtime Directories

Git cannot track an empty directory. To have chezmoi create one, add a `.keep`
file under its `home/` source path.

When a managed directory will contain caches, state, or other tool-generated
files, whitelist the directory in `.chezmoiignore.tmpl` and ignore its
contents. This lets chezmoi create the directory without trying to own runtime
files. `.local/state/zsh` and `.local/share/wget` are examples.

A directory that belongs to chezmoi should be represented in the source tree,
rather than created separately by a run script.

## Removing Managed Files

`.chezmoiremove.tmpl` prompts interactively. Reserve it for one-time removal of
obsolete managed files that will not reappear.

For generated state or paths that another tool may recreate, use
noninteractive cleanup in an appropriate migration script. Existing XDG path
cleanup lives in `run_onchange_after_00_migrate-xdg-paths`.

## Troubleshooting

Inspect the current resolved data and its source:

```console
chezmoi data
```

Render a failing template directly to expose syntax or missing-data errors:

```console
scripts/chezmoi-execute-template home/.chezmoiscripts/linux/run_onchange_after_10_install-apps.tmpl
```

For managed targets, prefer chezmoi's renderer:

```console
chezmoi cat --source-path ~/.config/zsh/.zshrc
```

To debug an eligible script without applying all managed state, render it and
pipe the result to the relevant interpreter with tracing. Check
`chezmoi status` first when a `run_once_` or `run_onchange_` script did not run.
Chezmoi may consider its state current.

## Related Documentation

- [Repository Architecture](repository-architecture.md)
- [Adding Software](contributing-software.md)
- [README setup and usage](../README.md#usage)
