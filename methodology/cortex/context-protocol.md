# Cortex Deep — Context Protocol (ECM)

> Load when a session must decide a context-lifecycle action — measure the
> window, externalize state, compact, hand off to a fresh session, or wrap up on
> a budget ceiling. See `EIDOLONS.md` §"ECM — Context Lifecycle" for the
> always-loaded summary; `README.md` for load-when guidance. Canonical spec:
> [`Rynaro/eidolons-ecm`](https://github.com/Rynaro/eidolons-ecm) (v0.1); the
> shipped nexus policy is `roster/context-policy.yaml` + `roster/pins.yaml`.

ECM governs the **context economy** of a running session: when it externalizes
to memory, when it compacts, when it abandons the window for a fresh one, and how
all of that happens **autonomously — mechanically, with no human present to
notice degradation and intervene.** Every trigger is a deterministic gate over
observable signals, in the same doctrine as ESL's right-sizing gate. There is
**no LLM-discretionary context decision** anywhere in this protocol.

---

## When it engages (opt-in + fail-open)

ECM engages **only when** the project opts in via `eidolons.yaml`'s `context:`
block (absent ⇒ ECM off, status quo unchanged — family opt-in rule). When on,
the kernel verbs run at hook firings; when a signal is missing or a call fails,
the policy degrades to `continue` — **advisory systems fail open, never block.**

Kernel verbs (pure bash 3.2 + jq, non-LLM, table-driven):

| Verb | Does |
|------|------|
| `eidolons context status` | Refresh the meter sidecar `.eidolons/.context/meter.json` via the D1 estimation ladder |
| `eidolons context policy` | Evaluate `roster/context-policy.yaml` first-match-wins over the meter → emit the operation verdict |
| `eidolons context externalize` | Drive the crystalium checkpoint chain (file-floor fallback when crystalium absent) |
| `eidolons context handoff` | Compose the session-handoff brief + its ECL `INFORM` envelope, persist via `crystalium_ingest` |

---

## The meter + zone ladder

A sidecar (ECL doctrine: **sidecar-on-disk, never in-context-only**) at
`.eidolons/.context/meter.json`, refreshed by the kernel at hook firings.

- **Estimation ladder (D1, 3 rungs):** host telemetry where exposed (Claude Code
  statusline `context_window.used_percentage` — exact) → `bytes/4` transcript
  heuristic → fail-open `unknown`. No tokenizer container, ever. Boundaries are
  coarse 25-point bands so a ±10% estimate cannot mis-zone by more than one band.
- **Zone ladder** (survey F1, context-rot onset ~50%):
  `green < 0.50 ≤ amber < 0.75 ≤ red < 0.90 ≤ critical`.
- Meter computation is ≤ 300 ms and **never blocks**; failure ⇒ `zone: unknown`
  ⇒ policy `continue`.

---

## The decision table (autonomous policy)

Evaluated by `eidolons context policy` at hook firings. Observable signals only,
**never LLM-discretionary**. **First matching row wins.**

| # | Condition (all conjuncts) | Operation |
|---|---|---|
| P1 | `budget.ceiling` set AND `spent ≥ ceiling` | **wrap-up** — externalize → handoff brief → stop gracefully |
| P2 | `zone = critical` | **handoff-fresh** — emergency externalize first (minimal manifest allowed) |
| P3 | `zone = red` AND `compaction_count < 2` | **externalize → compact** (host surface; pins re-injected post-op) |
| P4 | `zone = red` AND `compaction_count ≥ 2` | **handoff-fresh** — depth cap reached (no summary-of-summary beyond 2) |
| P5 | `zone = amber` AND `tool_result_share ≥ 0.40` | **prune tool results** (host-supported clearing) + externalize |
| P6 | `zone = amber` | **externalize** — checkpoint now, while cheap — then continue |
| P7 | `zone = green` or `unknown` | **continue** (fail-open: unknown telemetry never escalates) |

Every verdict is appended to `.eidolons/.context/policy-log.jsonl` (signal
snapshot + rule fired + operation) — the audit trail a future evidence-based
revision of the table needs. The table is revisable only through ESL.

**Lateral signals** (orchestrator-evaluated, not the kernel — they need chain
context): repeat-failure ≥ 3 on one step → the `failed-attempt-recovery` chain
(VIGIL) with a **fresh** context, not a compacted one; independent subtask →
subagent isolation (existing TRANCE/Kupo dispatch).

---

## Operations

| Operation | Steps |
|-----------|-------|
| `continue` | no-op |
| `externalize` | `plan_checkpoint` → commit identifier manifest → `ingest` envelope if present |
| `prune_tool_results` | externalize → host clear tool results |
| `compact` | externalize → host compact → **pin re-inject** → pin verify+repair |
| `handoff_fresh` | externalize → compose handoff brief → ECL envelope → `crystalium_ingest(topic_key: session_handoff)` → `session_end` |
| `wrap_up` | `handoff_fresh` steps + emit wrap-up notice (budget-ceiling graceful stop) |

**Compaction depth cap = 2** per session (survey G4): beyond it, `handoff_fresh`
only — never summary-of-summary.

---

## Pin set — what survives every lossy operation

`roster/pins.yaml` ships the defaults; consumer projects may **extend, never
shrink**. Pins are re-injected via the post-compaction hook surface (Claude Code
SessionStart `source=compact`); a post-op probe greps the injected artifact for
pin markers and repairs by re-injection on miss. Advisory, never blocking. Pins
**never include T3-origin content** (Gap G3).

| Default pin | Why it must survive |
|---|---|
| Cortex routing digest | Routing dies silently without it |
| Active Eidolon's refusal table | Lossy ops drop instructions first (ACL 2026 pitfall) |
| ESL enforcement mode | Advisory-vs-block posture must not flip mid-session |
| Crystalium trust-tier map (T0/T1/T3) | Tier confusion after compaction = quarantine bypass |
| Active plan step + frozen criteria SHA-256 | RAMZA's criteria freeze is meaningless if the SHA doesn't survive |
| Session budget ceiling + compaction count | The policy's own inputs must survive the ops they trigger |

---

## Externalize-before-compact — the crystalium contract

Before any lossy operation the kernel drives, in order: `crystalium_plan_checkpoint`
(plan state, execution layer, idempotent per `(plan_id, step)`) →
`crystalium_commit(episodic)` (identifier manifest: `path:line` anchors, symbols,
decision IDs, failed-approach log, open variables) → `crystalium_ingest(envelope)`
when a hand-off envelope exists (primary persist path; provenance preserved).

Provenance carries `contains_tool_origin: true` whenever T3 content was in scope
— the surviving summary must not launder mixed trust (Gap G3). **Degradation:**
crystalium absent → warn once, write the manifest to
`.eidolons/.context/externalized-<ts>.json` as the file-only floor, continue.
Memory failures are never fatal (1.5 s timeout → skip).

---

## Handoff brief — session succession without a human

The fresh-start operation. Artifact pair: `.eidolons/.context/handoff-<ts>.md`
(structured brief — task state, decisions + one-line rationale, **failed
approaches** so the successor doesn't repeat them, open variables, exact
identifiers, next steps, budget ledger) + an ECL `.envelope.json` sidecar
(performative **`INFORM`**, artifact type `ecm/handoff-brief@0.1`, SHA-256
integrity, `thread_id` continuity).

The brief has a **1500-token advisory** composition target — the composer logs
when it exceeds but **never truncates** (D4: truncation drops exactly what a
brief exists to preserve). The **hard ≤ 200-token bound** applies only to the
one-time SessionStart-injected *digest*; the full brief is recalled on demand,
not injected. Flow: externalize → compose → `crystalium_ingest(topic_key:
session_handoff)` → `crystalium_session_end` (Dream fires) → successor's
`eidolons memory preflight` recalls the latest `session_handoff` and injects it.
Persist is `ingest`-canonical (no `commit` branch; file floor is the only
fallback). Round-trip is CI-verified: `eidolons canary --context-handoff`.

---

## Subagent economics (D3)

Each subagent session gets its **own** meter; all sessions append to one shared
`.eidolons/.context/budget-ledger.jsonl`; the budget ceiling is evaluated
**orchestrator-only**. A subagent that would hit `handoff_fresh` or `wrap_up`
**remaps to finish-and-return** — subagents cannot spawn successors.

---

## Cache discipline (prefix stability as a named invariant)

Provider caches key on exact prefix match; truncate-from-front halves hit rates.
ECM names four conformance points (most already hold in the nexus):

- **C-1** Stable-prefix ordering: cortex digest / agent files / tool defs precede
  volatile content; per-prompt injections **append**, never mutate the prefix.
- **C-2** Byte-stable generated sections: `sync` idempotency + marker-bounded
  blocks are load-bearing for cache hits.
- **C-3** Never truncate-from-front. Reduction is host tool-result pruning,
  compaction, or handoff — all prefix-preserving.
- **C-4** Per-prompt injected artifacts ≤ ~200 tokens (bound the volatile tail's
  cache-miss cost).

---

## Host coverage

The kernel + decision table are **host-agnostic**; only the hook *recipe wiring*
is host-specific. Coverage is per-host because hosts expose radically different
context-injection channels — some per-tool, some session-start-only, some none.
Fail-open is by construction: a host with no runtime channel still gets the T0
documentary floor and the policy `continue` on `unknown`.

| Host | Tier | ECM surface (shipped/planned) |
|---|---|---|
| Claude Code | T3 | **Shipped (P1):** SessionStart(`compact`) pin re-inject + handoff recall; UserPromptSubmit meter digest + policy verdict; PostToolUse meter refresh (inject on zone change only); statusline exact telemetry; `compactThreshold: 75` don't-clobber. **PreCompact is NOT a documented hook** — externalization is amber-eager (P5/P6) instead. |
| Codex / Copilot / Cursor / OpenCode | T3–T1 | **P2 (in progress):** each host wired to whatever injection channel it actually exposes — full ladder where a per-tool/per-prompt channel exists, session-start-only inject where only that exists, documentary floor where none does. Never assume a host capability; verify it. |
| any | T0 floor | Cortex §Context protocol prose — status quo, never worse. |

**Atomos MCP: GO** — a dedicated context-lifecycle MCP is a committed **P3 build**
(maintainer decision 2026-07-07, `docs/specs/ecm/decisions/atomos-go-no-go.md`),
fenced to a **compose/verify executor** (brief composition + pin/envelope
verification), never injection/meter/policy/trigger. It is **additive**: the
kernel-verbs path stays the canonical, always-available implementation, and
atomos does not solve cross-host injection (nothing host-external can — injection
is a host-surface property). FORGE's prior NO-GO recommendation is retained in the
decision record as atomos's scope fence and design caveats; the P2-exit delete
tripwire is retired (atomos builds in parallel, informed by P2 evidence).

---

## The ten P0s (non-negotiable)

Opt-in · mechanical gates only · sidecar-on-disk · pin set survives every lossy
op (post-op verify+repair) · externalize-before-compact mandatory when crystalium
present (file-floor + warn when absent, never block) · compaction depth cap = 2 ·
anti-scope (never re-declare crystalium layers/tiers, never extend ECL's ten
performatives, never re-implement host compaction, never touch serving-layer) ·
bash 3.2 + stderr discipline + ≤ 300 ms prompt path · fail-open (only stop is the
budget ceiling's *graceful* wrap-up) · every verdict audited.
