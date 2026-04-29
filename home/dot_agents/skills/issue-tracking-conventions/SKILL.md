---
name: issue-tracking-conventions
description: Use when creating, filing, writing, or revising issues, epics, initiatives, tasks, stories, enhancements, or bug reports in any tracker — GitHub Issues, Jira, Linear, GitLab, Asana, Shortcut. Covers structural conventions per issue type and self-containment rules for descriptions.
---

# Issue Tracking Conventions

Personal defaults for writing issues, epics, and tickets. If a project's CONTRIBUTING, AGENTS.md, or issue templates mandate a different structure, follow the project.

## By type

- **Epics / initiatives:** outcome-level. Why it exists, what done looks like, what's explicitly excluded. No implementation details.
- **Tasks / stories / enhancements:** definition of done, not how to implement.
- **Bugs:** reproduction steps, expected vs. actual behavior.

## Self-containment

- Descriptions must be readable on their own. Don't reference local files, unlinked docs, branch names, or context the reader can't access.
- If a related artifact exists (PR, design doc, prior issue, Slack thread), link to it explicitly with a descriptive label.
- An issue should make sense to someone joining the project six months from now and reading it cold.
