# Step 1: Ideation (idea-explorer agent)

Goal: Expand a vague idea into concrete directions.

## Agent

`idea-explorer` (model: sonnet)

## Process

1. Invoke the `idea-explorer` agent with the user's idea description.
2. The agent produces `brainstorm.md` in the task subdirectory.
3. Register `brainstorm.md` in `_state.json` artifacts.
4. Present `brainstorm.md` to the user.

## State Update

After user confirms:
1. Set `currentStep` to `2`
2. Append `1` to `completedSteps`
3. Verify `artifacts.brainstorm` is set
4. Log to `history`

**Confirm with user before proceeding to Step 2.**
