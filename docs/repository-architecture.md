# Repository Architecture

This repository manages one user environment across macOS, Linux, FreeBSD,
and Windows. Chezmoi renders files into the home directory. Setup scripts add
system packages and prerequisites that do not belong in a home-directory
manager.

## Setup Progression

The entry points cover progressively narrower parts of setup:

1. Distro-specific `os-install` scripts install an operating system from a
   live environment. Arch and Chimera Linux provide this layer.
2. Distro-specific `setup-root` scripts create users and install enough of the
   base system for user-level setup. Arch, Chimera Linux, Debian, Fedora,
   FreeBSD, and Ubuntu provide this layer.
3. `script/bootstrap` installs prerequisites, clones the repository when
   needed, and initializes chezmoi. Higher-level setup scripts call it.
4. `script/setup-system` installs system packages, Nix, and other host-level
   prerequisites. It is run by a non-root user with sudo or doas access.
5. `script/setup` applies chezmoi source and performs user-level setup.
6. `script/setup-full` runs system setup followed by user setup.

For established machines, `script/update` coordinates reviewed updates to the
repository, external content, and Home Manager inputs.
`script/home-manager-switch` builds, compares, commits, and switches Home
Manager configuration. `script/update` calls it as part of the larger update
flow.

See the [README](../README.md#usage) for setup and update command examples.

## Top-Level Responsibilities

| Path | Responsibility |
| --- | --- |
| `home/` | Chezmoi source directory, selected by `.chezmoiroot` |
| `script/` | User entry points such as bootstrap, setup, testing, and updates |
| `scripts/` | Internal helpers, shared libraries, platform setup fragments, and optional utilities |
| `settings/` | Shared source settings and encrypted inputs consumed by generated configuration |
| `test/` | Pytest, Cram, Node, and container test infrastructure |
| `docs/` | Reference documentation and architectural decision records |
| `.github/` | GitHub Actions and repository metadata |

`script/` is the stable command surface for common operations. Code there may
delegate to lower-level programs under `scripts/` or `test/`.

## Chezmoi Source Layout

`home/` contains the source state that chezmoi renders into `$HOME`:

- `.chezmoi.toml.tmpl` detects the platform and machine role, collects prompts
  and environment overrides, and publishes template data.
- `.chezmoidata/` contains declarative data such as paths, fonts, and pinned
  external sources.
- `.chezmoiexternal.toml.tmpl` composes external definitions for tools,
  plugins, fonts, and application data.
- `.chezmoiignore.tmpl` excludes source according to platform and feature
  flags.
- `.chezmoiscripts/` contains ordered run scripts grouped into `darwin`,
  `linux`, `freebsd`, `windows`, and shared `posix` directories.
- `.chezmoitemplates/` contains reusable templates, including modular external
  definitions.

Chezmoi source names encode target metadata. For example, `dot_` becomes a
leading dot, `private_` restricts permissions, and `.tmpl` marks a file for
rendering. Use `chezmoi source-path <target>` rather than guessing the source
name.

## Source-to-Rendered Flow

A managed change passes through four layers:

1. Repository source under `home/`, `settings/`, or `scripts/` defines the
   desired state.
2. `.chezmoi.toml.tmpl`, `.chezmoidata/`, and environment overrides produce
   the data available to templates.
3. Chezmoi renders managed files and run scripts for the current machine.
4. `chezmoi apply` writes the rendered result into `$HOME` and runs eligible
   scripts.

Steps 1 through 3 are enough to inspect source and rendered output without
changing the current machine. Step 4 is the point where the change becomes
active in the live home directory. Resolve a target with `chezmoi source-path`,
inspect rendered content with `chezmoi cat --source-path` or
`scripts/chezmoi-execute-template`, then review `chezmoi diff`.

## Platform Organization

The repository supports macOS, Windows, FreeBSD, and several Linux families,
including Arch, Debian, Ubuntu, Fedora, Chimera Linux, and SteamOS. Shared
POSIX behavior belongs under `home/.chezmoiscripts/posix/`. Platform-specific
behavior belongs in the matching script or template directory. Chezmoi uses
its `darwin` OS identifier under `.chezmoiscripts/`, while repository-owned
setup files generally use `macos` in their names.

Installation policy varies because package managers and host capabilities
differ. The [software contribution guide](contributing-software.md) owns those
choices and platform-specific installation patterns.

## Related Documentation

- [Authoring Chezmoi Configuration](chezmoi-authoring.md)
- [Testing and Verification](testing.md)
- [Adding Software](contributing-software.md)
- [Architectural Decision Records](decisions/)
