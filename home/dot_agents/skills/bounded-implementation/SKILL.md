---
name: bounded-implementation
description: "Use ONLY for Mode 2 tasks (accumulated design intent, not trivial, below full superpowers threshold) and for explicitly bounded sub-tasks within Mode 3+ plans. Do NOT load for Mode 0 (trivial edits) or Mode 1 (intent-only). Contract: derive acceptance criteria, implement smallest change, verify adversarially against criteria before presenting. The adversarial verifier role — actively trying to break the implementation against its own criteria before declaring done — is what distinguishes this from basic TDD."
---

# Bounded Implementation

The spec is the criteria you derive from the request — not a separate document.


## Contract

### 1. Criteria
Derive 3-7 testable acceptance criteria from the request. Each must be:
- Falsifiable from the diff
- Scoped: names what changes, not just what works

State all criteria before touching any file.

### 2. Source boundaries
- Canonical source files: what changes
- Explicit non-goals: what does NOT change, even if related

If you cannot name the canonical source, stop and ask. Editing a rendered
output instead of the managed source is a failure, not a shortcut.

### 3. Implement
Smallest change satisfying the criteria. No worktrees. No durable tests unless
explicitly requested. No cleanup or refactoring beyond stated scope.

### 4. Verify (adversarial)
Before presenting, act as independent verifier:
- Does the diff satisfy each criterion? Cite evidence.
- Any wrong-source edits?
- Any scope creep?
- Any unsupported assumptions?

Fix failures before presenting. Do not present and flag failures simultaneously.

### 5. Report
- Mode and rationale (one line)
- Evidence per criterion (pass/fail + diff reference)
- Human-only checks remaining
- Nothing else

## Scope boundary

Mode 0-1: guidance is inline in the mode-classification prompt — do not invoke this skill.
Mode 3+: use superpowers workflows. This skill may be invoked at individual plan steps
where a bounded execution contract is needed within a larger plan.
