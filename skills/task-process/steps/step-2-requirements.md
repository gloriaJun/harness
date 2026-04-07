# Step 2: Requirements -> PRD (requirements-analyst agent)

Goal: Structure requirements into a formal PRD.

## Agent

`requirements-analyst` (model: sonnet)

## Input

One of the following (check `_state.json` artifacts):
- `artifacts.brainstorm` (from Step 1), OR
- User's requirements description, OR
- External planning document

## Process

1. Invoke the `requirements-analyst` agent with available inputs.
2. The agent produces `PRD-<task-name>.md`.
   - Location: project `docs/` if it exists, otherwise task subdirectory.
3. Register the PRD path in `_state.json` artifacts.

## Review (3-layer)

1. **Plannotator**: Open PRD in Plannotator for visual review.
   - If Plannotator is not available, present the PRD as text.
2. **User approval**: Wait for user to approve or request changes.
   - If revision requested: re-invoke agent, do NOT advance step.
3. **Codex cross-review**: After user approval, request Codex review.
   - Via codex-plugin-cc: `/codex:rescue "Review this PRD for missing requirements, ambiguity, and feasibility: <path>"`
   - Via Codex CLI: `codex exec --read <PRD-path> "Review this PRD: identify missing requirements, ambiguous items, and feasibility concerns"`
   - If Codex is not available, skip and note it.
4. Present Codex review results -> user decides whether to incorporate.

## State Update

After user confirms:
1. Set `currentStep` to `3`
2. Append `2` to `completedSteps`
3. Verify `artifacts.prd` is set
4. Log to `history`

**Confirm with user before proceeding to Step 3.**
