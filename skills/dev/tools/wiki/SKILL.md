# Wiki — Process Notes + Devlog Cleanup

Capture process notes to the Obsidian vault and optionally clean up the devlog directory.
Works with or without a devlog. Final step of the dev lifecycle.

---

## Entry Check

**Resolve devlogs root** from cwd:

| cwd contains | devlogs root |
|---|---|
| `GitHubWork` | `~/Documents/GitHubWork/_claude/devlogs/` |
| `GitHubPrivate` | `~/Documents/GitHubPrivate/_claude/devlogs/` |
| neither | ask the user |

**Scan for candidate tasks** (either condition qualifies):
- Retro done, wiki not started: `currentStep == 7 AND 7 NOT IN completedSteps`
- Wiki in progress: `currentStep == 8 AND 8 NOT IN completedSteps`

Prefer tasks whose `taskName` matches: `basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)`

If multiple candidates: list them and ask user to choose.

**Lifecycle mode** (candidate task found):
1. Read `_state.json`: extract `taskName`, `history`, `artifacts.retro`
2. If `currentStep < 7`: warn "retro step not yet done" — do not block
3. Ask: "Write process notes for **<taskName>**? (y/n)"
   - `n` → stop. Show: "Skipped. Run `/dev wiki` anytime to write it later."
   - `y` → proceed

**Standalone mode** (no candidate task found): proceed directly without asking.

---

## Context

**Lifecycle mode** — from `_state.json`:
- `taskName`, `history`, `artifacts.retro` (for cross-linking)

**Standalone mode** — ask user:
- Task name
- Retro file path (optional, for cross-linking)

---

## Process

### Step 1: Process Notes

Delegate to `vault-wiki-process` skill inline:

1. Load `~/Documents/obsidian-vault/.claude/skills/vault-wiki-process/SKILL.md` via Read tool.
2. Execute with task context:
   - **task-name**: from devlog `taskName` or user input
   - **scope**: `work` (default; confirm if ambiguous)
   - **retro-path**: `artifacts.retro` or user-provided (for cross-linking)
3. vault-wiki-process saves to: `~/Documents/obsidian-vault/04_Notes/process/<scope>-YYYY-MM-DD-<task-name>-process.md`

### Step 2: Devlog Cleanup (lifecycle mode only)

After process note is saved:

1. Show contents of the task directory for review.
2. Ask (Single Choice):
   ```
   Devlog task directory: <task-dir>
   Contents: _state.json, <artifacts list>

   What to do with the devlog?
   1. Delete entirely
   2. Archive (move to _archive/)
   3. Keep as-is

   > Enter number
   ```
3. Execute the chosen action. Delete only after explicit confirmation.

4. Update `_index.md`:
   - Find the row matching the task directory in `<devlogs-root>/_index.md`
   - If deleted or archived → remove the row entirely
   - If kept → update step column to `Step 8 (wiki — done)`
   - Update frontmatter `updated:` to today's date

---

## State Update (lifecycle mode only, if not deleting)

- `currentStep` → 8, append 7 and 8 to `completedSteps`
- `artifacts.wiki` ← wiki file path
- Append to `history`: `{ "step": 7, "action": "wiki saved + devlog cleaned", "timestamp": "ISO 8601" }`

---

## Completion

```
🎉 Task complete — <taskName>

Vault artifacts:
  📄 retrospect: <retro-path>
  📄 process:    <wiki-path>

Devlog: <deleted / archived / kept>
```

Task lifecycle is now complete. No next step.
