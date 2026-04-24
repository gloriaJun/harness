# Plan: Requirements → PRD

Goal: Structure requirements into a formal PRD.

## Agent

`requirements-analyst` (model: sonnet)

## Input

One of the following (check `_state.json` artifacts):
- `artifacts.brainstorm` (from idea step), OR
- User's requirements description, OR
- External planning document

## Process

1. Invoke the `requirements-analyst` agent with available inputs.
2. The agent produces `PRD-<task-name>.md`.
   - Location: project `docs/` if it exists, otherwise task subdirectory.
3. Register the PRD path in `_state.json` artifacts.

## Review

Load `references/review-protocol.md` and execute the full review workflow.
- **Artifact**: PRD at `artifacts.prd`
- **Codex focus**: "Review this PRD for missing requirements, ambiguity, and feasibility"

## State Update

`currentStep` → 3, append 2 to `completedSteps`
`artifacts.prd` ← PRD path
`reviews.prd` ← `{ mode, fallbackReason, approvedAt }`

Follow update mechanics from `schemas/state.md`.

## Session Handoff

Read `steps/_handoff.md` and follow the handoff instructions.
Next sub-command: `/dev design`
