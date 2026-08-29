# Updating External Content

The repository pins Git repositories, fetched files, and container base images
so an upstream change is reviewed before it becomes local configuration or
executable code.

## Authorization Boundary

Update execution is human-owned. Agents may inspect lock state, explain a
candidate, or suggest `script/update`, but must run an update only when the
user explicitly requests that workflow. This boundary includes direct chezmoi
update or external-refresh commands, not only repository wrappers.

`script/update --dry-run` is the normal preview entry point. `script/update`
coordinates review, approval, lock writes, commits, and downstream updates.
Do not substitute chezmoi's raw update command; it bypasses
repository-specific review and orchestration.

## Source and Lock Files

| Content | Source definition | Resolved lock | Consumer mapping |
| --- | --- | --- | --- |
| Git repositories | `home/.chezmoidata/git-sources.yml` | `home/.chezmoidata/git-lock.yml` | Individual templates and scripts |
| Fetched files | `home/.chezmoidata/fetch-sources.yml` | `home/.chezmoidata/fetch-lock.yml` | Individual templates and scripts |
| Container images | `home/.chezmoidata/container-sources.yml` | `home/.chezmoidata/container-lock.yml` | `home/.chezmoidata/container-targets.yml` |

Source files describe upstream identity and selection policy. Lock files hold
the exact revision, digest, or checksum adopted after review. Consumers remain
responsible for deciding where and how pinned content is installed.

## Git Sources

A Git source identifies a repository and either follows a ref or selects a
tag. `scripts/update-git-lock.py` resolves the candidate value:

```console
scripts/update-git-lock.py --dry-run --json
```

Branch-following entries lock a commit SHA. Tagged entries lock the selected
tag name. The dry-run JSON is also the handoff between candidate resolution,
review, and `--apply-resolved`, which ensures the written lock matches the
revision that was reviewed.

Git externals may contain shell plugins, agent skills, or other executable
content. A familiar upstream does not make an unseen revision safe to adopt.

## Fetched Files

`fetch-sources.yml` records URLs, optionally derived from another locked
version. `fetch-lock.yml` records the SHA-256 checksum of the downloaded bytes.
Preview checksum changes with:

```console
scripts/update-fetch-lock.py --dry-run
```

Run without `--dry-run` only inside an authorized update workflow. A changed
checksum means the exact bytes changed even when the URL did not.

## Container Images

`container-sources.yml` names mutable upstream image references.
`container-lock.yml` records resolved `sha256:` image digests, while
`container-targets.yml` maps each source to the Dockerfile that must receive
the pin.

Preview digest drift with:

```console
scripts/update-container-pins.py --dry-run
```

When adopting a change, update the source definition, lock, target mapping,
and Dockerfile pin together. Verify the affected image with the narrowest
container build or setup test described in
[Testing and Verification](testing.md#container-setup-tests).

Docker server architecture controls which Arch Dockerfile is exercised at test
time. That runtime behavior and `DOCKER_SERVER_ARCH` belong in the testing
guide rather than the lock format.

## Review Metadata

Git sources can tune review without changing update mechanics:

- `review_note` adds source-specific instructions. It should identify the
  content that matters and risks particular to that dependency.
- `review_paths` hard-scopes fetched history and diffs to selected paths in a
  large repository.
- `review: false` disables review for sources where executable-change review
  is intentionally unnecessary, such as some data-only assets.

Release notes provide narrative context; they do not replace inspection of the
pinned revision range. For tagged GitHub sources, the review tool may include
release notes alongside the log and diff.

`scripts/show-git-changes.py` is the review surface. It fetches the old and new
range, displays history and changes, applies path and note metadata, and may
ask an available agent CLI for a supply-chain summary. Absence of an agent CLI
does not prevent the textual review.

## Orchestrated Update Workflow

The POSIX entry point is `script/update`; Windows uses `script/update.ps1`.
The workflow:

1. Resolves candidate Git, fetched-file, and container changes without writing
   locks.
2. Displays the relevant change and review context.
3. Requests approval when operating interactively.
4. Writes the already-reviewed resolution.
5. Applies the broader repository and Home Manager update sequence.

`script/update --dry-run` reports candidates without writing files. The update
scripts also handle other maintenance, so consult their `-h` output rather
than calling lower-level writers casually.

## Verification and Troubleshooting

Before adopting a Git candidate, confirm the old and new revisions in the
review output match the lock change. If `review_paths` produces an empty diff,
check whether the source changed outside the intended scope rather than
assuming there was no update.

For a failed fetched-file update, inspect the resolved URL and compare the
bytes or checksum to the expected upstream artifact. Do not fix a mismatch by
copying a new checksum without reviewing the content.

For a failed external download during apply, inspect the managed external
set:

```console
chezmoi managed --include=externals
```

Refreshing externals changes local state and remains subject to the
human-owned authorization boundary.

## Related Decision

- [ADR 0004: Review Before Adopt for External Dependencies](decisions/0004-review-before-adopt-for-external-dependencies.md)
- [Testing and Verification](testing.md)
- [Repository Architecture](repository-architecture.md)
