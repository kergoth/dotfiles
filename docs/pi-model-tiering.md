# Pi Model Tiering and Routing

How to pick a model in pi across the available providers, and the reasoning
behind the priority order in `settings/pi/settings.json.tmpl` (`$allModels`).
The enabled-models list encodes priority; this doc records why that order is
what it is, so future additions land in the right slot.

## Model pools

| Pool | Provider entries | Billing |
| --- | --- | --- |
| Claude subscription | `claude-bridge/*`, `pi-claude-cli/*` | flat until usage limit |
| Codex subscription | `openai-codex/*` | flat until usage limit |
| Cursor subscription | `cursor/*` (work machines only) | flat until usage limit |
| opencode subscription | `opencode-go/*` | flat until usage limit |
| Local | `local-coder`, `local-reason`, `local-reason-long`, `local-assistant`, `local-quality`, `mtplx` | free, on-device or pre-paid flat |

Every interactive pool here is subscription or free. A true per-token pool
exists as opencode-zen, not currently configured; the dollar-denominated cost
arguments below apply at full strength only if it (or another per-token
provider) joins the list.

Two machine gates apply, set in the template's exclude logic:

- Work machines exclude every `opencode-go` model.
- Personal machines exclude the cursor models.

The exclusion test is exact string matching, not globbing. A new
`opencode-go` model must be added both to `$allModels` and to the work-exclude
block by its full name, or it will silently appear on work machines.

## Axes

Model choice resolves along three axes. The first two pick the tier; the third
picks where within a tier to start.

**Purpose.** Coding and agentic work on one end, chat and assistant use on the
other. They rank models differently: coding composites weight tool use and
long-horizon execution, while chat quality tracks blind human preference
(LMArena Elo). The gap between tiers compresses in chat; a flash-tier model
sits within roughly 15 Elo of a flagship there, while the same distance in
coding benchmarks is a canyon.

**Escalation.** Task duration and difficulty, cutting across purpose.
`claude-bridge/claude-fable-5` leads when a task takes hours or days end to
end, and its edge shrinks on ordinary workloads, where
`claude-bridge/claude-opus-5` beats it head to head at half the price.
Escalation is therefore a separate dial: reserve the top of it for long-running
or genuinely hard work rather than treating it as a better version of the
default tier.

**Cost.** Priced per resolved task, not per token, and driven by two task
properties. Loop shape first: an agent re-sends its whole context every step,
so spend scales with the square of the step count, and a cheaper model that
needs twice the steps costs roughly four times as much. Verification
asymmetry second: when output is cheap to verify (tests, diff review), a weak
attempt costs only a retry; when verification is expensive (research
synthesis, subtle correctness), a wrong answer costs the belief built on it.
Pool billing matters too. Every configured interactive pool is subscription
or free, so wheel-spinning spends window time and limit budget rather than
money; the quadratic dollar cost returns only on a per-token pool such as
opencode-zen.

## Chain ordering

Fallback chains have two orderings, and the right one depends on how
quality-sensitive the purpose is.

**Quality-ordered** chains spend the scarcest-capability subscription budget
first: `claude-bridge` and `openai-codex` targets lead, and the `opencode-go`
window enters when one of those is exhausted. Quality-sensitive work is what
those windows are for.

**Budget-ordered** chains spend free pools and the least-scarce subscription
window first, and never step up into the scarcer windows for low-stakes work.
Chat and summarization are the fit: tier compression means the cheap models
land within roughly 15 Elo of the flagships, so Claude or Codex window spent
there buys almost nothing. One rule is unconditional regardless of ordering:
no fallback step may escalate into the Claude or Codex windows for a
low-stakes purpose.

Both orderings are still window-aware. Subscription limits reset on rolling
windows, so "conserve" really means "expected marginal value of the remaining
pool within the window." A light day of reading and small edits makes
subscription spend on assistant chatter nearly free; a planned long refactor
session flips the calculus. Quality-ordered is the default, and the conscious
deviation is knowing heavier use of a pool is coming.

## Tiers and fallback chains

