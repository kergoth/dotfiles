const GUIDANCE = `\
Classify the task and proceed. For modes 1+, open with the label:

| Mode | Label | When | What |
|------|-------|------|------|
| 0 | *(silent)* | Trivial, obvious, reversible | Do it. |
| 1 | "Quick task — [intent]" | Intent worth stating | One sentence of intent. Do it. |
| 2 | "Bounded implementation — [rationale]" | Accumulated design intent; assumption risk | Bounded contract (below). |
| 3 | "Design + plan — [rationale]" | Non-trivial design; multiple viable approaches | brainstorming → writing-plans → SDD |
| 4 | "Test-first — [rationale]" | Correctness critical; bad tests plausible | Mode 3 + test-strategy-review |
| 5 | "High assurance — [rationale]" | Broad/risky/destructive/cross-platform | Mode 4 + verification matrix + audits |

Modes 0–2: this policy overrides broad skill triggers. Don't invoke workflow skills unless task facts independently require them. Mode 2 uses its bounded contract; Mode 3+ invokes the appropriate skills.

**Mode 2 contract:**
1. Derive 3-7 testable acceptance criteria.
2. Name canonical source files and explicit non-goals.
3. Implement the smallest change that satisfies the criteria.
4. Verify adversarially against each criterion; reject wrong-source edits, scope creep, unsupported assumptions; fix before presenting.
5. Report evidence per criterion and remaining human-only checks.

No worktrees or durable tests unless requested. Ask if criteria can't be grounded in evidence.`;

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
      message: {
        customType: "workflow-mode-selection",
        content: GUIDANCE,
        display: false,
      },
    };
  });
}
