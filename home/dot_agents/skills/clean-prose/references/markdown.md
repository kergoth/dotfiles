# Markdown Conventions

Conventions for markdown links and structured lists in documentation files
(READMEs, `docs/`, Obsidian notes). Plan files, design documents, and
conversational responses are exempt — they may use autolinks or bare URLs.

## Links

- Always use proper markdown links: `[descriptive text](url)` or
  reference-style `[text][ref]` with definitions at the bottom.
- Never use bare autolinks (`<http://...>`) or plain unlinked URLs in
  documentation contexts. These are the antipattern to avoid.
- Use descriptive link text that explains the destination. Avoid generic
  text like `[here]`, `[this]`, or `[link]`.

## Structured lists

In structured lists, use indented continuation for elaboration that goes
beyond a one-sentence definition. The inline portion answers "what is it";
continuation handles caveats, structure, deployment details, or anything
that would otherwise stretch the bullet into a run-on. Example:

```
- **Pool size**: 20 connections by default.
  Production overrides via PGPOOL_SIZE; tune per service in infra/db.yml.
```
