---
status: accepted
date: 2026-11-24
decision-makers: kergoth
---

# Pin the Pi Harness Through Dotfiles-Managed Releases

## Context and Problem Statement

The Pi agent harness installed itself through its own installer, so the
installed version was whatever the installer or `pi update` last produced. The
dotfiles declared `pi` in `git-lock.yml` only as a bootstrap npm version used
when `pi` was absent, which meant the declared version and the running version
drifted silently. Because the harness and its extension packages only work
together at compatible versions, an unpinned harness makes extension pins
meaningless: a `pi update` could move the harness past an extension's
supported range without any reviewed change.

Upstream offers no version selection: `install.sh` has no version flag, and
`pi update` reads the latest version from a version-check endpoint. The
per-version artifacts that its updater already consumes are published, so a
pinned install can be assembled from them.

## Decision Drivers

* Dotfiles is the single source of truth for tool versions, with one reviewed
  commit per bump
* Installs must work without `sudo`, as the invoking user
* Extension packages must move together with the harness, in the same commit
* Upstream's own lockfile integrity should be preserved rather than
  re-implemented
* Avoiding a permanent fork of the installer keeps the maintenance surface
  small once upstream supports version selection

## Considered Options

* Keep the upstream installer and accept `pi update` drift
* Install the harness from npm with a pinned global package
* Stage pinned releases from upstream's published installer artifacts
* Vendor the release tarball into the dotfiles repository

## Decision Outcome

Chosen option: "Stage pinned releases from upstream's published installer
artifacts", because it pins the version without executing a remote installer,
reuses upstream's signed-off lockfile integrity, and needs only a small
version-selection wrapper rather than a fork.

`scripts/pi-managed-install.py` fetches the version metadata, `package.json`,
and `package-lock.json` for the pinned version, verifies the metadata version
matches the pin, verifies both blobs against checksums captured in
`fetch-lock.yml`, runs `npm ci --ignore-scripts` in a staging directory, smoke
tests `--version`, and renames the staging directory into
`releases/<version>`. `current-version` is replaced atomically.

Dotfiles owns the scaffolding: it renders `~/.pi/agent/bin/pi` as a launcher
that resolves `current-version`, and the staging script writes
`managed-install.json` and `current-version` in the shape upstream's launcher
and updater expect. Extension packages are pinned at exact versions in
`pi-extensions.yml` and merged into `settings.json` by package identity, so a
live unversioned entry cannot shadow the managed pin.

### Consequences

* Good, because the harness version is a reviewed diff and `pi update` cannot
  move it: settings disable self-update with a message pointing at
  `script/update`
* Good, because a bump requires the pinned version's artifacts to exist, so a
  premature pin fails the update instead of recording unchecked checksums
* Good, because extension pins and the harness pin land in one commit
* Bad, because dotfiles depends on upstream's on-disk layout
  (`releases/`, `current-version`, `managed-install.json`); an upstream layout
  change breaks the install until this decision is revisited
* Bad, because `python3` must exist on the target for the staging script, which
  makes system Python a setup prerequisite
* Neutral, because staging needs network access and `npm`; both already exist in
  the setup path

### Confirmation

`scripts/update_review/providers/pi.py` reports harness and extension changes as
a single review unit. After `script/update`, `git-lock.yml`,
`pi-extensions.yml`, and `fetch-lock.yml` change together, and
`~/.pi/agent/install/current-version` matches the `pi` pin. When upstream
publishes a newer release, `pi update` runs the configured refusal command and
fails without changing the installed version; when the pin already equals
upstream latest, `pi update` reports that it is up to date and does nothing,
because Pi consults `selfUpdateCommand` only after deciding an update is
available. The startup version-check notice is silent because
`PI_SKIP_VERSION_CHECK=1` is set in the shell profiles; the one-time changelog
notice after a staged upgrade still appears, since it reports the version now
installed rather than offering an update.

## More Information

Exit condition: remove the staged-install scaffolding in favour of
`install.sh --version` (or an equivalent `PI_INSTALL_VERSION` environment
variable) once upstream supports version selection. The launcher, staging
script, and shell hooks for Pi then reduce to a single versioned install call.

Upstream artifacts consumed, for reference: `<api_base>/<version>` (version and
checksum metadata), `<api_base>/<version>/package.json`,
`<api_base>/<version>/package-lock.json`, and `<api_base>/latest`.

Scope boundary: this covers the harness release and top-level extension
packages only. Transitive dependencies follow upstream's lockfile, and
`~/.pi/agent/npm/package-lock.json` stays unmanaged.
