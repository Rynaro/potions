# Routing Artifact Schema

The routing artifact is emitted at Dispatch Protocol Step 5. This is the output
format the orchestrator produces after routing a prompt through the Eidolons
pipeline.

## Schema

```yaml
selected: [<eidolon>, ...]           # Eidolon(s) to dispatch
tier: standard | trance              # Execution tier
chain:                               # For multi-step chains
  - eidolon: <name>
    role: <role>
    hand_off_artifact_path: <path>
    edge_origin: <origin>
model_tier_per_step: [light | standard | deep, ...]  # Model tier per chain step
confidence: 0..1                     # Routing confidence score
assumptions: [...]                   # Assumptions made during routing
clarification_request: <string?>     # If underspecified, questions to ask
refusal_rerouting: <bool>            # True if rerouted due to refusal
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `selected` | Yes | Array of Eidolon names selected for dispatch |
| `tier` | Yes | `standard` (default) or `trance` (gated escalation) |
| `chain` | When multi-step | Ordered steps for chain execution |
| `model_tier_per_step` | When chain | Model capability tier per step |
| `confidence` | Yes | 0–1 score from verb matching |
| `assumptions` | No | List of assumptions the routing relied on |
| `clarification_request` | When underspecified | 1–3 clarifying questions |
| `refusal_rerouting` | No | True if top Eidolon refused and rerouted |

## Examples

### Single Eidolon dispatch

```yaml
selected: [Vivi]
tier: standard
confidence: 0.9
assumptions: ["prompt contains 'implement'"]
refusal_rerouting: false
```

### Chain dispatch

```yaml
selected: [ATLAS, RAMZA, Vivi]
tier: standard
chain:
  - eidolon: ATLAS
    role: scout
    edge_origin: roster
  - eidolon: RAMZA
    role: planner
    edge_origin: roster
  - eidolon: Vivi
    role: coder
    edge_origin: roster
model_tier_per_step: [light, standard, standard]
confidence: 0.75
assumptions: ["prompt spans scout+plan+implement phases"]
refusal_rerouting: false
```

### Clarification request

```yaml
selected: []
tier: standard
confidence: 0.3
clarification_request: "What specific outcome do you need? Is this a code change, documentation update, or investigation?"
```
