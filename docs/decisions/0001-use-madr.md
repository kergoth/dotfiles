---
status: accepted
date: 2026-04-29
decision-makers: kergoth
---

# Use MADR for Architectural Decision Records

## Context and Problem Statement

This repository makes architectural decisions that shape how the system is built and how it should evolve. Until now those decisions have been recorded informally in design docs under `docs/implemented/`, or as plan/spec files that were treated as temporary artifacts and not retained. This makes it hard to understand *why* the system is built the way it is, and creates no clear place for decisions that aren't tied to a specific implementation task.

We need a lightweight, file-based format for capturing architectural decisions that lives alongside the code, requires no tooling, and has a clear enough structure that writing one is not burdensome.

## Decision Drivers

* Low overhead — format must not become a barrier to recording decisions
* Markdown-native — works with the existing `docs/` structure and plain editors
* Established standard — reduces bikeshedding on format and lifecycle vocabulary
* Template-based — new ADRs should have a clear starting point

## Considered Options

* MADR (Markdown Architectural Decision Records)
* Michael Nygard's original ADR format (simpler, less structured)
* RFC-style documents (heavier prose format, no formal standard)
* Continue ad hoc design docs in `docs/implemented/`

## Decision Outcome

Chosen option: "MADR", because it is a widely-used, actively maintained standard with official templates, a clear lifecycle vocabulary (proposed/accepted/deprecated/superseded), and enough structure to capture reasoning without requiring narrative prose for every section.

### Consequences

* Good, because ADRs are in a recognized format with a clear lifecycle
* Good, because templates give new ADRs a consistent starting point
* Good, because `docs/decisions/` is a stable home distinct from ephemeral plans and specs
* Neutral, because existing design docs in `docs/implemented/` are not retroactively converted — only decisions with lasting architectural significance are promoted
* Bad, because there is some overhead in maintaining the `status` field as decisions evolve

### Confirmation

Check that `docs/decisions/` contains numbered MADR files and that new architectural decisions produce an ADR rather than a plan or scratch doc.

## More Information

Official MADR project: https://adr.github.io/madr/

Templates are in `docs/decisions/templates/`. Use the full template for decisions with multiple real alternatives; use the minimal template for straightforward decisions.

Naming convention: `NNNN-kebab-case-title.md` with zero-padded four-digit numbers.

ADRs capture the *why* behind decisions. Implementation detail, task plans, and temporary design notes belong in ephemeral artifacts (plans/specs) or issue comments, not in ADRs.
