# Cortex Deep — TRANCE Tier Matrix

> Load this file when evaluating or authorizing an TRANCE escalation.
> See `EIDOLONS.md` for the always-loaded routing cortex; the Activation
> Gates table below was relocated here from EIDOLONS.md per R-021/R-022
> (generalist-eidolon P2 cortex re-fit) — it was mislabeled
> "(always-loaded)" while not actually needed for single-Eidolon dispatch.

---

## Activation Gates

TRANCE grants: parallel fan-out (max 5 branches), worktree isolation per branch, verifier-cascade wrapping, evaluator-optimizer loop (cap 3 iterations), model-tier upgrade (lead = deep, workers = light).

TRANCE is **never** the default. Auto-trigger requires **both** a complexity flag AND a stakes flag. Cost warning emitted at ≥ 5× standard-tier budget.

| Gate | Eidolon | Condition |
|------|---------|-----------|
| G1 — Discovery scatter | ATLAS | Surface > 25 files OR > 5 modules → scatter sub-agents per module, aggregate via Abstract phase |
| G2 — Hard-decision consistency | FORGE | ≥ 3 plausible alternatives AND (high-stakes flag OR explicit TRANCE token) → N=3 reasoning traces, majority-vote |
| G3 — Spec evaluator-optimizer | RAMZA | Complexity ≥ 7/12 AND (high-stakes OR ambiguous reqs) → generator + evaluator, max 3 iterations |
| G4 — Parallel implementation | Vivi | RAMZA emitted > 1 independent story AND budget bounded → one Vivi per track, worktree isolation |
| G5 — Doc parallel synthesis | IDG | Large source artifact set AND topological order allows parallelism → per-section parallel, CHT per section, one-revision cap preserved |
| G6 — Forensic counterfactuals | VIGIL | ≥ 2 plausible root-cause hypotheses AND bisect surface allows independent testing → parallel hypothesis tests on isolated bisects |

**TRANCE refusals (immutable):** A refused capability does not become available at TRANCE. ATLAS still does not write. RAMZA still does not implement. IDG still does not retrieve. FORGE still does not tool-call. VIGIL still does not auto-apply patches. Per-Eidolon retry budgets remain enforced inside TRANCE. Gilgamesh (generalist, fallback-only) has no TRANCE form — it dispatches only at `standard` tier via Step-2(a); TRANCE escalation never applies to a Step-2(a) fallthrough.

---

## Per-Eidolon TRANCE Capability Matrix

| Eidolon | TRANCE form | Granted | Forbidden at TRANCE |
|---|---|---|---|
| ATLAS | Scatter sub-agents per module | Parallel fan-out (G1); worktree isolation; Abstract-phase aggregation | Writing, editing — D2 refusal stands |
| RAMZA | Evaluator-optimizer loop on draft spec | Generator + evaluator + termination gate (G3); cap 3 iterations | Implementing code; > 3 cycles |
| SPECTRA | Evaluator-optimizer loop on draft spec | Generator + evaluator + termination gate (G3); cap 3 iterations | Implementing code; > 3 cycles |
| Vivi | Parallel feature branches in worktrees + verifier cascade | Multi-track implementation (G4); per-track verifier; loop shape remains bounded | Writing in a shared tree without isolation; novel architecture |
| APIVR-Δ | Parallel feature branches in worktrees + verifier cascade | Multi-track implementation (G4); per-track verifier; reflection memory bounded ≤ 3 retries | Re-attempting beyond category budget; writing in shared tree without `isolation: worktree` |
| IDG | Parallel doc-section synthesis | Per-section parallelism with topological respect (G5); CHT verification per section | Retrieval; > 1 revision per section |
| FORGE | Self-consistency on reasoning chains | N=3 (or N=5 high-stakes) sampled traces with majority-vote / judge-merge (G2) | Tool calls, retrieval, code emission; debate without heterogeneity |
| VIGIL | Parallel hypothesis testing on isolated bisects | Counterfactual fan-out on worktrees (G6); 5-intervention budget preserved | Auto-apply patches; writing outside `verified-patch.diff` |
| Gilgamesh | None (standard-only fallback) | Bounded Step-2(a) fallthrough work | TRANCE escalation; routing, spawning, specialist or underspecified work |

---

## Model Tiers

