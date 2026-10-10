---
name: evidence-driven-investigation
description: Use when investigating why something happens, evaluating a proposed explanation, or determining which uncertain mechanism is responsible. Enforces explicit separation of observation, inference, and assumption; falsifiable hypotheses; evidence-strength assessment; and tests designed to distinguish competing explanations. Compose with domain-specific skills such as systematic-debugging rather than replacing them.
---

# Evidence-Driven Investigation

Use this skill to govern evidence quality and hypothesis testing during uncertain investigations.

Domain-specific skills remain responsible for execution. For example, when debugging, use this alongside `systematic-debugging`.

## Core Principle

Reasoning is not evidence.

A plausible explanation remains a hypothesis until supported by observation.

## Workflow

### 1. State the Hypothesis

Express the current explanation as a falsifiable claim.

Identify:

- what you think is happening
- why it is plausible
- what observation would falsify it

Prefer one leading hypothesis at a time. Keep alternatives visible when existing evidence does not distinguish them.

### 2. Separate Observation From Inference

Distinguish:

- **Observed:** directly reproduced, measured, logged, inspected, or otherwise verified
- **Inferred:** explanation derived from observations
- **Assumed:** currently unverified premise

Never present inference or assumption as observed fact.

### 3. Prefer Stronger Evidence

Prefer evidence in roughly this order:

1. Direct reproduction or observation
2. Complete causal evidence connecting cause to effect
3. Partial causal evidence
4. Analogy to similar systems or known behavior
5. Reasoning alone

Reasoning alone can justify investigation. It does not establish a cause.

### 4. Test for Falsification

Design the smallest practical test that distinguishes the hypothesis from plausible alternatives.

Prefer tests that:

- vary or observe one relevant factor
- expose the suspected causal boundary
- predict different outcomes depending on whether the hypothesis is true
- avoid changing the system toward the proposed fix before establishing the cause

Seek disconfirming as well as confirming evidence.

### 5. Update From Evidence

After meaningful new evidence:

- state what it establishes
- state what it does not establish
- reject or revise contradicted hypotheses
- identify remaining uncertainty

Do not preserve a hypothesis merely because it remains plausible.

### 6. Match Action to Evidence

Require evidence proportionate to the cost and reversibility of the action.

Low-risk, reversible experiments may proceed with incomplete evidence.

Destructive, broad, expensive, or difficult-to-reverse changes require stronger causal evidence.

When strong evidence is unavailable, state the residual uncertainty explicitly.

## Resource Mapping

When uncertainty about available mechanisms affects the investigation, verify the capability boundary before assuming it.

Check relevant:

- tools and permissions
- existing code, configuration, tests, and instrumentation
- supported APIs or interfaces
- project documentation and implementation patterns

Skip this when available capabilities are already clear.

## Failure Modes

Do not:

- treat plausibility as proof
- search only for confirming evidence
- change multiple variables in one diagnostic experiment
- use the suspected fix as the primary test of the hypothesis
- silently convert assumptions into facts
- assign false precision to confidence estimates
- continue defending a hypothesis after contradictory evidence

## Composition

When debugging, combine this skill with `systematic-debugging`.

`systematic-debugging` owns the debugging procedure: reproduce, trace, isolate, test, fix, and verify.

This skill owns the epistemic discipline: what is observed, what is inferred, what would falsify the explanation, how strong the evidence is, and what uncertainty remains.
