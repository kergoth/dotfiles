---
status: accepted
date: 2026-03-22
decision-makers: kergoth
---

# Review-Before-Adopt Workflow for External Dependencies

## Context and Problem Statement

The dotfiles update workflow (`script/update`) resolved new commit SHAs for pinned externals and immediately applied them via `chezmoi apply` with no opportunity to review what changed before the updated code was deployed to the home directory. This is a meaningful supply chain risk: zsh plugins, agent skills, and shell scripts are executed directly, and a compromised upstream commit would be adopted silently. The risk applies even to trusted upstreams, because trust in a project does not mean trust in every future commit.

## Decision Drivers

* Zsh plugins and agent skills execute directly and can affect shell startup and agent behavior
* Supply chain attacks on widely-used open source projects are documented and increasing
* Review must be practical — a workflow nobody uses provides no protection
* Non-interactive pipelines (CI, unattended apply) must not break

## Considered Options

* Trust all updates implicitly (previous behavior)
* Require fully manual review before running `script/update`
* Automated review gate: shortlog + AI summary + interactive approval prompt

## Decision Outcome

Chosen option: "Automated review gate", because it makes the review practical enough to actually happen while keeping the non-interactive path functional.

### Consequences

* Good, because every external update surfaces a shortlog and optional AI supply-chain summary before any files are written
* Good, because the interactive approval gate (TTY only) prevents accidental adoption without explicit intent
* Good, because non-interactive mode prints the review output but does not block pipelines
* Good, because per-external `review: false` opt-out is available for asset-only repos where review adds no value
* Bad, because review adds latency to the update workflow
* Neutral, because Nix/home-manager inputs are excluded — `nvd diff` plus content-addressed integrity covers that path

### Confirmation

Running `script/update` from a TTY prompts for confirmation after showing the shortlog for each changed external. Running with `--dry-run` shows the review without writing any files. Running non-interactively shows the review and proceeds without blocking.

## More Information

Implementation: `scripts/show-git-changes.py` produces the review output; `scripts/update-git-lock.py --dry-run --json` resolves candidates without writing; `--apply-resolved` writes the pre-reviewed SHAs. This ensures the SHAs written match exactly what was reviewed, with no race between resolve and write.

AI summary uses the first available agent CLI (`claude`, `codex`, `agent`) with graceful degradation — no summary if none is found, no failure.

Per-source `review_note` and `review_paths` fields in `git-sources.yml` scope the AI review to the relevant parts of large repos.

Scope boundary: this covers git-pinned externals in `git-sources.yml` and single-file fetches in `fetch-sources.yml`. Nix inputs have separate integrity guarantees via content addressing.
