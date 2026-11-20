# Cortex Deep — Validation Gates (V1–V14)

> The cortex's own self-test rubric. Each gate is an acceptance criterion for
> one routing class. Load this file when testing cortex behavior or writing
> new routing rules. See `EIDOLONS.md` for the always-loaded routing cortex.

---

## V1 — Pure-discovery prompt
GIVEN the prompt "map the auth flow"
WHEN no prior Eidolon has acted in this conversation AND surface size is unknown / small
THEN route to ATLAS standard tier; no chain; emit confidence ≥ 0.8.

## V2 — Discovery over large surface (TRANCE scatter)
GIVEN the prompt "map the entire monorepo's data layer"
WHEN cortex heuristic estimates surface > 25 files OR > 5 modules
THEN escalate to ATLAS-TRANCE; scatter sub-agents per module with `isolation: worktree`; aggregate via Abstract phase (G1). Emit `[DECISION]` recording the threshold trip.

## V3 — Spec-needs-research chain
GIVEN the prompt "I need a spec for refactoring the dispatcher; I don't know the call graph yet"
WHEN both discovery verbs and spec verbs co-occur
THEN emit chain ATLAS → SPECTRA; standard tier per step; record `edge_origin: roster`; hand-off artifact = `scout-report.md`.

## V4 — Brownfield bug fix (standard)
GIVEN the prompt "Fix the off-by-one in `flowmap_resolve`"
WHEN no prior failed attempt in conversation AND no stack-trace markers
THEN APIVR-Δ standard; chain length 1; bounded retry budget per `apivr-failure-recovery/SKILL.md:154-210`.

## V5 — Brownfield bug fix, second attempt → VIGIL
GIVEN the conversation contains a prior APIVR-Δ Reflect-exhaustion in this turn
WHEN the user re-prompts the same fix
THEN re-route to VIGIL; emit `[DECISION]` citing the failed-attempt-recovery chain template.

## V6 — Hard architectural decision, no code (FORGE)
GIVEN the prompt "Should we route via the hierarchical supervisor or a single-router for our 6-Eidolon roster?"
WHEN the prompt has decision verbs and no implementation verbs
THEN FORGE standard; chain length 1; output is verdict + assumptions + alternatives; no downstream chain.

## V7 — Documentation synthesis from multiple sources (IDG-TRANCE)
GIVEN the prompt "Write the ADR set covering all six methodology docs"
WHEN source artifact set ≥ N sections AND IDG topological order permits parallelism
THEN IDG-TRANCE (G5); per-section parallel synthesis; CHT verification per section; one-revision cap preserved.

## V8 — Ambiguous "design and implement X" (chain)
GIVEN the prompt "Design and implement the `--json` flag for `eidolons doctor`"
WHEN both design and implement verbs co-occur
THEN chain SPECTRA → APIVR-Δ; complexity scored against `spectra-planning/SKILL.md:14-19` (≤ 7/12 may bypass to direct APIVR-Δ — see V14).

## V9 — Stack trace + repeat failure → VIGIL fast-path
GIVEN a prompt containing a stack trace or "still failing after retry"
WHEN no prior VIGIL invocation
THEN VIGIL standard; bypass APIVR-Δ first-attempt path; record reason `confidence_boost: stack_trace_signal`.

## V10 — Free-form natural-language prompt with no Eidolon name (the headline case)
GIVEN the prompt "make sense of this codebase and propose a refactor plan"
WHEN no Eidolon name is in the prompt AND no host environment hint
THEN route via descriptor soft-match: ATLAS → SPECTRA chain; emit confidence and surface assumptions. This closes the routing gap identified in foundation `[F §5]`.

## V11 — Refused capability re-routes
GIVEN the prompt "ATLAS, please patch this file"
WHEN the named Eidolon would refuse (ATLAS write refusal)
THEN set `refusal_rerouting: true`; select APIVR-Δ instead; emit `[DECISION]` explaining the override; never ask ATLAS to write.

## V12 — Abstain / clarify rather than guess
GIVEN the prompt "do the thing"
WHEN no Eidolon scores ≥ τ AND no chain template matches
THEN emit `clarification_request` with 1–3 questions; do not dispatch; cap clarifications at 1 turn.

## V13 — TRANCE cost ceiling enforcement
GIVEN a prompt that would otherwise spawn 8 parallel branches
WHEN C1 (`max_parallel = 5`) would be exceeded
THEN decline unbounded fan-out; emit `[DECISION]` citing C1 with the proposed alternative (sequenced batches of 5); await user consent OR proceed at the cap with an `[ACTION]` flag.

## V14 — Direct-implementation bypass with justification
GIVEN the prompt "add a `--json` flag to `eidolons doctor`"
WHEN complexity < 7/12 AND surface is small AND ATLAS handoff allowed (`roster/index.yaml:60`)
THEN ATLAS → APIVR-Δ direct; skip SPECTRA; emit `[DECISION]` with the bypass justification.
