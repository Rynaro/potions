# Agent display names

Every dispatched Eidolon uses this human-facing task label wherever the harness
exposes an override for a display name, task title, or visible task description:

`<Eidolon Name> [<Model> | <Effort>] - <Task>`

Example: `Vivi [Sol 6.1 | Medium] - Implementing Pokéball Experience`.

Use the roster's `display_name`, preserving case and punctuation (for example,
`ATLAS`, `Vivi`, `APIVR-Δ`). Generated agent adapters supply this identity.
For an unregistered package, use its manifest methodology, then its slug.
Task is a concise, specific description of the work; never leave `<Task>` literal.

Use the actual resolved model and reasoning effort for that worker, including
explicit runtime overrides or confirmed inherited settings. A routing tier
(`light`, `standard`, `deep`) is not a model or effort. Do not infer runtime
settings from a recommended profile or the parent when inheritance is unknown.
Use `Unknown` independently for each unavailable value; update the label when
resolved values become available. Never change execution settings just to match
a label.

Format known model IDs `gpt-<version>-<family>` as `<Family> <version>` for
families `sol`, `astra`, `luna`, and `terra`: `gpt-6.1-sol` becomes `Sol 6.1`.
Preserve other model IDs verbatim rather than inventing a product name. Capitalize
known effort values: `None`, `Minimal`, `Low`, `Medium`, `High`, `Xhigh`, `Max`,
`Ultra`. Preserve any other nonempty effort value verbatim.

Before dispatch, set the full label on a supported human-facing title/display
control; also use it in a visible task description if that is the only override.
Include it in the worker's assignment and ask the worker to keep its own title
current when the harness exposes that capability. For a standalone Eidolon,
apply this policy when the task becomes known. On task/model/effort changes,
refresh the label on that same task. In a multi-step chain label each worker
with its own identity and settings; never rename another worker's parent chat.

On Codex desktop, use `set_thread_title` for the current chat when exposed.
A restricted spawn identifier (including Codex collaboration `task_name`),
agent type, configured `name`, filename, routing key, or slug must stay stable
and valid. Do not put the formatted label in those fields or invent unsupported
configuration keys. Codex CLI, Claude Code, Copilot, OpenCode, Cursor, and future
harnesses follow the same capability-based rule: use only controls exposed by
the active tool schema. If no mutable display control exists, put the label in
the task assignment/visible heading; the harness's own fixed agent label may
remain unchanged. Static discovery descriptions cannot know a future task or
its runtime settings and therefore are not prefilled with guessed labels.
