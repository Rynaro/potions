# Cortex Deep — Tier Execution Dial

> Load this file when calibrating how much scaffolding a dispatched task
> should carry, or auditing why a step's execution shape looks heavier or
> lighter than expected. See `EIDOLONS.md` for the always-loaded routing
> cortex and the tier ladder definition (`light < standard < deep`).

---

## Why a dial, not one shape

Execution SHAPE — how much the orchestrator pre-decomposes work before
handing it to the WORKER — is not a fixed property of a methodology. It is a
function of the WORKER's model tier. 2026 ablation evidence (fixed-workflow
vs free-agent comparisons; scaffold-gap measurements across SWE-bench-class
suites) shows fixed-workflow structure adds **12–22 points** below the
frontier and **≈0 points** at the frontier. Below the frontier, an
unstructured worker wanders; at the frontier, structure is dead weight the
worker pays for in latency and rigidity without buying correctness. One
scaffold for every tier either starves the weak worker or throttles the
strong one — the dial exists so neither happens.

---

## The Dial

| Tier | Shape | Decomposition | Localization | Edit format | Validation | Done-decision |
|---|---|---|---|---|---|---|
| **light** | Fixed pipeline | Orchestrator pre-decomposes; worker receives ONE bounded step per call (one file/location) | Mechanical (grep/index) — never model-driven exploration | Whole-file or search/replace — **never** unified diff | Mechanical check (lint/parse/test) after every step, before the next is issued | External verifier only; escalation is a deterministic rule (verifier cascade), never worker self-assessment |
| **standard** | Bounded loop | Worker drives `eidolons sandbox loop` end-to-end within `--k`/`--protect` bounds | Worker-driven within the loop's guardrails | Search/replace | Fanout (parallel-sample-and-select) preferred over iterate on non-thinking hosts; pass^k re-run gate | External verifier |
| **deep** | Thin loop | Full-task scope; iterate shape allowed (self-repair across attempts) | Worker-driven | Either format; unified diff permitted | Two-tool minimalism (bash + file-edit) — scaffolding is minimized because it adds ≈nothing at this tier | External verifier |

---

## Cross-tier constants (never dial down)

These hold at every tier, including `deep`. The dial adjusts scaffolding
*density*, never the verification boundary:

- **External verification never scales down.** Every tier ends at a
  verifier the worker does not control — dialing up the tier thins the
  scaffold, not the gate.
- **Maker ≠ checker, at every tier.** The Eidolon that writes the patch is
  never the Eidolon (or self-assessment) that certifies it.
- **Test files are read-only to the executor** — the anti-tamper ratchet.
  A worker that can edit the test it's judged against is not verified by
  that test.
- **Acceptance criteria are frozen before work starts.** The dial changes
  how a worker gets to "done," never what "done" means.

---

## Consumers

The dial is descriptive, not a new mechanism — these existing surfaces are
already instances of it:

- **Vivi**'s host-adaptive ITERATE/FANOUT branch (`roster/routing.yaml`
  `loop_native: true`) — iterate on thinking hosts, fanout on standard
  hosts is the standard↔deep half of this dial in code.
- **APIVR-Δ**'s conservative non-loop fallback (`loop_native: false`) — the
  light-tier posture for hosts/contexts where the loop shape itself is
  wrong.
- **Kupo**'s bounded ≤2-file micro-task scope — the light-tier row taken to
  its floor: one orchestrator-dispatched step, mechanically verified.
- **`eidolons sandbox loop`'s escalation cascade** (`roster/aci.yaml`
  `escalation:` — category-counter/ceiling → VIGIL hand-off) — deterministic
  escalation by rule, never the worker's own "I'm done" claim.

`roster/routing.yaml` `suggested_tier` (and any future `degraded_mode` /
`fallback` keys) carry this dial as data; this table is the prose the data
implements.

---

## Open Questions Carried Forward

| ID | Assumption | Mitigation |
|----|------------|------------|
| OQ-T1 | The 12–22 point structure-gap figure generalizes past SWE-bench-class coding tasks to the full Eidolons task surface (docs, planning, forensics). | Treat as a coding-tier calibration until cross-class telemetry exists; do not extend the dial to non-coder classes without evidence. |
