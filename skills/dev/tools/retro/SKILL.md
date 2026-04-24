# Retro — Session Retrospective

Capture a retrospective note for a completed task and save it to the Obsidian vault.
Works with or without a devlog.

---

## Entry Check

**Resolve devlogs root** from cwd:

| cwd contains | devlogs root |
|---|---|
| `GitHubWork` | `~/Documents/GitHubWork/_claude/devlogs/` |
| `GitHubPrivate` | `~/Documents/GitHubPrivate/_claude/devlogs/` |
| neither | ask the user |

**Scan for candidate tasks** (either condition qualifies):
- Post-complete, retro not started: `currentStep == 6 AND 6 IN completedSteps`
- Retro in progress: `currentStep == 7 AND 7 NOT IN completedSteps`

Prefer tasks whose `taskName` matches: `basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)`

If multiple candidates: list them and ask user to choose.

**Lifecycle mode** (candidate task found):
1. Read `_state.json`: extract `taskName`, `history`, `artifacts`
2. If `currentStep < 6`: warn "complete step not yet done" — do not block
3. Ask: "Write a retrospective for **<taskName>**? (y/n)"
   - `n` → stop. Show: "Skipped. Run `/dev retro` anytime to write it later."
   - `y` → proceed

**Standalone mode** (no candidate task found): proceed directly without asking.

---

## Context

**Lifecycle mode** — from `_state.json`:
- `taskName`, `history` entries, `artifacts` list

**Standalone mode** — ask user:
- Task name
- Brief description of what was accomplished

---

## Execute

Delegate to `vault-retro` skill inline:

1. Load `~/Documents/obsidian-vault/.claude/skills/vault-retro/SKILL.md` via Read tool.
2. Execute with task context:
   - **task-name**: from devlog `taskName` or user input
   - **scope**: `work` (default; confirm if ambiguous)
   - **context**: summarize from `history` + artifacts (lifecycle) or user description (standalone)
3. vault-retro saves to: `~/Documents/obsidian-vault/04_Notes/retrospect/<scope>-YYYY-MM-DD-<task-name>-retrospect.md`

---

## State Update (lifecycle mode only)

1. Update `_state.json`:
   - `currentStep` → 7, append 6 to `completedSteps`
   - `artifacts.retro` ← retro file path
   - Append to `history`: `{ "step": 6, "action": "retro saved", "timestamp": "ISO 8601" }`

2. Update `_index.md`:
   - Find the row matching the task directory in `<devlogs-root>/_index.md`
   - Update step column to `Step 7 (retro)`
   - Update frontmatter `updated:` to today's date

---

## Completion

```
✅ [retro] complete — retrospect note saved

📄 <retro-path>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next:  /dev wiki
Start a new session and run `/dev wiki` — it will detect this task and resume.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
