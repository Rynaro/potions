<!-- eidolon:cortex start -->
# EIDOLONS.md — Routing Cortex

> Always-loaded routing cortex for the Eidolons nexus.
> A host LLM reading this file once at session start can route any
> free-form prompt to the correct Eidolon(s), at the correct tier,
> in the correct chain. No vendor model names appear here — capability
> classes and tier ladder only (`light < standard < deep`). The concrete
> model per tier is set by the active profile in `roster/model-profiles.yaml`;
> use `eidolons model` to inspect or change it. See §DEEP for extended
> tables loaded on demand.
>
> The `<!-- always-loaded:start/end -->` pair below marks the byte range a
> mechanical CI check counts against the I-C4 ≤900-token budget. The check
> uses a configurable chars-per-token proxy (default `--ratio 3` for Claude
> 4.7+ which produces ~30% more tokens; use `--ratio 4` for older tokenizers).
> CI fails > 850 to leave headroom — see `.github/workflows/ci.yml`
> "cortex-token-budget" and `scripts/token-budget-check.sh`. Everything
> outside the markers is on-demand and does not count.

---

<!-- always-loaded:start -->
## Roster

| Name | Class | Triggers | Refuses | Handoff |
|------|-------|----------|---------|---------|
| ATLAS | scout | map, trace, where does, how does, investigate, analyze, audit (read-only) | implement, fix, edit, write, commit | RAMZA, Vivi, IDG |
| RAMZA | planner (default) | spec, plan, decompose, clarify requirements, decision-ready | implement code, modify files | Vivi, IDG |
| SPECTRA | planner (opt-in) | named dispatch only | implement code, modify files | Vivi, IDG |
| Vivi | coder (default) | implement, build, fix, refactor, optimize, migrate, make tests pass | design from scratch, novel architecture | IDG |
| APIVR-Δ | coder (opt-in) | named dispatch only | design from scratch, novel architecture | IDG |
| IDG | scriber | document, ADR, runbook, write up, summarize | explore repo, find calls, retrieve | (terminal) |
| FORGE | reasoner | trade-off, compare, evaluate, which approach | implement, retrieve, synthesize prose | (lateral) |
| VIGIL | debugger | diagnose, debug, root cause, flaky, why does X fail | build new feature, plan from scratch | (lateral) |
| Kupo | executor | rename, import/path fix, lockfile bump, lint autofix, one-line edit, search-replace | design, plan, cross-cutting refactor | (orchestrator-dispatched) |
| Gilgamesh | generalist (fallback-only; zero triggers—Step-2(a) only) | | design, plan, deploy, migrate, route, spawn, underspecified | (orchestrator-dispatched; PROPOSEs upward) |

## Dispatch

**Default:** delegate via pipeline; orchestrator does not implement, spec, or scout directly. Direct answer only for trivial/conversational/single-fact. Tier default `standard`; TRANCE gated, never automatic.

1. **Classify** — extract verbs, match triggers, score 0–1.
2. **Gate** — ≥0.8 one Eidolon, ≤1 verb class: dispatch standard. ≥0.6 for ≥2 OR spans ≥2 classes: chain (`chain-templates.md`). <0.6 all (`dispatch-predicate.md`): (a) actionable → Gilgamesh; (b) underspecified → `clarification_request` (1–3 questions), do NOT dispatch. Gilgamesh never enters Step 1, never outranks specialist ≥τ.
3. **Refusal** — top Eidolon refuses → reroute + emit `[DECISION]`.
4. **Tier** — default `standard`; `trance` only with complexity AND stakes flags (`trance-matrix.md`).
5. **Artifact** — emit (`routing-artifact.md`): `{selected, tier, chain:[{eidolon, role, hand_off_artifact_path, edge_origin}], model_tier_per_step, confidence, assumptions, clarification_request?, refusal_rerouting}`.
<!-- always-loaded:end -->

---

## Agent display names

Before dispatch or standalone Eidolon work, load `.eidolons/cortex/agent-naming.md`
(`methodology/cortex/agent-naming.md` in the nexus checkout). Apply its
`<Eidolon Name> [<Model> | <Effort>] - <Task>` pattern to every supported
human-facing title or task description, using actual runtime settings.

---

## Chain Templates

Chain templates route a prompt spanning ≥2 co-triggering capability classes
to a scripted step sequence. Full table (steps + trigger condition) relocated
on demand: `methodology/cortex/chain-templates.md`.

---

## TRANCE Activation Gates

