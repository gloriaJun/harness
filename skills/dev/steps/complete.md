# Complete: Task Wrap-up

When all features are done.

## Process

1. Final update of PRD and TRD to reflect any changes made during execution.
2. If documents were saved in the task subdirectory (temporary):
   - Ask (follow Single Choice pattern):
     ```
     Temporary files found in the task subdirectory.

     What to do with them?
     1. Delete
     2. Keep
     3. Move to another location

     > Enter number or free text
     ```
   - Delete only after explicit confirmation.
3. Present summary:
   - What was built
   - Files changed
   - Follow-up items
4. Run **insight**: Load and execute `~/.claude/skills/insight/SKILL.md` inline (in main context).
   This reviews the entire task workflow and suggests grimoire improvements.

---

## Session Handoff

### State Update

`currentStep` → 6, append 6 to `completedSteps`. Append to `history`.

Follow update mechanics from `schemas/state.md`.

### _index.md Update

- Find the row matching the current task directory in `<devlogs-root>/_index.md`
- Update step column to `Step 6 (complete)`
- Update frontmatter `updated:` to today's date

### Completion Message

```
✅ [complete] done — task wrap-up finished

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Optional next steps:
  /dev retro  — session retrospective
  /dev wiki   — process notes + devlog cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
