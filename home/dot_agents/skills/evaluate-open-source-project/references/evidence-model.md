# Evidence Model

## States

- `evaluated`
- `insufficient-time-to-observe`
- `insufficient-evidence`
- `not-applicable`
- `blocked-local-access`

## Applicability

Treat GitHub-native issue, PR, and release signals as `not-applicable` or
`insufficient-evidence` when the project clearly uses another visible
public collaboration or release mechanism.

## Blocked depth

If `assessment` or `audit` is requested but clone or isolation
requirements are refused, complete earlier phases if possible and mark the
deeper phases as blocked in the report.
