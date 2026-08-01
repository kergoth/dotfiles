# whatcable

**Status:** Adopted — add to as-needed macOS utilities
**Evaluated:** 2026-08-01 (90-day re-evaluation; original: 2026-05-02)
**Repo:** https://github.com/darrylmorley/whatcable

## What it does

WhatCable is a macOS menu-bar utility that identifies USB-C and Thunderbolt cables and devices, reports charging wattage, cable certification, DisplayPort lane counts, and power delivery profiles. It also ships a `whatcable` CLI and a terminal dashboard (`--monitor`). All processing is local; no data is sent automatically.

## Recommendation

**Adopt.** Add to `docs/as-needed.md` under "As Needed GUI Software for macOS." All four revisit criteria from the original evaluation are met:

1. **Sustained commit activity** — exceeded by a wide margin. Over 50 stable (non-beta, non-emergency) releases shipped since May 2, 2026: v0.13.0 through v1.3.0 (released July 31, 2026), including the v1.0.0 milestone on June 13 and three minor stable series (v1.1.x, v1.2.x, v1.3.x). Release cadence is consistent and feature-driven, not emergency-only.

2. **External merged PRs** — 108 total merged PRs as of evaluation date, with multiple distinct external contributors: localization contributors (bovirus/Italian, jimmyorz/Traditional Chinese, yurii-shcherbiuk/Ukrainian), feature contributors (dhruvsheth10, jesserobbins), and bug-fix contributors (VailElla). Active community, not a solo project.

3. **Issue #23 (updater verification hardening)** — closed. The issue was opened May 1, 2026 by @durul and has since been closed. A related updater path fix shipped in v1.0.3 ("Critical security fix for self-update cleanup process"). No open security issues remain in the tracker.

4. **No unresolved silent regressions** — zero open regression issues. The single open bug (#401, USB-PD profiles not displayed on certain hardware) is a coverage gap, not a regression or silent failure.

## Key findings

- **Signing and notarization**: unchanged. App remains signed with a Developer ID and notarized by Apple. No Gatekeeper warnings.
- **Telemetry**: unchanged. Diagnostic data is opt-in and user-triggered only. Update checks poll the GitHub Releases API every ~6 hours with no personal data transmitted.
- **External Swift dependencies**: none. `Package.swift` declares only internal targets; no third-party Swift packages added.
- **Release quality**: stable releases have meaningful changelogs and increment version numbers consistently. Beta series (e.g., v1.3.0-beta.1 through beta.4) precede stable releases, showing a deliberate QA step.
- **Community health**: 108 merged PRs from a diverse contributor base; localization is especially active. Issue tracker is responsive — closed bugs include silent-failure fix (#407, Intel T2 Mac IOKit plugin) and third-party driver conflict (#462).
- **Update mechanism**: uses a custom in-app updater checking GitHub Releases. Updater cleanup path hardened in v1.0.3. The comprehensive verification hardening requested in issue #23 (exact asset names, full designated-requirement validation, deferred quarantine removal) was part of that closed issue's scope.

## Mitigation

**Issue #23 (closed):** The issue was filed May 1, 2026 and is now closed. The v1.0.3 release addressed the cleanup path bug. The broader verification hardening (exact asset naming, complete designated-requirement checks, deferred quarantine removal) was in scope of the closed issue. The closure without a linked PR visible externally means verification completeness cannot be confirmed from outside the repo, but no follow-up reports or CVEs have surfaced since closure. Treat as resolved pending any future regression report.

**Residual risk (low):** The updater does not use Sparkle, whose verification model is well-audited. The custom updater's full security posture remains partially opaque. Mitigated by: (a) the app is notarized so each update goes through Apple's process, (b) the update check is read-only API polling with no personal data, and (c) as-needed installation means exposure is bounded to machines where it's actively used.
