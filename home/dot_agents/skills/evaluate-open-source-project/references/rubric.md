# Rubric

| id | criterion | category | applies at | evidence needed | age handling | weight | red flags |
| --- | --- | --- | --- | --- | --- | --- | --- |
| stewardship-active-maintenance | Active maintenance over time | stewardship | triage, assessment, audit | releases, commits, recent activity windows | age-sensitive | high | launch burst followed by long silence |
| stewardship-maintainer-continuity | Maintainer continuity and concentration | stewardship | triage, assessment, audit | contributor and commit concentration over time | age-sensitive | high | one-person project with no sign of durable stewardship |
| maturity-evidence-sufficiency | Evidence sufficiency for project age | maturity | triage, assessment, audit | project age, activity history, public signals | strongly age-sensitive | high | claims exceed what available history can support |
| community-issue-responsiveness | Issue responsiveness | community | triage, assessment, audit | issue response and stale patterns | age-sensitive | medium | maintainers rarely respond or only close without engagement |
| community-pr-responsiveness | External PR responsiveness | community | triage, assessment, audit | PR review, merge, and stale patterns | age-sensitive | medium | outside contributions sit stale or receive no real review |
| release-cadence-discipline | Release cadence and follow-through | release-discipline | triage, assessment, audit | releases, tags, timing gaps | age-sensitive | medium | initial releases only, then drift |
| project-hygiene-foundations | Project hygiene foundations | governance | triage, assessment, audit | README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT | lightly age-sensitive | low-medium | missing license or unusable README |
| security-agent-artifact-surface | Agent-facing artifact trust surface | security-surface | assessment, audit | local clone, repo-local agent files, config, hooks | not age-sensitive | high | agent instructions appear to shape evaluator behavior unsafely |
| security-exfiltration-touchpoints | Exfiltration and outbound-behavior touchpoints | security-surface | audit | local clone, code search, network and secret handling touchpoints | lightly age-sensitive | high | suspicious outbound behavior or opaque automation |
| confidence-evidence-depth | Recommendation confidence grounded in evidence depth | evidence-quality | triage, assessment, audit | completed phases, blocked access, unknowns | strongly age-sensitive | high | high-confidence recommendation with shallow evidence |
