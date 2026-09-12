const GUIDANCE = `\
## Task scope — classify before acting

State mode once, then proceed: "Mode N — [one-line rationale]"

| Mode | When | What |
|------|------|------|
| 0 | Trivial, obvious, reversible | Do it. No preamble. |
| 1 | Intent worth stating; plan is overhead | One sentence of intent. Do it. |
| 2 | Accumulated design intent; assumption risk | Bounded-implementation contract (below). |
| 3 | Non-trivial design; multiple viable approaches | brainstorming → writing-plans → SDD |
| 4 | Behavior correctness critical; bad tests plausible | Mode 3 + test-strategy-review |
| 5 | Broad/risky/destructive/cross-platform | Mode 4 + verification matrix + audit passes |

**Mode 2 — bounded-implementation contract:**
1. Derive 3-7 testable acceptance criteria from the request.
2. Name canonical source files and explicit non-goals (what will NOT change).
3. Implement the smallest change that satisfies the criteria.
4. Verify adversarially: check diff against each criterion; reject wrong-source edits,
   scope creep, unsupported assumptions; fix before presenting.
5. Report evidence per criterion and any human-only checks remaining.

No worktrees. No durable tests unless explicitly requested.
Stop and ask if criteria cannot be grounded in available evidence.
For Mode 3+, invoke the appropriate superpowers skills instead.`;

const IMPL_VERBS =
  /\b(add|fix|update|create|implement|refactor|change|delete|remove|build|write|modify|move|rename|replace|migrate|configure|set[\s-]?up|install|enable|disable|convert|generate|extract|deploy|integrate|extend|improve|optimize|debug|resolve|rewrite|restructure|clean[\s-]?up|format|lint)\b/i;

const ACKNOWLEDGMENT =
  /^(ok|okay|thanks?(?:\s+you)?|got\s+it|makes?\s+sense|sounds?\s+good|looks?\s+good|perfect|great|sure|alright|cool|noted|understood|agreed|yep|yup|nope|no\s+worries)[.!\s]*$/i;

const QUESTION_START =
  /^(what|why|how|when|where|who|which|is |are |was |were |do |does |did |can |could |would |should |will |has |have |had )/i;

function isConversational(prompt: string): boolean {
  if (ACKNOWLEDGMENT.test(prompt)) return true;
  if (IMPL_VERBS.test(prompt)) return false;
  if (prompt.endsWith("?")) return true;
  if (QUESTION_START.test(prompt)) return true;
  return false;
}

export default function (pi: any) {
  pi.on("before_agent_start", async (event: any) => {
    const prompt = (event.prompt ?? "").trim();
    if (prompt.length < 10) return;
    if (isConversational(prompt)) return;
    return {
      systemPrompt: event.systemPrompt
        ? `${event.systemPrompt}\n\n${GUIDANCE}`
        : GUIDANCE,
    };
  });
}
