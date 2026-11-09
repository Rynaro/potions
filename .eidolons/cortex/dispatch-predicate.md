# Cortex Deep — Dispatch Step-2(a)/(b) Predicate (Gilgamesh fallthrough)

> Load this file when auditing or reproducing a Dispatch Protocol Step-2(a)/(b)
> routing decision (the mechanical actionable/underspecified split gating
> Gilgamesh, the generalist fallthrough worker). See `EIDOLONS.md` for the
> always-loaded Step-2 summary. This table is copied verbatim from the frozen
> ESL change `generalist-eidolon` acceptance criteria
> (`.spectra/changes/generalist-eidolon/acceptance-criteria.md`, SHA-256
> `d088c0cc58b72330bea3f61fc376c1f7c5e1086496c1d3297793d1cf3f9ff8d8`) — it is a
> reference copy for on-demand cortex loading, not a re-declaration; the ESL
> change document remains the source of record.

Relocated out of the EIDOLONS.md always-loaded region per I-C4/R-021/R-022 —
the full lexicons and fixture table are far too large to keep resident every
session; only the Step-2(a)/(b) split + the invariant sentence stay
always-loaded.

---

## Scope

Predicate input is **English only**. Non-English, emoji-only, or
code-fenced-only prompts route to `clarification_request` by design (the
English lexicons below simply do not match, so S1=0 → clarify).

## Reference extractor

