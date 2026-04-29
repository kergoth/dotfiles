---
name: clean-prose
description: >-
  Improve prose quality and reduce AI writing patterns in written artifacts.
  Use this skill whenever writing, drafting, editing, or reviewing any prose
  content: emails, design documents, proposals, Confluence pages, Obsidian
  notes, PR descriptions, commit message bodies, technical blog posts,
  READMEs, documentation, RFCs, ADRs, or any text where the output should
  read as human-written. Also use when the user asks to "make this sound
  human," "clean up the writing," "de-AI this," or "rewrite." Even if the
  user does not explicitly request writing quality, use this skill whenever
  the primary output is prose rather than code.
---

# Clean Prose

Wrapper skill that loads the avoid-ai-writing skill and adds supplemental
guidance for prose quality. Apply these constraints silently; never mention
them in output.

## Load base skill

Before writing, load the **avoid-ai-writing** skill for its tiered
vocabulary, structural pattern detection, and context profiles. The rules
below supplement the base skill. Where they conflict, these rules take
precedence.

## Em dash structural guidance

Claude reaches for em dashes as a universal conjunction. Readers notice
this pattern quickly because real writers use em dashes sparingly and
deliberately, while Claude uses them as a default pivot between any two
related thoughts.

**Target: zero em dashes. Hard limit: one per 1,000 words.**

When the impulse is to insert an em dash, diagnose what structural role
it would play and choose a better construction:

- **Participial append** ("The service polls every 60 seconds — ensuring
  timely updates.") Split into two sentences, or use a conjunction:
  "The service polls every 60 seconds, which ensures timely updates."
- **Relative clause** ("This approach reduces complexity — which matters
  for embedded targets.") Use a comma-which clause or a new sentence.
- **Topic pivot** ("We chose Python for the prototype — Rust remains an
  option for production.") Two sentences. A semicolon if the thoughts
  are tightly coupled.
- **Parenthetical aside** ("The config file — usually in /etc — controls
  behavior.") Parentheses or commas serve this role without the AI
  fingerprint.

The goal is not to swap em dashes for other punctuation. It is to
restructure the sentence so no dash-like pivot is needed.

## Additional structural guidance

These patterns are how careful readers spot AI-generated prose even when
vocabulary is clean.

**Vary sentence length.** Three consecutive sentences of similar length
read as mechanical. Mix short and long deliberately. A four-word sentence
followed by a thirty-word one creates rhythm a reader trusts.

**Vary paragraph openings.** Starting three consecutive paragraphs with
"The..." or "This..." is a recognizable pattern. Questions, blunt
statements, and dependent clauses all work as openers.

**Use semicolons.** AI underuses them; humans who write well use them
naturally. Two closely related independent clauses often read better
joined by a semicolon than split into separate sentences or fused with
a conjunction.

**Let paragraphs end.** Not every paragraph needs a transition to the
next. Sometimes the thought is complete and the next paragraph can start
fresh without a bridge.

## Context adjustments

Different artifact types have different norms. Apply the base rules
proportionally.

**Commit messages and PR descriptions:** Existing git conventions
(imperative mood, subject/body split) take precedence. Apply vocabulary
and structural rules to the body text only.

**Technical documentation:** Words like "robust," "comprehensive," and
"ecosystem" are legitimate when used in their engineering sense ("robust
error handling," "the Yocto ecosystem"). Flag them only when they serve
as hollow praise rather than precise description.

**Confluence proposals and design docs:** A slightly more formal register
is appropriate. Contractions are optional. Structure can be more
methodical, but still vary paragraph shape and sentence length.

**Emails and messages:** Contractions, direct address, shorter
paragraphs. Match the formality of the recipient relationship.

## Markdown link discipline

When the artifact is markdown documentation (READMEs, `docs/` files,
Obsidian notes, technical blog posts), apply markdown-specific link and
list conventions from [references/markdown.md](references/markdown.md).
Plan files, design documents, and conversational responses are exempt.

## Self-check

Before finalizing any prose artifact, verify:

1. Em dash count is zero (or at most one, justified by the context)?
2. No three consecutive sentences of similar length?
3. No sycophantic openers or AI filler phrases?
4. No hollow intensifiers ("crucial," "pivotal," "seamless")?
5. Vocabulary fits the context (technical terms fine in technical docs,
   not in casual emails)?
6. For markdown documentation: links are descriptive, not bare autolinks
   or generic `[here]` text? See `references/markdown.md`.