Chains are ordered preference for a purpose, with adjacent steps drawing on
different pools so a rate limit or outage in one pool moves you to another.
Where the two orderings differ, each purpose carries both, exposed as aliases
(see [Alias roles](#alias-roles)).

### Alias roles

The `pi-model-fallback-alias` extension turns each chain into a stable
`alias/<role>` model with automatic failover: it advances on connection,
authentication, and HTTP errors until output commits, then puts failed
targets on an exponential cooldown shared across aliases and pi processes.
Configuration renders from `home/dot_pi/private_agent/model-alias.json.tmpl`,
so work and personal machines get different chains; `/reload` picks up edits,
`/model-alias-targets` shows the flattened chains, and
`/model-alias-latency-report` shows attempt statistics.

| Role | Ordering | Purpose |
| --- | --- | --- |
| `alias/coding` | quality | sonnet-tier default for coding and agentic work |
| `alias/coding-budget` | budget | same tier, `opencode-go` window first, conserving the Claude and Codex windows |
| `alias/coding-max` | quality | opus-tier escalation for hard or novel work |
| `alias/chat` | budget | casual chat and assistant use |
| `alias/research` | quality | research and synthesis; fable is a manual escalation, not in the chain |
| `alias/light` | budget | background text tasks: contextPrune summarization, session auto-naming |

`coding-budget` exists only on personal machines; work has no `opencode-go`
window to front-load.
The `chat` chain includes the local assistant target only where
`~/.pi/agent/models.json` exists, and always last: the local model server
isn't always running, so it's an on-demand fallback rather than a leading
option.

Escalation between tiers stays manual. The two-strike policy from the coding
section is the trigger for switching from `alias/coding` to
`alias/coding-max`; the alias failover handles pool outages, not tier
escalation.

### Coding and agentic

Quality-ordered by default (`alias/coding`); `alias/coding-budget` front-loads
the `opencode-go` window for conserving the Claude and Codex windows. Escalate
on evidence, not upfront.

- **Sonnet tier (default)**: `claude-bridge/claude-sonnet-5` ahead of
  `claude-bridge/claude-sonnet-4-6` (trial, September 2026 — sonnet-5 first
  with 4-6 as fallback; revert the order if sonnet-5's higher per-task token
  use outweighs its lower per-token price), then `openai-codex/gpt-5.6-terra`,
  then (personal only) `opencode-go/kimi-k2.7-code` and
  `opencode-go/deepseek-v4.1-flash` once the opencode-go window opens;
  `cursor/auto-smart` at work. `alias/coding-budget` (personal only)
  front-loads the opencode-go pair ahead of the claude-bridge and terra
  targets. Best fit: known-pattern changes, small diffs, routine refactors.
- **Opus tier (escalation)**: `opencode-go/kimi-k3`, `opencode-go/glm-5.3`,
  `opencode-go/deepseek-v4-pro`, `claude-bridge/claude-opus-5-5` ahead of
  `claude-bridge/claude-opus-5` (trial, September 2026 — Anthropic claims
  opus-5.5 costs ~40% less per completed task than opus-5; unverified
  independently), `openai-codex/gpt-5.6-terra` or `openai-codex/gpt-5.6-sol`,
  `cursor/grok-4.7` at work — cursor-native (Cursor Models pool), not a
  third-party pick routed through cursor, so it adds real provider diversity
  instead of just re-billing a pool already covered by `claude-bridge` or
  `openai-codex` at a surcharge.
  Best fit: novel design, ambiguous debugging, large refactor planning.
- **Escalation policy**: two strikes. One stall or unsatisfied retry at the
  sonnet tier, then jump. Prune or summarize the stalled transcript before
  escalating so the stronger model is not misled by a flailing history; pi's
  contextPrune handles this. Set an explicit done-condition on long tasks so a
  runaway loop cannot quietly run up the meter.

Every interactive pool is subscription-priced, so pool choice trades window
scarcity rather than dollars: spend the window whose remaining budget has the
least valuable planned use. The loop-cost argument for starting strong still
holds through time and retries, and would regain its dollar force on a
per-token pool such as opencode-zen.

### Chat and assistant

Budget-ordered (`alias/chat`); a single chain per machine type, no
quality-ordered variant. It existed as `chat-quality` briefly but collapsed
back to one alias (October 2026) since it never diverged from `chat` in
practice and chat volume is low enough that a dedicated quality tier isn't
worth maintaining — revisit if chat quality becomes a real complaint.
- **Personal `alias/chat`**: `opencode-go/glm-5.3-flash` (Arena Elo 1471,
  image input, 1M context), then `openai-codex/gpt-5.6-luna`, then
  `claude-bridge/claude-haiku-4-5` if neither cheap tier is cutting it, then
  `local-assistant/**` last — on-demand only, since the local server isn't
  always running.
- **Work `alias/chat`**: `openai-codex/gpt-5.6-luna`, then
  `cursor/grok-4.7` on provider-diversity grounds (no chat-quality evidence
  either way; swap for `cursor/auto-smart` if the tone does not suit), then
  `claude-bridge/claude-haiku-4-5`, then `local-assistant/**` where
  `models.json` exists.

`opencode-go/qwen3.8-flash` and `openai-codex/gpt-5.6-luna` are roughly a
wash on conversational quality; `opencode-go/glm-5.3-flash` dominates both on
current Arena evidence at the same price class. Reserve `opencode-go/kimi-k3`
for coding; its chat quality is real but pays opus-tier prices for a purpose
where the flash tier gets most of the way there.

### Research and long-horizon escalation

`alias/research` is the default tier, reached automatically; escalation to
fable is manual, mirroring the `coding`/`coding-max` split (October 2026 —
fable was previously the chain's automatic top pick, but the alias always
selects the first entry regardless of task duration, so leading with fable
meant every automatic call paid its cost even for ordinary work where it
loses head to head with `claude-bridge/claude-opus-5`; dropped in favor of
manual invocation for now, with a `research-max` alias as a future option if
that manual step proves too easy to forget).

- **Default (`alias/research`)**: `claude-bridge/claude-opus-5`, then
  `openai-codex/gpt-5.6-terra`, then (personal only)
  `opencode-go/kimi-k3` or `opencode-go/deepseek-v4-pro` for interactive
  research sessions (an evening of source reading, then a synthesis; both
  carry 1M context at sonnet-plus pricing), then (work only)
  `cursor/grok-4.7` — cursor-native rather than a third-party pick routed
  through cursor, for the same provider-diversity reason as the opus coding
  tier.
- **Manual escalation**: `claude-bridge/claude-fable-5`, for
  multi-hour-plus autonomous research and synthesis. This is its design
  center; reach for it deliberately on genuinely long-horizon work, not as
  a default for interactive depth or routine work.

### Background text tasks

`alias/light` is not a cheap-chat tier; it's the model for background work
that never needs interactive selection: `contextPrune` summarization
(`settings/pi/settings.json.tmpl`'s `summarizerModel`) and session
auto-naming (`home/dot_pi/private_agent/configs/session-name.json.tmpl`).
Both are trivial, low-stakes text tasks, so `light` stays budget-ordered and
leads with the cheapest option per machine type.

- **Personal**: `opencode-go/mimo-v2.5` first — mid-pack overall, concise,
  cheap to run (15B of 310B activated), with the 1M context that condensation
  needs, and not a candidate for the interactive tiers above. Then
  `openai-codex/gpt-5.6-luna`, then `claude-bridge/claude-haiku-4-5`.
- **Work**: `openai-codex/gpt-5.6-luna` first, then `cursor/composer-2.5`
  (cheapest cursor-native model; its coding specialization doesn't matter
  for title/summary text), then `claude-bridge/claude-haiku-4-5`.

Each chain still touches all three subscription providers available on that
machine type (October 2026 decision) so a provider outage or usage-limit hit
doesn't stall summarization or session naming — even though the task is
low-stakes, having no path through a downed provider is worse than the
modest window cost of an occasional fallback hit.

## Evidence notes

Rankings above rest on these sources, checked September 2026. Re-verify
before major re-tiering; the catalog moves monthly.

- [LMArena Text leaderboard snapshot][llming] and [BenchLeader text
  rankings][benchleader] for chat-quality ordering (`opencode-go/kimi-k3` at
  rank 7, `opencode-go/glm-5.3-flash` at 1471 Elo,
  `claude-bridge/claude-fable-5` at the top).
- [Anthropic's Fable 5 positioning][fable] for the long-horizon design center,
  and the [Opus 5 vs Fable 5 head-to-head][goldie] plus [cost
  comparison][edenai] for where the escalation tier stops paying.
- [The price reversal study][reversal] (32% of model pairs: cheaper list
  price, higher realized cost), the [Gitar switch case study][gitar] (5x
  cheaper model, higher total spend), and the [quadratic agent loop cost
  analysis][quadratic] for the cost axis.
- [llm-stats comparisons][llmstats] for spec-level head-to-heads
  (`openai-codex/gpt-5.6-luna` vs `opencode-go/qwen3.8-flash`,
  `opencode-go/mimo-v2.5` vs `opencode-go/qwen3.8-flash`).

[llming]: https://llm.ing/benchmarks/lmarena-text
[benchleader]: https://www.benchleader.com/benchmarks/lmarena_text
[fable]: https://www.anthropic.com/research/claude-fable-5-mythos-5
[goldie]: https://goldiebench.com/vs/opus5-vs-fable-5
[edenai]: https://www.edenai.co/post/claude-opus-5-vs-claude-fable-5-benchmark
[reversal]: https://arxiv.org/html/2603.23971v2
[gitar]: https://gitar.ai/blog/we-switched-to-a-5x-cheaper-llm-our-costs-went-up
[quadratic]: https://dreaming.press/posts/why-ai-agent-costs-scale-quadratically.html
[llmstats]: https://llm-stats.com/models/compare/gpt-5.6-luna-vs-qwen3.8-flash
