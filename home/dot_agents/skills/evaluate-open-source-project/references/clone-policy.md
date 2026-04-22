# Clone Policy

- `triage`: metadata-only, no clone required
- `assessment`: fresh disposable clone by default
- `audit`: fresh disposable clone by default
- Reuse of an ambient working tree is a downgrade that must be reported.
- Triage may inspect a small set of top-level docs only. Do not recursively
  chase linked remote scripts or deep repo contents during triage.
