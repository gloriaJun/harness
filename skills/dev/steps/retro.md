# Retro: Session Retrospective

Capture a retrospective note for the completed task and save it to the Obsidian vault.
Requires an active devlog with `currentStep >= 6` (complete step done).

## Pre-condition

1. Read `_state.json` from the task directory.
2. Verify `currentStep == 6` (complete step done). If not, warn and block.
3. Extract: `taskName`, `history`, `artifacts` for context.

## Process

Delegate to `vault-retro` skill inline:

1. Load `~/Documents/obsidian-vault/.claude/skills/vault-retro/SKILL.md` via Read tool.
2. Execute the vault-retro workflow with task context pre-filled:
   - **task-name**: `_state.json` → `taskName`
   - **scope**: `work` (default; ask user to confirm if ambiguous)
   - **context**: summarize from `history` entries and artifacts list
3. vault-retro saves to: `~/Documents/obsidian-vault/04_Notes/retrospect/<scope>-YYYY-MM-DD-<task-name>-retrospect.md`

## State Update

After vault-retro completes:

1. Update `_state.json`:
   - Set `currentStep` to `7`
   - Append `6` to `completedSteps`
   - Register retro file path in `artifacts.retro`
   - Append to `history`: `{ "step": 6, "action": "retro saved", "timestamp": "ISO 8601" }`

## Session Handoff

Read `steps/_handoff.md` and follow the handoff instructions.

```
Next: /dev wiki
```
