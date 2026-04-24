# Idea: Development Ideation

Goal: Expand a vague development idea into a structured brainstorm document.

## Process

### 1. Capture the Idea

Ask the user to describe their idea freely — no structure required yet.
If already provided in the trigger message, use that as input.

### 2. Invoke idea-explorer Agent

Dispatch the `idea-explorer` agent (model: sonnet) with the user's description.

The agent will:
- Ask clarifying questions (one at a time) to explore the idea
- Identify the problem being solved, who benefits, and potential approaches
- Produce `brainstorm.md` in the task directory

### 3. Register Artifact

Save `brainstorm.md` to the devlog task directory:
```
<devlogs-root>/<task-dir>/brainstorm.md
```

Register in `_state.json`:
```json
{ "artifacts": { "brainstorm": "brainstorm.md" } }
```

### 4. Present and Confirm

Show the brainstorm to the user.
Ask: "Ready to move to planning? (y / edit / stop)"

- `y` → proceed to handoff
- `edit` → apply user corrections and re-show
- `stop` → save state and exit (resume later with `/dev plan`)

## State Update

`currentStep` → 2, append 1 to `completedSteps`, `artifacts.brainstorm` ← path

Follow update mechanics from `schemas/state.md`.

## Session Handoff

Read `steps/_handoff.md` and follow the handoff instructions.
Next sub-command: `/dev plan`
