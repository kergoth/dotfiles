# Pi Model Tiering and Routing

How to pick a model in pi across the available providers, and the reasoning
behind the priority order in `settings/pi/settings.json.tmpl` (`$allModels`).
The enabled-models list encodes priority; this doc records why that order is
what it is, so future additions land in the right slot.

## When to use which alias

- **`alias/coding`** — default for coding and agentic work. Start here.
- **`alias/coding-budget`** — same coding tier, conserves the Claude window.
  Personal machines spend OpenCode Go first, then Codex, then Claude; work
  machines start with Codex, then Claude, then Cursor.
- **`alias/coding-max`** — opus-tier escalation. Manual jump after two
  strikes (a stall or unsatisfied retry) at `coding`, not a default.
- **`alias/chat`** — casual chat and assistant use, budget-ordered.
- **`alias/research`** — default research/synthesis tier.
  `claude-bridge/claude-fable-5`, invoked directly rather than through an
  alias, is the manual escalation for multi-hour-plus autonomous research.
- **`alias/light`** — background automation only (`contextPrune`
  summarization, session auto-naming), not for interactive use.

See [Alias roles](#alias-roles) and [Tiers and fallback
chains](#tiers-and-fallback-chains) below for the fallback order within each
chain and why it's ordered that way.

## Model pools

| Pool | Provider entries | Billing |
| --- | --- | --- |
| Claude subscription | `claude-bridge/*`, `pi-claude-cli/*` | flat until usage limit |
| Codex subscription | `openai-codex/*` | flat until usage limit |
| Cursor subscription | `cursor/*` (work machines only) | flat until usage limit |
| opencode subscription | `opencode-go/*` | account-level rolling, weekly, and monthly windows exposed by the usage endpoint |
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

The local `model-alias` extension registers each chain as a native Pi virtual
model named `alias/<role>`. Pi still owns physical provider dispatch, request
headers, stream handling, and model continuity. The extension selects the
physical target, tracks failures in shared state, and retries on another pool
when the failure is recoverable. Configuration renders from
`home/dot_pi/private_agent/model-alias.json.tmpl`, so work and personal
machines get different chains; `/reload` picks up edits.

A continuation stays on its last successful physical model while that model is
available. This warm-provider rule preserves provider-side prompt caches and
prevents a recovered first-choice model from pulling a large conversation back
across providers. For a cross-provider switch at 131072 context tokens or
more, TUI and RPC sessions ask whether to switch, compact through
`alias/light` before switching, or stop. The prompt times out after 60 seconds.
The unattended default is compact, but print and JSON modes switch directly
because those modes cannot finish extension-requested compaction. Subagents
load the same extension through Pi's required-child-extension registry, so
`alias/*` resolves in their print-mode processes too.

The extension treats 60 seconds without the first provider event, or 90
seconds between later events, as a stall. Any provider stream event resets the
gap timer, including streamed thinking that has not produced visible text.
After aborting a stalled request, the extension resumes on another target and
allows at most two automatic resumes for one user route.

Cooldowns and usage windows are shared under
`~/.pi/agent/state/model-alias/`. Codex stream events and sanitized Claude
bridge events provide utilization and reset times. OpenCode Go is polled no
more than every five minutes from its authenticated usage endpoint, which
reports account-level rolling, weekly, and monthly windows. A provider with
any window at or above its threshold, or flagged as limited, is avoided at the
next user-turn boundary; an in-progress tool loop stays warm until the target
fails. Error classification remains the fallback when usage data is absent or
stale. User interrupts are not failures and never start a cooldown.

The default threshold is `$settings.switchAboveUsedPercent` (95). To reserve
headroom on a shared account, `$settings.providerSwitchAboveUsedPercent` maps a
provider, or a `provider:window` pair such as `claude-bridge:seven_day`, to its
own threshold. The most specific key wins, then the global value. Claude
reports every window on each turn (`unifiedWindows` in the SDK's rate-limit
event, forwarded by the bridge as `windows`), so a weekly reserve takes effect
even while the five-hour window is low. Utilization is account-wide but only
refreshes when this machine uses Claude, so another machine's usage shows up on
the next request.

`/alias` lists each chain with the session's current target, active
cooldowns, and providers over the usage threshold. `/alias reset [target]`
clears cooldowns for one target or all of them, for when a cooldown outlives
the problem that caused it. The reset applies to every Pi session because the
state is shared; usage windows are left alone, since the next provider report
would restore them. To pin a physical model, select it directly with `/model`.

`/alias usage` fetches live utilization for every provider in the alias
chains before printing each window's percent, reset time, applicable threshold,
and whether it is over, so an idle provider never shows a reading from its last
turn. Fetched values are written back to the shared state, which also corrects
routing. A provider whose fetch fails is shown from stored data, labeled with
the error and the reading's age. Codex is read from the undocumented ChatGPT
usage endpoint the Codex CLI uses, with pi's own login. Claude is read through
the Agent SDK's experimental usage call on a throwaway session, with
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` and `CLAUDE_CODE_OAUTH_TOKEN`
removed from that child's environment: the first makes the CLI skip the fetch,
and the second is a setup-token limited to the `user:inference` scope, while
the usage endpoint needs `user:profile`. The child therefore uses the
interactive Claude Code login, so the machine needs one. Only the five-hour and
seven-day Claude windows are kept; the per-model weekly caps are not, because
routing treats any window at its limit as making the whole provider
unavailable. Both endpoints can change without notice.

| Role | Ordering | Purpose |
| --- | --- | --- |
| `alias/coding` | quality | sonnet-tier default for coding and agentic work |
| `alias/coding-budget` | budget | same coding tier, conserves Claude; personal machines also spend OpenCode Go before Codex |
| `alias/coding-max` | quality | opus-tier escalation for hard or novel work |
| `alias/chat` | budget | casual chat and assistant use |
| `alias/research` | quality | research and synthesis; fable is a manual escalation, not in the chain |
| `alias/light` | budget | background text tasks: contextPrune summarization |
| `alias/title` | budget | session auto-naming; only providers that accept requests made outside an agent session |

`coding-budget` conserves subscription pools within the coding tier rather
than selecting a cheaper tier. Personal machines front-load OpenCode Go,
then prefer Codex over Claude. Work machines have no OpenCode Go pool, so
Sol leads, followed by Sonnet and `cursor/auto-smart`. The quality-ordered
`coding` chain still prefers Sonnet over Sol on both machine types.
The `chat` chain includes the local assistant target only where
`~/.pi/agent/models.json` exists, and always last: the local model server
isn't always running, so it's an on-demand fallback rather than a leading
option.

Escalation between tiers stays manual. The two-strike policy from the coding
section is the trigger for switching from `alias/coding` to
`alias/coding-max`; the alias failover handles pool outages, not tier
escalation.

### Coding and agentic

Quality-ordered by default (`alias/coding`); `alias/coding-budget` prefers
Codex over Claude to conserve the Claude window, with OpenCode Go ahead of
both on personal machines. Escalate on evidence, not upfront.

- **Sonnet tier (default)**: `claude-bridge/claude-sonnet-5`, then
  `openai-codex/gpt-6.1-sol`, then (personal only)
  `opencode-go/kimi-k2.7-code` and `opencode-go/deepseek-v4.1-flash` once
  the opencode-go window opens; `cursor/auto-smart` at work.
  `alias/coding-budget` uses the opencode-go pair, then `gpt-6.1-sol`, then
  Sonnet on personal machines; at work it uses `gpt-6.1-sol`, then Sonnet,
  then `cursor/auto-smart`. Best fit: known-pattern changes, small diffs,
  routine refactors.
- **Opus tier (escalation)**: `claude-bridge/claude-opus-5-5`, then
  `openai-codex/gpt-6.1-sol`, then (personal only)
  `opencode-go/deepseek-v4-pro` ahead of `opencode-go/kimi-k3` (October
  2026 — deepseek-v4-pro carries roughly 10x kimi-k3's monthly quota on
  OpenCode Go, so spending it first reserves kimi-k3's thin allowance for
  when deepseek-v4-pro is also exhausted; the two aren't ranked on quality,
  only quota), `cursor/grok-4.7@256k` at work — cursor-native (Cursor Models
  pool), not a third-party pick routed through cursor, so it adds real
  provider diversity instead of just re-billing a pool already covered by
  `claude-bridge` or `openai-codex` at a surcharge.
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

### Codex tier selection

The Codex slots use the GPT-6 family (October 2026). `gpt-6.1-sol` fills the
sonnet-tier and research fallback slot and the opus-tier fallback slot;
`gpt-6-luna` backs `chat`, `light`, and `title`. There is no GPT-6 Terra:
`gpt-5.6-terra` is dominated by `gpt-6.1-sol` ($2/$10 per million tokens; sources
disagree on Terra's exact list price, but none put it below Sol's) and scores
lower, so it was dropped rather than kept as a
middle rung. `gpt-6-astra` ($10/$50) is in the scoped list for manual
selection only, not in any chain, since nothing here has shown a task that
`gpt-6.1-sol` fails and Astra passes.

A local A/B (`scripts/pi-ab`, five fixed tasks, one run each) found all three
of `claude-sonnet-5-5`, `gpt-6.1-sol`, and `gpt-5.6-terra` passing every task.
`claude-sonnet-5-5` was fastest (3 turns, about 20s median), `gpt-6.1-sol` next
(6 turns, about 57s), `gpt-5.6-terra` slowest (8 turns, about 104s, roughly 60%
more output tokens than Sol), with the same Codex window delta for Sol and
Terra. The tasks were too easy to separate the models on correctness, so this
supports Sol over Terra and Sonnet as the default, not a ranking on hard work.

### Chat and assistant

Budget-ordered (`alias/chat`); a single chain per machine type, no
quality-ordered variant. It existed as `chat-quality` briefly but collapsed
back to one alias (October 2026) since it never diverged from `chat` in
practice and chat volume is low enough that a dedicated quality tier isn't
worth maintaining — revisit if chat quality becomes a real complaint.

- **Personal `alias/chat`**: `opencode-go/glm-5.3-flash` (Arena Elo 1471,
  image input), then `openai-codex/gpt-6-luna`, then
  `claude-bridge/claude-haiku-4-5` if neither cheap tier is cutting it, then
  `local-assistant/**` last — on-demand only, since the local server isn't
  always running.
- **Work `alias/chat`**: `openai-codex/gpt-6-luna`, then
  `cursor/grok-4.7@256k` on provider-diversity grounds (no chat-quality evidence
  either way; swap for `cursor/auto-smart` if the tone does not suit), then
  `claude-bridge/claude-haiku-4-5`, then `local-assistant/**` where
  `models.json` exists.

`opencode-go/qwen3.8-flash` and `openai-codex/gpt-5.6-luna` were roughly a
wash on conversational quality (measured before `gpt-6-luna` replaced it; not
re-measured); `opencode-go/glm-5.3-flash` dominates both on
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
  `openai-codex/gpt-6.1-sol`, then (personal only)
  `opencode-go/deepseek-v4-pro` ahead of `opencode-go/kimi-k3` (same
  quota-first ordering as the opus coding tier) for interactive research
  sessions (an evening of source reading, then a synthesis), then (work
  only) `cursor/grok-4.7@256k` — cursor-native rather than a third-party pick
  routed through cursor, for the same provider-diversity reason as the opus
  coding tier.
- **Manual escalation**: `claude-bridge/claude-fable-5`, for
  multi-hour-plus autonomous research and synthesis. This is its design
  center; reach for it deliberately on genuinely long-horizon work, not as
  a default for interactive depth or routine work.

### Background text tasks

`alias/light` is not a cheap-chat tier; it's the model for background work
that never needs interactive selection: `contextPrune` summarization
(`settings/pi/settings.json.tmpl`'s `summarizerModel`).
The task is a trivial, low-stakes text task, so `light` stays budget-ordered and
leads with the cheapest option per machine type.

- **Personal**: `opencode-go/mimo-v2.5` first — mid-pack overall, concise,
  cheap to run (15B of 310B activated), with the 1M context that condensation
  needs, and not a candidate for the interactive tiers above. Then
  `openai-codex/gpt-6-luna`, then `claude-bridge/claude-haiku-4-5`.
- **Work**: `openai-codex/gpt-6-luna` first, then `cursor/composer-2.5`
  (cheapest cursor-native model; its coding specialization doesn't matter
  for title/summary text), then `claude-bridge/claude-haiku-4-5`.

Each chain still touches all three subscription providers available on that
machine type (October 2026 decision) so a provider outage or usage-limit hit
doesn't stall summarization or session naming — even though the task is
low-stakes, having no path through a downed provider is worse than the
modest window cost of an occasional fallback hit.

`alias/title` backs session auto-naming
(`home/dot_pi/private_agent/configs/session-name.json.tmpl`). Title calls are
made outside any agent session, and `cursor` and `claude-bridge` reject those
(cursor: "Bare modelRegistry.streamSimple calls are unsupported"; claude-bridge:
a `prompt-capture` error), so the chain holds only providers that accept them:
`opencode-go/mimo-v2.5` then `openai-codex/gpt-6-luna` on personal machines,
luna alone at work, which has no `opencode-go`. When the chain is exhausted
the session gets the heuristic title, never a session-model title.

## Context ceilings

Long sessions degrade well before a 1M window fills, so every long-window
model in the scoped list is registered at 272K, the real window of the
`openai-codex` models. Pi compacts when context exceeds the registered window
minus its reserve, so every target compacts near 256K regardless of which
alias target answers. The ceiling is applied per physical model because Pi
takes the window from the model that answered last but looks up compaction
settings by the selected model, which for an alias is the alias itself. A
reserve set on `alias/*` would therefore apply to every fallback target.

- **Claude:** `provider.contextCap` in `settings/pi/claude-bridge.json.tmpl`.
  The bridge still requests the `[1m]` model, so the entitlement stays. A new
  Claude model needs an entry there.
- **`opencode-go`:** `modelOverrides` in `~/.pi/agent/models.json`, which is
  machine-local and not managed by chezmoi. A new 1M model needs an entry.
- **Exempt:** `opencode-go/mimo-v2.5`, which only backs `alias/light` and
  `alias/title` and never accumulates context, and
  `claude-bridge/claude-fable-5*`, which is invoked directly for long-horizon
  work.

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
  (`openai-codex/gpt-5.6-luna` vs `opencode-go/qwen3.8-flash`, before the
  GPT-6 refresh; `opencode-go/mimo-v2.5` vs `opencode-go/qwen3.8-flash`).

[llming]: https://llm.ing/benchmarks/lmarena-text
[benchleader]: https://www.benchleader.com/benchmarks/lmarena_text
[fable]: https://www.anthropic.com/research/claude-fable-5-mythos-5
[goldie]: https://goldiebench.com/vs/opus5-vs-fable-5
[edenai]: https://www.edenai.co/post/claude-opus-5-vs-claude-fable-5-benchmark
[reversal]: https://arxiv.org/html/2603.23971v2
[gitar]: https://gitar.ai/blog/we-switched-to-a-5x-cheaper-llm-our-costs-went-up
[quadratic]: https://dreaming.press/posts/why-ai-agent-costs-scale-quadratically.html
[llmstats]: https://llm-stats.com/models/compare/gpt-5.6-luna-vs-qwen3.8-flash
