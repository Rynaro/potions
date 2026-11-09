# Cortex Deep — ESL Protocol (Lifecycle Orchestration + Escalation)

> Load when composing a non-trivial change in an ESL-enabled project (Part 1,
> lifecycle orchestration), or when verifying / deciding the verify enforcement
> mode / recording escalation (Part 2, RECORD → HONOR). See `EIDOLONS.md`
> §"ESL — Spec Lifecycle" for the always-loaded summary; `README.md` for
> load-when guidance.

Two parts: **Lifecycle Orchestration** (how the orchestrator drives the full ESL
lifecycle by default — the per-Eidolon adoption) and the **Escalation
RECORD → HONOR** policy (advisory↔block enforcement). `esl-1.0.md` stays opt-in
and untouched; the orchestrator (not the Eidolons' own repos) composes the
tonberry artifacts in v1.0.

---

# Part 1 — Lifecycle Orchestration (per-Eidolon adoption)

## When it engages (opt-in + right-size gate)

The ESL lifecycle engages **only when** the project has OPTED INTO ESL (tonberry
installed/granted via `eidolons.mcp.lock`) **AND** the request is non-trivial.
ESL stays opt-in per `esl-1.0` §1.4. The mandatory mechanical right-sizing gate
(files-touched + /12 rubric + trade-off presence) applies at `proposed` entry:

- **Trivial** (≤2 files, /12 ≤ 4, no new behavior): Kupo direct micro-fix,
  **NO** lifecycle — preserve current Eidolon-only routing.
- **Lite** (bounded scope, /12 ∈ 5–6, single behavior, no trade-off): one-page
  SPECTRA spec (GIVEN/WHEN/THEN + acceptance_checks) + shortened lifecycle
  (states 0→2→3→4).
- **Full** (/12 ≥ 7 OR trade-off present OR system-wide blast radius): all five
  states with FORGE deliberation.

**Graceful degradation:** tonberry absent OR project not ESL-enabled → fall back
to normal Eidolon routing (spec→implement→review) WITHOUT lifecycle artifacts.
Never hard-fail.

## State Ownership & Orchestrator Actions

The orchestrator (never individual Eidolons' repos in v1.0) composes the tonberry
ops; each ESL state binds to an owning Eidolon. `<id>` = the change_id; the
change folder lives at `.spectra/changes/<change_id>/`.

| State | Owner Eidolon | Orchestrator action | Performative |
|-------|---------------|---------------------|--------------|
| `proposed` | SPECTRA (specify) | `tonberry propose --change_id <id> --maker vivi --checker <kupo\|vigil> --has_code <bool>`; `tonberry right_size …` → tier | `PROPOSE` |
| `[deliberated]` | FORGE (only full + real trade-off) | `tonberry transition … deliberated` after FORGE CRITIQUE/DECIDE; SKIP for lite/trivial | `CRITIQUE`→`PROPOSE`; `DECIDE` |
| (spec) | SPECTRA | emits `spec.{md,yaml}` into the change folder (lite = one-page) | (artifact) |
| `in_progress` | Vivi (MAKER, isolated worktree) | `tonberry transition … in_progress`; dispatch Vivi to implement | `DELEGATE` / `ACKNOWLEDGE` |
| `verified` | Kupo verifier (VIGIL on failure) — **MAKER ≠ CHECKER** | dispatch the DISTINCT checker to verify acceptance_checks; compose the verify envelope (`from.eidolon` = checker); `tonberry verify --mode <lock enforcement>`; `tonberry transition … verified` | `INFORM(verify_pass)` / `ESCALATE` |
| (drift) | the checker | `tonberry drift_check --checker <checker>` before archive | (internal) |
| `archived` | IDG (scriber) | `tonberry archive` (MOVES `.spectra/changes/<id>/` → `archive/<date>-<id>/`); IDG documents; route the promotion-intent envelope to `mcp__crystalium__ingest` if available | `ACKNOWLEDGE`; `INFORM(promotion)` |
| (escalation) | nexus | `eidolons mcp assess tonberry` records enforcement (on archive / cadence) — Part 2 | (meta) |

## Lifecycle Invariants

- **Maker ≠ Checker (C4):** promotion to `verified` requires a `verify_pass`
  envelope whose `from.eidolon` ≠ `change.json.maker`. Mechanically enforced by
  tonberry's C4 check. A self-verified change is a contract violation.
- **tonberry v0.4.0 ergonomics:** declare `has_code` at `propose` (read by
  `transition`); the lifecycle ops persist by default (`--dry-run` to preview);
  `archive` MOVES the folder, and `assess`/`list` count active + archived so the
  escalation signal survives the move.
- **Anti-scope:** the orchestrator composes the ops; per-Eidolon-repo methodology
  edits (so each Eidolon calls `mcp__tonberry__*` itself) are a future increment.

---

# Part 2 — Escalation Protocol (RECORD → HONOR)

ESL ships its **computation** (`tonberry assess`) and its **lever**
(`tonberry verify --mode warn|block`). This part closes the two missing hops —
**RECORD** the enforcement decision durably, and **HONOR** it when verifying —
without resurrecting a spec-lifecycle verb family. Owner split (FORGE verdict
H5): the **nexus** owns the lock-write; the **orchestrator** owns *when verify
runs*. `tonberry` never writes `eidolons.mcp.lock`.

## RECORD — `eidolons mcp assess tonberry`

The nexus subcommand `eidolons mcp assess <name>` runs the MCP's one-shot
`assess` op against the project, reads back
`{signals, thresholds, tripped[], recommended_mode}`, and **the nexus** (never
tonberry) upserts the decision into that MCP's `eidolons.mcp.lock` entry:

```jsonc
{
  "name": "tonberry", "kind": "oci-image", /* …existing fields… */
  "enforcement": "advisory",            // "advisory" | "block" — the recorded mode
  "enforcement_signals": {              // the numbers that produced it (auditability)
    "change_count": 7, "repo_loc": 41000, "full_ratio": 0.22
  },
  "enforcement_thresholds": { "N": 10, "L": 50000, "R": 0.4 },
  "enforcement_assessed_at": "2026-06-25T00:00:00Z"
}
```

The lockfile is VCS-committed, so the escalation is auditable in a PR diff.

**When to run it:** it **fires automatically at `eidolons mcp install tonberry`**
(the install cadence — a fresh install records an enforcement mode + signals so
the project starts with an honest advisory↔block strength), and on `archive` /
end-of-change (the orchestrator calls it after `mcp__tonberry__archive` — no
polling daemon). It also runs manually / on a cadence (after large growth or
before a release). Because `eidolons mcp sync` routes a not-yet-installed MCP
through `install`, the auto-assess rides that path too; an already-installed
no-op `sync` does not re-fire. The install auto-fire is gated strictly to
tonberry, is fail-open (it never aborts the install), and is suppressible with
`EIDOLONS_SKIP_AUTO_ASSESS=1` for CI / deterministic flows. An "advisory" result
is a normal exit 0, not a failure.

**Graceful skip (ESL opt-in):** if tonberry is not installed, or its `assess` op
is unavailable, `mcp assess` warns and exits 0 with no lock write — never
hard-failed.

**Idempotency carry-forward (load-bearing):** the catalogue-driven
`eidolons mcp install`/`refresh` entry-builders rebuild the lock entry and do NOT
know the `enforcement*` fields; `mcp_lock_upsert`'s no-op signature also excludes
them. The install/refresh path therefore **carries forward** any pre-existing
`enforcement*` before upsert (`mcp_lock_carry_enforcement`). A re-install MUST
NOT clear a recorded escalation. The `mcp assess` write bypasses the no-op
signature (`mcp_lock_set_enforcement`) so an enforcement-only change persists.

## HONOR — before `tonberry verify` on a project's changes

The verifying caller (orchestrator/cortex) chooses the verify mode with a
**two-layer fallback**:

| Condition | Action |
|---|---|
| `enforcement: "block"` recorded in the tonberry lock entry | Pass `--mode block` to `tonberry verify`. |
| `enforcement: "advisory"` recorded | Pass `--mode warn` (advisory). |
| **Field absent** (never assessed) | Run a live `tonberry assess` and honor its `recommended_mode`. |
| **tonberry absent** (not installed) | Default **advisory** and proceed — never block on a missing tool. |

Read the recorded mode with:

```sh
jq -r '(.mcps // [])[] | select(.name=="tonberry") | .enforcement // empty' eidolons.mcp.lock
```

The recorded mode is sticky and cheap; the live-assess fallback keeps the honor
hop correct when nothing has been recorded yet.

## Thresholds are tunable lock knobs (NOT baked constants)

| Knob | Seed | Meaning |
|------|------|---------|
| `N` | 10 | change_count — tracked changes before escalating |
| `L` | 50000 | repo_loc — repository lines of code |
| `R` | 0.4 | full_ratio — share of `full`-sized changes |

Recorded under `enforcement_thresholds` in the lock when an assessment runs, so
they travel with the project and can be tuned per-project. They are **not**
compiled into the nexus — it records whatever `tonberry assess` reports.

## Owner boundaries (anti-scope)

- **tonberry computes** `assess`; it never writes `eidolons.mcp.lock`.
- **nexus records** via `eidolons mcp assess` (the only writer of `enforcement*`).
- **orchestrator honors** by reading the lock field and choosing `--mode`.

No new top-level `eidolons spec`/`esl` verb is introduced.

---

## Provenance

- **ESL v1.0 spec** (`Rynaro/eidolons-esl/spec/esl-1.0.md`) §1–9 — state machine,
  maker/checker, drift, right-sizing, archive (§9.2 MOVE).
- **Dogfood trace** — nexus `.spectra/changes/mcp-assess-dry-run/RETRO.md`
  (propose→right_size→SPECTRA→Vivi→Kupo→verify→drift→archive, proven end-to-end).
- **tonberry v0.4.0** ergonomics (has_code at propose, ops persist, archive moves).
- **Escalation** — FORGE verdict H5 (`forge-escalation-autoflip-decision.md`).
