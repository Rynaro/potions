# Cortex Deep Tables

Deep reference content for `EIDOLONS.md`. Loaded on demand per the progressive
disclosure principle (spec P3). The always-loaded section of `EIDOLONS.md` stays
under 900 tokens; detail that doesn't need to be resident in every session lives
here.

## Files in this directory

| File | Contents | Load when |
|------|----------|-----------|
| `agent-naming.md` | Cross-harness task display naming, runtime metadata, and identifier constraints | Before dispatch or standalone Eidolon work |
| `routing-artifact.md` | Schema and examples for the routing artifact emitted at Dispatch Protocol Step 5 | Emitting or parsing routing artifacts |
| `handoff-graph.md` | Canonical hand-off graph (union of roster + composition.md edges with origin labels), disambiguation table, and routing open questions | Composing a multi-Eidolon chain or auditing edge provenance |
| `chain-templates.md` | Full Chain Template table (steps + trigger condition per template) relocated from EIDOLONS.md's always-loaded region | Composing a multi-Eidolon chain (Dispatch Protocol Step 2 chain branch) |
| `trance-matrix.md` | TRANCE Activation Gates (G1–G6, relocated from EIDOLONS.md), per-Eidolon TRANCE capability matrix, cost ceiling rules, refusal gates | Evaluating or authorizing an TRANCE escalation |
| `dispatch-predicate.md` | The Step-2(a)/(b) mechanical predicate — closed lexicons, S1–S5 reference-extractor rules, tie-break, and the frozen normative fixture table | Auditing or reproducing a Step-2(a)/(b) actionable/underspecified routing decision (Gilgamesh fallthrough) |
| `validation-gates.md` | All 14 GIVEN/WHEN/THEN acceptance gates (V1–V14) the cortex must satisfy | Testing cortex behavior, writing new routing rules |
| `memory-protocol.md` | Full 8-tool CRYSTALIUM surface, layer × tier × operation matrix, Dream consolidation knobs, skill_invoke sandboxing, ECL-envelope → ingest mapping | Composing memory-aware chains, auditing tier gates, configuring Dream |
| `esl-protocol.md` | ESL cortex protocol — Part 1: lifecycle orchestration (per-Eidolon adoption: state ownership SPECTRA→FORGE→Vivi→Kupo/VIGIL→IDG, right-sizing gate, maker≠checker, tonberry v0.4.0 ergonomics); Part 2: escalation RECORD→HONOR (`eidolons mcp assess` lock-write, two-layer verify-mode fallback, idempotency carry-forward, N/L/R knobs) | Composing a non-trivial change in an ESL-enabled project; verifying ESL changes; choosing the verify enforcement mode; recording an escalation |
| `tier-execution.md` | Tier-indexed execution dial — how decomposition SHAPE scales with the WORKER's model tier (light/standard/deep): fixed pipeline vs bounded loop vs thin loop, edit-format and localization rules per tier, and the cross-tier constants (external verification, maker≠checker, read-only tests) that never dial down | Calibrating scaffolding density for a dispatched task; auditing why a step's shape looks heavier or lighter than expected |
| `context-protocol.md` | ECM context-lifecycle protocol — the meter + zone ladder (amber/red/critical), the autonomous decision table P1–P7 (first-match, never LLM-discretionary), the closed operation set (externalize/prune/compact/handoff-fresh/wrap-up), the pin set that survives lossy ops, externalize-before-compact + handoff-brief crystalium contracts, subagent economics, cache discipline C-1..C-4, and per-host coverage | Deciding a context action in a long/autonomous session; wiring or auditing ECM hook recipes; extending ECM to a new host |

## Token budget note

Each file here is on-demand only. A host that loads `EIDOLONS.md` and then
hits a chain-composition step should load `handoff-graph.md`; a host evaluating
whether to escalate to TRANCE should load `trance-matrix.md`. Neither is needed
for simple single-Eidolon standard-tier dispatch.

The cortex itself (EIDOLONS.md always-loaded section) + one deep table still
stays well inside the ≤3500-token specialist working-set budget
(`methodology/prime-directives.md D1`).
