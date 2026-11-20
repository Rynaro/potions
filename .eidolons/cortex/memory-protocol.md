# Cortex Deep — Memory Protocol (CRYSTALIUM)

> Load this file when composing memory-aware chains, auditing tier gates,
> or configuring Dream consolidation. See `EIDOLONS.md` §"Memory protocol"
> for the always-loaded summary. See `README.md` for load-when guidance.

---

## 8-Tool Surface

| Tool | Purpose |
|------|---------|
| `recall` | Hybrid retrieval: vector similarity + BM25 + recency decay. Returns ranked entries from requested layers. |
| `commit` | Direct episodic write. Raw notes, intermediate findings. T0/T1/T2 (T3 quarantined). |
| `ingest` | ECL-envelope → memory. Derives tier from `from.eidolon`, preserves provenance + MIN-trust, scopes to `thread_id`. **Primary persist path.** |
| `update` | Bi-temporal invalidation: marks old entry superseded, writes new entry with `valid_from`. No hard-delete. |
| `skill_invoke` | Verifier-sandboxed procedural admission. Executes a skill from the procedural layer in a restricted evaluator; output is not auto-promoted. |
| `plan_checkpoint` | Execution-layer checkpoint: records current plan state under a `plan_id`. T0/T1 only. |
| `plan_replan` | Execution-layer replan: creates a new plan version branching from a checkpoint. T0/T1 only. |
| `session_end` | Triggers Dream consolidation worker. Marks the session boundary; Dream fires asynchronously (≥60s idle-poll). |

---

## Layer × Tier × Operation Matrix

| Layer | T0 (host/operator) | T1 (Eidolons) | T3 (tool-origin) |
|-------|--------------------|---------------|-----------------|
| **episodic** | R/W, recall, commit, ingest, update | R/W, recall, commit, ingest, update | ingest-only (quarantined; recall allowed) |
| **semantic** | R/W, recall, commit, update | R/W, recall, commit, update | — (TIER_CEILING) |
| **procedural** | R/W, recall, commit, skill_invoke | R/W, recall, commit, skill_invoke | — (TIER_CEILING) |
| **execution** | R/W, plan_checkpoint, plan_replan | R/W, plan_checkpoint, plan_replan | — (TIER_CEILING) |

**T0-only operations (CLI-only, no tool surface):** `forget` (hard-purge, operator only), `force_promote` (bypass corroboration gate), `review` (human-confirm queue).

**TIER_CEILING** = the server returns `reason_code: TIER_CEILING`; the caller must treat this as terminal (do not retry, do not bypass).

---

## Dream Consolidation

Dream is the async episodic→semantic promotion engine. It runs after `session_end` and on an idle-poll timer.

**Triggers:**
- `session_end` tool call (explicit — use once per host disconnect).
- Idle-poll: fires when no tool call has been received for `idle_threshold_s` seconds (default 60).
- Manual: operator `trigger_dream` CLI command (T0 only).

**Episodic → Semantic Gate:**
1. Candidate episodic entries are grouped by `topic_key` (derived from provenance tags).
2. A candidate passes if corroborated by ≥ `min_corroboration` independent sources (default 2) OR has `force_promote=true` (T0 only).
3. `MIN-trust` is preserved across promotion: the promoted semantic entry inherits the minimum trust tier of its corroborating episodic entries.
4. Promoted entries are tagged `promoted_by: dream` + `promotion_ts`.

**Pruning:**
- Episodic entries older than `episodic_ttl_s` (default 604800 = 7 days) and superseded by a promoted semantic entry are marked `status: pruned`.
- Pruning never removes entries with `pinned: true`.
- Hard-delete requires T0 `forget` call.

**Knobs (configurable per deployment):**

| Knob | Default | Effect |
|------|---------|--------|
| `idle_threshold_s` | 60 | Seconds of inactivity before idle-poll fires |
| `min_dream_gap_s` | 300 | Minimum seconds between consecutive Dream runs |
| `min_corroboration` | 2 | Minimum independent corroborating sources for auto-promotion |
| `episodic_ttl_s` | 604800 | Seconds before eligible episodic entries are pruned post-promotion |
| `importance_floor` | 0.3 | Entries below this importance score are pruned before TTL expires |

---

## `plan_checkpoint` / `plan_replan`

Designed for APIVR-Δ (coder) and FORGE (reasoner) execution-layer workflows. T0/T1 only (T3 TIER_CEILING).