Phrase-normalize (see phrase table below) → whitespace-tokenize (retain each
token's backtick/trailing-punct info) → compute S1..S5. S6/S7 are declared
preconditions from the Step-1 scorer (S6 = no specialist scored ≥ τ; S7 =
fewer than 2 capability classes trigger-hit, i.e. no chain owns it).
**Predicate** (only evaluated when S6 ∧ S7 hold): `actionable = S1 ∧ S2 ∧ S3 ∧ S4 ∧ S5`.
Any signal indeterminate → `0` (tie-break biases to `clarification_request`).

| Signal | Rule |
|---|---|
| **S1 act_verb** | `1` iff ∃ token `t` with core ∈ ACT_VERBS, core ∉ EXCLUDED_POLYSEMOUS, `t` in **imperative position** (previous token is a CLAUSE_MARKER or `t` is first), and previous-token-core ∉ DET_BLOCKLIST. Kills noun-sense hits ("the recent patch", "the update"). |
| **S2 deliverable** | `1` iff ∃ core ∈ DELIVERABLE_NOUNS OR ∃ PATH_OR_ID token |
| **S3 named_target** | `1` iff ∃ PATH_OR_ID token (a generic word alone never satisfies S3) |
| **S4 acceptance** | `1` iff ∃ core ∈ ACCEPTANCE_MARKERS OR a numeric target token |
| **S5 bounded** | if no GENERIC_SCOPE token → `1`; else `1` iff (∃ LIMITER token) **AND** (∃ PATH_OR_ID token), else `0` (a co-occurring path alone does NOT neutralize a generic scope) |

## Closed lexicons (presence-matched, case-insensitive, word-boundary)

Phrase pre-normalization runs first, replacing each multi-word phrase with an
underscore-joined single token: `set up→set_up, look into→look_into, figure
out→figure_out, look at→look_at, deal with→deal_with, work on→work_on, roll
back→roll_back, limited to→limited_to, so that→so_that, exits 0→exits_0,
without error→without_error, no longer→no_longer, the project→the_project,
the codebase→the_codebase, the app→the_app, the repo→the_repo, the
system→the_system, entire codebase→entire_codebase`.

- **ACT_VERBS**: `add, create, write, implement, build, fix, edit, modify,
  update, rename, remove, delete, refactor, migrate, configure, wire,
  install, generate, apply, patch, replace, extend, rewrite, convert, bump,
  upgrade, set_up, scaffold, append, insert, enable, disable, revert,
  rollback, roll_back, seed, provision, compile, lint, format, export,
  import, publish, init, bootstrap, stub, deprecate`
- **EXCLUDED_POLYSEMOUS** (never satisfy S1): `make, improve, handle,
  deal_with, work_on, better`
- **INVESTIGATE_VERBS**: `look_into, investigate, figure_out, explore,
  analyze, review, understand, explain, find, trace, map, diagnose,
  look_at, check, audit`
- **DELIVERABLE_NOUNS**: `file, patch, function, method, class, module,
  endpoint, route, script, config, test, fixture, migration, workflow,
  schema, table, component, flag, cli, ci, pipeline, dockerfile, readme,
  docs, hook, rule, field`
- **GENERIC_SCOPE**: `everything, everywhere, all, entire, whole,
  project_wide, repo_wide, codebase, throughout, across, anything,
  somewhere, the_project, the_codebase, the_app, the_repo, the_system,
  entire_codebase`
- **LIMITERS**: `only, just, limited_to, solely, exclusively`
- **ACCEPTANCE_MARKERS**: `so_that, until, passes, passing, matches,
  returns, expected, equal, green, exits_0, without_error, no_longer,
  fixes`; plus a numeric target = an `^[0-9]+%?$` token that is `%`-suffixed
  or immediately followed by a word token
- **FILE_EXT** (closed): `ts tsx js jsx py rb go rs sh bash json yaml yml
  toml md txt sql bats java kt c h cpp cs php lock cfg ini env`
- **CLAUSE_MARKERS**: `<start-of-prompt>, and, then, also, to, please`, or
  the previous token ended with `, ; : .`
- **DET_BLOCKLIST**: `the, a, an, this, that, these, those, my, our, your,
  his, her, its, their, no, any, some, each, every`

### PATH_OR_ID token (tightened)

A token is `PATH_OR_ID` iff ANY holds (evaluated on the token core = strip
surrounding backticks + edge punctuation):

1. **path** — contains `/` and contains ≥1 `[A-Za-z]` (e.g.
   `cli/src/status.sh`, `src/legacy/`)
2. **known extension** — matches `^([A-Za-z0-9_.\-]*)\.([A-Za-z0-9]+)$`
   where the extension ∈ FILE_EXT **and** the stem contains ≥1 `[A-Za-z]`
   (so `30.5s`, `2.5.0`, `3.14`, `e.g.` do NOT match)
3. **fenced identifier** — the raw token was backtick-fenced and the fenced
   core matches `^(--)?[A-Za-z_][A-Za-z0-9_-]*$` (e.g. `` `getUserData` ``,
   `` `--json` ``, `` `retry` ``)

Bare acronyms/mixed-case words (`CI`, `REST`, `gRPC`) are NOT PATH_OR_ID.

### Lexicon versioning policy

An out-of-lexicon verb never sets S1 (S1=0 → the predicate resolves to
`clarification_request` per the AND-combinator, unless routed elsewhere by a
specialist). Extending ACT_VERBS/DELIVERABLE_NOUNS/etc. requires amending
the frozen ESL change criteria (a new SHA-256 freeze) — never a silent
in-flight edit, so the derivability self-check (AC-C11) keeps holding.

---

## Normative predicate fixtures (machine-derived; frozen)

S1..S5 are the reference-extractor output; S6,S7 are declared preconditions.
Two independent conforming extractors MUST produce identical S1..S5 vectors.
No cell below is hand-set.

| Fixture | Prompt (verbatim) | S1 | S2 | S3 | S4 | S5 | S6 | S7 | Route |
|---|---|----|----|----|----|----|----|----|---|
| P1 | Make the project better. | 0 | 0 | 0 | 0 | 0 | 1 | 1 | clarification_request |
| P2 | Improve performance somewhere in the codebase. | 0 | 0 | 0 | 0 | 0 | 1 | 1 | clarification_request |
| P3 | Rename `getUserData` to `fetchUserProfile` everywhere it appears and update all call sites and the docs. | 1 | 1 | 1 | 0 | 0 | 1 | 1 | clarification_request |
| P4 | Look into the flaky checkout test and figure out what's going on. | 0 | 1 | 0 | 0 | 1 | 1 | 1 | clarification_request |
| P5 | Set up CI for the project. | 1 | 1 | 0 | 0 | 0 | 1 | 1 | clarification_request |
| P6 | Weigh whether we should use REST or gRPC for the new service and set it up. | 0 | 0 | 0 | 0 | 1 | 1 | 0 | chain (decide-then-implement) |
| P7 | In `services/auth/Login.ts`, explain what the recent patch does and why the update matters, until it's clear to me. | 0 | 1 | 1 | 1 | 1 | 1 | 1 | clarification_request |
| P8 | Configure the timeout to 30.5s until the healthcheck returns healthy. | 1 | 0 | 0 | 1 | 1 | 1 | 1 | clarification_request |
| P9 | Refactor `src/legacy/` across the entire codebase to remove deprecated calls, until the test suite is green. | 1 | 1 | 1 | 1 | 0 | 1 | 1 | clarification_request |
| P10 | Crea el archivo `src/app.py` y anade la funcion `login` para que el test pase. | 0 | 1 | 1 | 0 | 1 | 1 | 1 | clarification_request |
| P11 | Bump the dependency to 2.5.0. | 1 | 0 | 0 | 0 | 1 | 1 | 1 | clarification_request |
| C1 | Add a `--json` flag to `cli/src/status.sh` and update `cli/tests/status.bats` so the new case passes. | 1 | 1 | 1 | 1 | 1 | 1 | 1 | generalist |
| C2 | Refactor the auth layer. | 1 | 0 | 0 | 0 | 1 | 1 | 1 | clarification_request |
| C3 | Create `scripts/backup.sh` that dumps the DB to `./backups/` and exits 0 on success. | 1 | 1 | 1 | 1 | 1 | 1 | 1 | generalist |
| C4 | Update everything. | 1 | 0 | 0 | 0 | 0 | 1 | 1 | clarification_request |
| C5 | Append a `retry` field to `config/http.yaml` so requests retry 3 times. | 1 | 1 | 1 | 1 | 1 | 1 | 1 | generalist |
| C6 | Replace the deprecated call across `src/auth/` only, until the auth tests pass. | 1 | 1 | 1 | 1 | 1 | 1 | 1 | generalist |

P7 (noun-trap), P8 (version/decimal), P9 (generic-scope + path), P10
(non-English), P11 (version) are regression fixtures. C6 exercises the
LIMITER rescue (bounded generic scope).

**Executable form:** `scripts/dispatch-predicate-extractor.sh` (bash 3.2) +
`cli/tests/dispatch_predicate.bats` implement this table as a deterministic,
no-LLM self-check (AC-C05/AC-C06/AC-C11) plus the routing-outcome assertions
(AC-C01/C02/C07/C08/C09/C10/C12).
