# Cortex Deep — Chain Templates

> Load this file when composing a multi-Eidolon chain (Dispatch Protocol
> Step 2, ≥2 co-triggering capability classes). See `EIDOLONS.md` for the
> always-loaded routing cortex and `roster/routing.yaml` for the
> machine-readable `chains:` block the kernel actually matches against
> (`eidolons run`; `requires_classes` selects the most-specific template).

Relocated out of the EIDOLONS.md always-loaded region per R-021/R-022
(generalist-eidolon P2 cortex re-fit) — this table was mislabeled
"(always-loaded)" while not actually needed for single-Eidolon dispatch.

---

## Chain Templates

| Template | Steps | When |
|----------|-------|------|
| **scout-diagnose-decide-plan-fix** | ATLAS → VIGIL → FORGE → RAMZA → Vivi → IDG | Every routed class present — the full pipeline (widest) |
| **scout-diagnose-plan-fix** | ATLAS → VIGIL → RAMZA → Vivi → IDG | Unfamiliar code + a live failure + a build |
| **scout-diagnose-decide-fix** | ATLAS → VIGIL → FORGE → Vivi → IDG | Unfamiliar code + a live failure + a decision + a fix |
| **plan-before-build** | ATLAS → RAMZA → Vivi → IDG | Unfamiliar code + multi-component change |
| **scout-diagnose-fix** | ATLAS → VIGIL → Vivi → IDG | Unfamiliar code + a live failure + a fix, no spec needed |
| **diagnose-then-plan-then-fix** | VIGIL → RAMZA → Vivi | A live failure that needs a spec before the patch |
| **scout-then-spec** | ATLAS → RAMZA | Discovery + spec verbs co-occur (V3) |
| **audit-without-touching** | ATLAS → IDG | "Audit", "explain", "review" with no write intent |
| **ship-fast** | RAMZA → Vivi | Known terrain, scoped feature |
| **direct-implementation-bypass** | ATLAS → Vivi (skip RAMZA) | Complexity < 7/12 AND small surface AND unambiguous reqs; emit `[DECISION]` |
| **decide-then-implement** | FORGE → RAMZA → Vivi | "Should we use X or Y, then build it" |
| **forensic-then-fix** | VIGIL → Vivi | Bug with reproduction + verified patch suggestion |
| **failed-attempt-recovery** | (prior coder failure) → VIGIL → Vivi | Conversation shows prior coder Reflect-exhaustion |
| **decision-only** | FORGE | No code touching; deliberation emitting verdict + assumptions |

### Specificity, and where it stops deciding

The kernel takes the matching template with the **most** `requires_classes`.
Before `chain-three-class` there was no three-class debugger template, so a
"diagnose it, spec it, fix it" prompt fell back to two-class **ship-fast** and
the **diagnosis step was silently dropped** — a planner received a failure
nobody had root-caused.

Equal-specificity matches are resolved by jq's *stable* sort, i.e. by
declaration order in `roster/routing.yaml` — an artifact, not a decision.
**Four** such pairs exist among the two-class templates and are pinned (not
endorsed) by `cli/tests/routing_chains.bats`. `scout-diagnose-plan-fix` exists
specifically so that adding `diagnose-then-plan-then-fix` did not create a
sixth: it covers the union of that pair's classes, keeping specificity
decisive. The three-class entry also *resolved* a pre-existing tie
(`ship-fast` vs `forensic-then-fix` at coder+debugger+planner), so the set
moved 6 → 5, and `scout-diagnose-fix` later resolved a second
(`audit-without-touching` vs `forensic-then-fix`), moving it 5 → 4.
**Adding a template means re-running that suite** — a new
collision, including one that merely duplicates an existing class set, fails
it rather than quietly letting line order choose in production.

A pair counts as resolved iff some template `C` has
`C.requires_classes ⊆ (A ∪ B)` **and** `|C| > |A|` — subset, matching the
kernel. An earlier revision of both this note and the test used set *equality*
with the union; that over-counted (7) and was blind to duplicate class sets.

Gilgamesh (generalist, fallback-only) never appears in a chain template —
it lives solely in Dispatch Protocol Step-2(a) (no specialist scores ≥ τ,
predicate resolves actionable). A chain always wins over the Step-2(a)/(b)
split when ≥2 capability classes co-trigger (Step 2's chain branch is
evaluated first).

See `methodology/cortex/handoff-graph.md` §"Chain Template Justifications"
for the edge-origin provenance of each template.