**`plan_checkpoint(plan_id, state, step, metadata)`**
- Records the current execution state at a named step under `plan_id`.
- Idempotent: re-checkpointing the same `(plan_id, step)` updates in-place.
- Returns `checkpoint_id` for use by `plan_replan`.

**`plan_replan(plan_id, from_checkpoint_id, new_plan)`**
- Creates a new plan version branching from `checkpoint_id`.
- Old plan version is preserved (bi-temporal: marked `superseded_by: <new_version>`).
- Returns the new `plan_version` identifier.

**APIVR-Δ integration:** checkpoint at each Implement sub-step (A→P→I→V→Δ/R). On Reflect-exhaustion, `plan_replan` records the branching decision before VIGIL hand-off so the execution history is auditable.

**FORGE integration:** checkpoint each reasoning trace in G2 (≥3 plausible alternatives). `plan_replan` records which alternative was selected and why.

---

## `skill_invoke` — Verifier-Sandboxed Procedural Admission

Procedural layer entries are verified skills (e.g. "how to run the regression suite", "safe merge protocol"). `skill_invoke` executes them in a restricted evaluator to prevent untrusted escalation.

**Flow:**
1. Caller provides `skill_id` + `context`.
2. Server retrieves the procedural entry; verifies it passes current trust gates.
3. Executes in the sandboxed evaluator (read-only context; no writes to other layers during execution).
4. Returns `result` + `execution_trace`.
5. Result is **not** auto-promoted to any layer; caller must decide whether to `commit` a summary.

**T3 restriction:** T3 artefacts may not invoke skills (TIER_CEILING). T3 artefacts may not be used as `context` inputs to `skill_invoke` unless explicitly wrapped by a T1 caller.

---

## Bi-temporal `update` + Principled Forgetting

`update(entry_id, new_payload, reason)`:
- Marks the existing entry as `status: superseded`, sets `superseded_at` timestamp.
- Writes a new entry with `valid_from: now`, `supersedes: <entry_id>`.
- Bi-temporal invariant: the old entry remains queryable by timestamp-range queries.

**Principled forgetting (T0 `forget`):**
- `forget(entry_id, reason)` sets `status: hard_deleted`. Entry is removed from all retrieval indexes.
- Audit trail entry is written to the execution layer (T0-only; non-deletable).
- No cascading: superseded entries are not auto-deleted; only the targeted entry is purged.

---

## ECL-Envelope → `ingest` Mapping

When an ECL hand-off envelope (`ecl-envelope.json`) is present alongside an artefact, `ingest` is the **primary persist path** — it captures provenance that `commit` cannot.

| ECL field | CRYSTALIUM mapping |
|-----------|-------------------|
| `from.eidolon` | Determines caller tier (T1 for all six roster Eidolons) |
| `thread_id` | Scopes the memory entry to the current chain run (enables chain-level recall) |
| `performative` | Tags the entry's intent (e.g. `INFORM`, `REQUEST`, `CONFIRM`) |
| `integrity.value` (SHA-256) | Stored verbatim as `provenance.content_hash`; verifiable |
| `integrity.algo` | Stored as `provenance.hash_algo`; must be `sha256` for T1 ingest |
| `payload_path` | Relative path to the artefact; stored as `provenance.artifact_path` |
| `trace[]` | JSONL trace stream appended to `provenance.ecl_trace` (truncated at 4 kB) |

**Trust derivation:** the server validates that `from.eidolon` matches one of the six roster Eidolons. Unrecognized `from.eidolon` values ingest at T3 (quarantined episodic only).

**MIN-trust:** if the envelope carries multiple provenance hops (relay chain), the resulting trust tier is `min(hop_tiers)`. A chain that passes through a T3 artefact is stored at T3 regardless of the initiating T1 Eidolon.

---

## Open Questions Carried Forward

| ID | Assumption | Mitigation |
|----|------------|------------|
| OQ-M1 | T2 tier (human-collaborator) is reserved but not yet exposed via the tool surface. | Defer to v1.3; T2 slots in between T1 and T3 in the matrix. |
| OQ-M2 | `min_corroboration=2` is sufficient for auto-promotion without human review. | Raise to 3 for procedural entries (higher-stakes); monitor false-positive promotions. |
| OQ-M3 | `skill_invoke` sandboxed evaluator scope is sufficient to prevent procedural layer abuse. | Audit evaluator escape surface at v1.3; add evaluator signature verification. |