The tier ladder `light < standard < deep` assigns a vendor-neutral capability level to each Eidolon. Concrete model strings live exclusively in `roster/model-profiles.yaml` (never in this file or EIDOLONS.md — PD #162).

**FORGE-derived per-class defaults:**

| Eidolon | Suggested tier | Rationale |
|---|---|---|
| SPECTRA | deep | Planner; spec quality gates require full reasoning |
| RAMZA | deep | Default planner; mission-critical requirements and decision quality |
| FORGE | deep | Deliberation; self-consistency via N=3 traces |
| VIGIL | deep | Forensic; counterfactual chains require depth |
| ATLAS | standard | Scout; deterministic retrieval first, LLM second |
| APIVR-Δ | standard | Coder; `loop_native:false` — deep is benchmark-gated |
| Vivi | standard | Default coder; iterative implementation and verification |
| Gilgamesh | standard | Bounded fallback generalist; autonomous non-specialist work |
| IDG | light | Scriber; synthesis from provided context |
| Kupo | light | Executor; localized micro-tasks |

**Resolution precedence** (most-specific wins): per-member PIN → per-tier calibration → active profile → roster `suggested_tier` → class default → nexus `default_profile`. Use `eidolons model show` to inspect resolved values; `eidolons model use` to override.

---

## Cost Ceiling Rules

| Rule | Value | Rationale |
|---|---|---|
| C1 — Max parallel branches | 5 | Empirical sweet spot for orchestrator-workers |
| C2 — Max model-tier upgrade | lead = deep, workers = light | Mirrors research-system topology; D9 |
| C3 — Max wall-clock | Host-enforced; cortex emits `wall_clock_budget_seconds` hint | Cortex never spins indefinite background jobs without user opt-in |
| C4 — Token budget warning | Emit `[DECISION]` at ≥ 5× standard-tier budget | 15× lift number is upper bound, not default |
| C5 — Surface-size threshold | > 25 files OR > 5 modules = large surface | Heuristic; configurable |
| C6 — Auto-trigger requirement | Both complexity flag AND stakes flag must hold | Either alone keeps cortex at standard tier |

---

## Refusal Gates (TRANCE MUST NOT override these)

- **R1** — Refused capabilities remain refused at TRANCE. ATLAS still does not write. SPECTRA still does not implement. IDG still does not retrieve. FORGE still does not tool-call. VIGIL still does not auto-apply patches.
- **R2** — FORGE parallel fan-out is reasoning-only. FORGE's TRANCE is self-consistency on reasoning chains; it does not gain tool access.
- **R3** — Bounded budgets are inviolable. Per-Eidolon retry budgets remain enforced inside TRANCE. TRANCE adds parallelism, not a fresh budget.
- **R4** — D5 unbounded reflection forbidden. TRANCE may not extend reflection loops past published caps (SPECTRA 3 cycles, IDG 1 revision, APIVR ≤ 3 same-category attempts).
- **R5** — Partial-team deployment degrades gracefully. If a needed Eidolon is not installed (`eidolons.lock` check), TRANCE is degraded: cortex emits a `[GAP]` and a fallback chain rather than spawning fan-out into a member that doesn't exist.

---

## Confidence Thresholds

| Threshold | Value | Source |
|---|---|---|
| τ_standard (min to dispatch) | 0.6 | Hybrid-LLM dial behavior [D §3.2] |
| τ_trance (min to auto-escalate) | 0.8 | RouteLLM preference data [D §2 #1] |
| FORGE consensus floor | 60% | Self-Consistency threshold [D §3.6] |

`[OQ-2]` Assumption: τ values are reasonable defaults until calibration experiment shows optimal point is far off. Tune from routing-decision logs.

---

## Open Questions Carried Forward

| ID | Assumption | Mitigation |
|---|---|---|
| OQ-1 | LLM-self-routing against descriptors is good enough for v1. | Migrate to calibrated classifier (RouteLLM) when mis-routing > 10% in telemetry. |
| OQ-4 | TRANCE-on-demand is the right v1 stance. | Add TRANCE-default flag in `eidolons.yaml`; cortex still emits `[DECISION]` at C4 ceilings. |
| OQ-7 | Self-consistency at N=3/N=5 is right for FORGE-TRANCE. | Tune from logs; drop N back to 3 or standard if empirical evidence disagrees. |
