# Wiki: Process Notes + Devlog Cleanup

Capture process notes to the vault and clean up the devlog directory.
This is the final step of the dev lifecycle.

## Pre-condition

1. Read `_state.json` from the task directory.
2. Verify `currentStep == 7` (retro done). If not, warn and ask to confirm.
3. Extract: `taskName`, `history`, `artifacts.retro` for context.

## Process

### Step 1: Process Notes

Delegate to `vault-wiki-process` skill inline:

1. Load `~/Documents/obsidian-vault/.claude/skills/vault-wiki-process/SKILL.md` via Read tool.
2. Execute vault-wiki-process workflow with task context pre-filled:
   - **task-name**: `_state.json` → `taskName`
   - **scope**: `work` (default; confirm if ambiguous)
   - **retro-path**: `artifacts.retro` (for cross-linking)
3. vault-wiki-process saves to: `~/Documents/obsidian-vault/04_Notes/process/<scope>-YYYY-MM-DD-<task-name>-process.md`

### Step 2: Devlog Cleanup

After process note is saved, clean up the devlog directory:

1. Show contents of the task directory for review.
2. Ask (Single Choice):
   ```
   Devlog task directory: <task-dir>
   Contents: _state.json, <artifacts list>

   What to do with the devlog?
   1. Delete entirely
   2. Archive (move to _archive/)
   3. Keep as-is

   > 번호 입력
   ```
3. Execute the chosen action. Delete only after explicit confirmation.

4. Update `_index.md`:
   - Read `<devlogs-root>/_index.md`
   - Find the row matching the current task directory name
   - If deleted or archived → remove the row entirely
   - If kept → update "상태" column to `완료`
   - Update frontmatter `updated:` to today's date

## State Update

1. Update `_state.json` (if not deleting):
   - Set `currentStep` to `8`
   - Append `7` to `completedSteps`
   - Register wiki file path in `artifacts.wiki`
   - Append to `history`: `{ "step": 7, "action": "wiki saved + devlog cleaned", "timestamp": "ISO 8601" }`

## Completion

```
🎉 Task complete — <taskName>

Vault artifacts:
  📄 retrospect: <retro-path>
  📄 process:    <wiki-path>

Devlog: <deleted / archived / kept>
```

Task lifecycle is now complete. No next step.
