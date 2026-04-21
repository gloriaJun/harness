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

1. **Review mode selection (required)**: Ask the user to choose one mode.
   - 1) Plannotator visual review (default)
   - 2) Inline text review
   - 3) Skip review
2. **Plannotator attempt (when mode=1)**:
   - Check `plannotator` command availability first.
   - If available, run Plannotator review on the PRD.
   - If unavailable or launch fails, show a visible warning and ask confirmation:
     - `[WARN] Plannotator CLI is unavailable. Switching to inline text review.`
     - `Continue with inline text review? (Y/n)`
   - If user says no: stay in this step and let the user choose retry/skip.
   - If user says yes (or default): fall back to inline text review.
3. **User approval**: Wait for user to approve or request changes.
   - If revision requested: re-invoke agent, do NOT advance step.
4. **Codex cross-review**: After user approval, request Codex review.
   - Via codex-plugin-cc: `/codex:rescue "Review this PRD for missing requirements, ambiguity, and feasibility: <path>"`
   - Via Codex CLI: `codex task --effort low --read <PRD-path> "Review this PRD: identify missing requirements, ambiguous items, and feasibility concerns"`
   - If Codex is not available (Bash restricted or CLI missing):
     - Invoke `code-reviewer` agent (model: sonnet) for cross-review instead.
     - Note the fallback in `_state.json` history.
5. Present Codex review results -> user decides whether to incorporate.

## State Update

After user confirms:
1. Set `currentStep` to `3`
2. Append `2` to `completedSteps`
3. Verify `artifacts.prd` is set
4. Record review metadata in `_state.json.reviews.prd`:
   - `mode`: `plannotator | text | skipped`
   - `fallbackReason`: `plannotator_cli_unavailable | plannotator_launch_failed | null`
   - `approvedAt`: ISO 8601
5. Log to `history`

**Confirm with user before proceeding to Step 3.**