TRANCE grants parallel fan-out, worktree isolation, verifier-cascade
wrapping, an evaluator-optimizer loop, and a model-tier upgrade — never the
default; auto-trigger requires both a complexity flag AND a stakes flag.
Full gate table (G1–G6) + refusal invariants relocated on demand:
`methodology/cortex/trance-matrix.md` §"Activation Gates".

---

## Confidence Signals

| Signal | Effect | Target |
|--------|--------|--------|
| Stack trace, panic, "still failing after retry" | +0.3 | VIGIL |
| Surface > 25 files or 5 modules | +0.2 | ATLAS-TRANCE |
| "Greenfield", "from scratch", "novel" | −0.3 | the coder class (Vivi and APIVR-Δ refuse greenfield) |
| "I don't have a spec yet" | +0.2 | RAMZA |
| Prior failed coder attempt in conversation | +0.4 | VIGIL |
| Eidolon named explicitly in prompt | +0.5 | that Eidolon (still check refusal table) |
| Multiple SDLC phases ("scout and spec and build") | chain trigger | (see Chain Templates) |

---

## Memory protocol — CRYSTALIUM MCP

When `crystalium` is installed (`grants_to_eidolons: all`), every dispatched Eidolon runs a mandatory pre-flight + post-flight against the harness. Direct file writes to crystalium's data dir are forbidden; **all reads and writes funnel through MCP tool calls** so the chokepoint can enforce tier × layer × operation.

**Wiring:** crystalium is `wiring_mode: allowlist/direct` — `mcp__crystalium__*` tools ARE injected into each Eidolon's agent `tools:` allowlist (same as atlas-aci; opposite of junction's transport-only wiring).

| Step | Tool call | When |
|------|-----------|------|
| Pre-flight | `mcp__crystalium__recall(scope, query, k=5, layers=[semantic, episodic])` | First action of every dispatch — recall relevant prior context before reasoning |
| Write spine | `mcp__crystalium__ingest(ecl_envelope)` | Primary persist path — ingest the ECL hand-off envelope; derives T1 identity from `from.eidolon`, preserves provenance + MIN-trust |
| Raw notes | `mcp__crystalium__commit(layer=episodic, payload, provenance)` | Direct episodic write — mission notes, intermediate findings |
| Plan gate | `mcp__crystalium__plan_checkpoint / plan_replan` | APIVR-Δ and FORGE execution-layer checkpoints (T0/T1 only) |
| Session end | `mcp__crystalium__session_end()` | Once per host disconnect — enqueues the Dream consolidation worker |

**Trust-tier map:**

| Tier | Callers | Permitted layers |
|------|---------|-----------------|
| T0 | Host / operator (CLI-only: forget, force_promote, review) | All four layers |
| T1 | ATLAS / SPECTRA / APIVR-Δ / IDG / FORGE / VIGIL | episodic, semantic, procedural, execution |
| T3 | Tool-origin artefacts (enter via `ingest` only) | episodic (quarantined); may never write semantic/procedural/execution |

**ECL → ingest mapping:** when a hand-off envelope is available, `ingest(ecl_envelope)` is the primary commit path. The field `from.eidolon` determines tier (T1 for all six Eidolons). `thread_id` scopes to the current chain run. SHA-256 provenance is preserved verbatim from the envelope's `integrity.value`.

**Refusals are mechanical:** if any crystalium tool returns `reason_code: TIER_VIOLATION`, `TIER_CEILING`, or `PROMOTION_GATE`, treat as terminal for that path — do **not** retry with a different tier, and do **not** mutate the data dir directly to bypass. The chokepoint catches what gets caught.

**Deep table:** `methodology/cortex/memory-protocol.md` — full 8-tool surface, layer × tier × operation matrix, Dream consolidation knobs, skill_invoke sandboxing, bi-temporal update rules.

**Append-only:** This section is the wire-time enforcement of crystalium usage. Removing it disconnects the team's memory. Edit only via additive amendments — do not delete columns or rows.

---

## Invariants

