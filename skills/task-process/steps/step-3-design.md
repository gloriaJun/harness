# Step 3: Design -> TRD (system-architect agent)

## Skip Condition

Skip if **both** are true:
- No UI or design changes involved
- Logic-only change within a single system or file

If skipping:
1. Set `artifacts.trd` to `"skipped"`
2. Inform the user and proceed to Step 4

## Agent

`system-architect` (model: sonnet)

## Input

- `artifacts.prd` from `_state.json` (required)
- Existing codebase context

## Process

1. Invoke the `system-architect` agent with the PRD and codebase context.
2. The agent produces `TRD-<task-name>.md` (+ `architecture.md` if needed).
   - Location: same directory as PRD.
3. Register the TRD path in `_state.json` artifacts.

## Review (3-layer)

1. **Plannotator**: Open TRD in Plannotator for visual review.
2. **User approval**: Wait for approval or changes.
   - If revision requested: re-invoke agent, do NOT advance step.
3. **Codex cross-review**: Request Codex review of TRD.
   - Focus: technical feasibility, missing edge cases, security concerns.
4. Present Codex review results -> user decides whether to incorporate.

## State Update

After user confirms:
1. Set `currentStep` to `4`
2. Append `3` to `completedSteps`
3. Verify `artifacts.trd` is set (or `"skipped"`)
4. Log to `history`

**Confirm with user before proceeding to Step 4.**
