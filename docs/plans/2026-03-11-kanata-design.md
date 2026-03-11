# Kanata Cross-Platform Coverage Design

**Goal:** Add Kanata keyboard remapping support on Windows and Linux, with Nix Home Manager user service where supported and Chimera Linux system package fallback, while preserving existing macOS Karabiner-Elements usage.

## Scope

- **Platforms**: Windows, Linux (Nix-based), Chimera Linux (no Nix).
- **Guards**: `user_setup`, `not work`, `not ephemeral`.
- **Type**: CLI binary + user service/autostart.
- **Out of scope**: macOS changes (Karabiner-Elements remains primary).

## Architecture

- **Linux (Nix/Home Manager)**:
  - Prefer a built-in Home Manager module/service for Kanata if it exists.
  - If no module is available, add a local HM module that installs `pkgs.kanata` and defines a systemd user service.
- **Chimera Linux**:
  - Install via system package manager (apk).
  - Configure a user-level service/autostart mechanism (research whether `dinitctl --user` is appropriate; otherwise use XDG autostart).
- **Windows**:
  - Install via Scoop (CLI tool path).
  - Add autostart in `home/.chezmoiscripts/windows/run_onchange_after_30_configure-login-items.ps1.tmpl`.
  - Research whether Kanata self-registers on first run; otherwise create an explicit startup entry.

## Files Likely Involved

- `home/dot_config/home-manager/home.nix.tmpl`
- `home/dot_config/home-manager/modules/` (new module if needed)
- `scripts/setup-system-chimera.tmpl` (or Chimera-specific install path)
- `home/.chezmoiscripts/windows/run_onchange_before_25_install-tools.ps1.tmpl`
- `home/.chezmoiscripts/windows/run_onchange_after_30_configure-login-items.ps1.tmpl`
- `README.md` (CLI software entry)
- Issue #65 (Additional Task for kanata-tray on Linux)

## Research Tasks (Required Before Implementation)

1. **Home Manager support**: Check if `programs.kanata` or `services.kanata` exists in Home Manager and the expected configuration options.
2. **Nix package**: Confirm the package name and availability in nixpkgs.
3. **Chimera package**: Confirm kanata is in Chimera pkgs and the exact package name.
4. **Windows Scoop**: Confirm Scoop package name/bucket for kanata.
5. **Windows autostart**: Determine whether Kanata can register itself for startup; otherwise choose Registry Run or Startup folder strategy.
6. **Chimera autostart**: Confirm the proper user service mechanism (likely `dinitctl --user`, otherwise XDG autostart).

## Documentation Updates

- **README**: Add Kanata to appropriate CLI Software section with `_Conditional: user_setup, not work, not ephemeral._`
- **Issue #65**: Add Additional Task to evaluate `kanata-tray` on Linux (no table marker changes).

## Risks / Decisions

- Home Manager module availability determines whether we add a custom module.
- Windows autostart behavior affects whether we rely on first-run registration or create explicit startup entries.
- Chimera user service approach depends on confirmed service manager.