- **I-C1** — Marker-bounded sections when embedding into shared host files (`<!-- eidolon:cortex start/end -->`).
- **I-C2** — No `eval` of routing rules; descriptor table is data, dispatch is interpretive.
- **I-C3** — Capability classes + vendor-neutral tiers only (`light < standard < deep`). Never vendor model names.
- **I-C4** — Always-loaded section (`<!-- always-loaded:start/end -->`) ≤ 900 tokens; deep tables in `methodology/cortex/`. CI enforces a conservative proxy ceiling (default `chars/3 ≤ 850` for Claude 4.7+ tokenizer; use `--ratio 4` for older tokenizers).
- **I-C5** — Refusals are immutable; cortex must never request a refused capability of a target Eidolon.
- **I-C6** — Same prompt + same context + same roster ⇒ same routing decision.
- **I-C7** — `roster/index.yaml` is the source of truth; new Eidolons auto-appear, removed Eidolons disappear. `roster/mcps.yaml` is the closed MCP catalogue; `eidolons mcp list|show|install|refresh|uninstall|upgrade|sync|health|run` is the unified verb set (v1.3+).
- **I-C8** — `[GAP]` and `[DISPUTED]` over silent merge when routing is genuinely ambiguous.
- **I-C9** — Bash 3.2 compatibility for any CLI helper consuming a cortex artifact.
- **I-C10** — Stderr discipline for all tooling logs; stdout reserved for captured values.
- **I-C11** — Single writer per chain step — at most one Eidolon holds write authority at a time; scouts and checkers never write. Mechanical form: read-only tool allowlists (member-side) + strict-tier PreToolUse recipes (host-side).

---

**ECL — Wire Format.** Inter-Eidolon hand-offs use the **Eidolons Communication Layer (ECL v1.0)** wire format: every emitted artefact carries a JSON sidecar envelope (`ecl-envelope.json`) containing the performative, sender/receiver identities, a SHA-256 integrity tag, and a JSONL trace stream. ECL is opt-in for v1.0; existing Eidolons remain conformant unchanged. Machine-readable hand-off contracts live at [`Rynaro/eidolons-ecl/contracts/`](https://github.com/Rynaro/eidolons-ecl/tree/main/contracts).

**ESL — Spec Lifecycle.** Eidolons changes may follow the **Eidolons Spec Lifecycle (ESL v1.0)**: a right-sizable state machine + a mandatory mechanical right-sizing gate (trivial→Kupo / lite→one-page / full→full) + a drift/living-spec contract, with **maker≠checker** enforced on the verify envelope. The grammar (states, `change.json` schema, bash conformance checker) lives at [`Rynaro/eidolons-esl`](https://github.com/Rynaro/eidolons-esl); it reuses SPECTRA artifacts, ECL envelopes, and CRYSTALIUM layers. Opt-in for v1.0. **Escalation HONOR:** before `tonberry verify` on a project's changes, read `enforcement` from the tonberry `eidolons.mcp.lock` entry — `block` ⇒ pass `--mode block`; field absent ⇒ live `tonberry assess`, honor `recommended_mode`; tonberry absent ⇒ advisory. Record it with `eidolons mcp assess tonberry` (see `methodology/cortex/esl-protocol.md`). **Lifecycle (opt-in):** for ESL-enabled projects, non-trivial changes run the full lifecycle by default — propose→[deliberate]→implement→verify→drift→archive across RAMZA→FORGE→Vivi→Kupo/VIGIL→IDG (maker≠checker), orchestrator-composed via tonberry; trivial→Kupo direct.

**ECM — Context Lifecycle.** Long-running and autonomous sessions manage their own context economy via the **Eidolons Context Management (ECM v0.1)** protocol — a deterministic, table-driven meter + zone ladder (amber 0.50 / red 0.75 / critical 0.90) that fires context operations (externalize · prune · compact · handoff-fresh · wrap-up) with **no human in the loop and no LLM discretion**: first-match-wins rules P1–P7 over a `.eidolons/.context/meter.json` sidecar. A pin set survives every lossy op; externalize-before-compact checkpoints through CRYSTALIUM; session succession emits an ECL `INFORM` handoff brief; compaction depth caps at 2. Opt-in via `eidolons.yaml`'s `context:` block; **fail-open** when telemetry is absent. Kernel verbs `eidolons context status|policy|externalize|handoff` + host-hook recipes (each host wired to whatever injection channel it exposes — Claude Code full at P1; Codex full, OpenCode start+per-prompt, Copilot/Cursor static-floor at P2). Spec: [`Rynaro/eidolons-ecm`](https://github.com/Rynaro/eidolons-ecm). Deep table: `methodology/cortex/context-protocol.md`.

*Deep tables (chain templates, TRANCE matrix, hand-off graph, disambiguation table, validation gates, ESL protocol, tier execution dial, context protocol, dispatch predicate, open questions) load on demand from `methodology/cortex/`. See `methodology/cortex/README.md`.*

<!-- eidolon:cortex end -->
