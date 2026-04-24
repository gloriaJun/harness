# Session Handoff

Follow these steps at the end of idea, plan, design, and breakdown.
Build and complete handle their own handoff inline.

## 1. Persist State

Update `_state.json` per the values declared in the step file's "State Update" section.
Follow `schemas/state.md` update mechanics.

## 2. Update `_index.md`

- Read `<devlogs-root>/_index.md`
- Find the row matching the current task directory name
- Update the "current step" column to `Step N (<next-step-name>)`
- Update frontmatter `updated:` to today's date
- If the row is not found: append a new row as fallback

Step name mapping:

| currentStep (next) | step-name |
|--------------------|-----------|
| 1 | idea |
| 2 | plan |
| 3 | design |
| 4 | breakdown |
| 5 | build |
| 6 | complete |
| 7 | retro |
| 8 | wiki |

## 3. Show Completion Message

The next sub-command is declared in the step file's "Next sub-command:" line.

```
✅ [<sub-command>] complete — <artifact(s)> saved

📁 <path to saved artifact(s)>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next:  /dev <next-sub-command>
Start a new session and run `/dev` — it will detect this task and resume automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 4. Do Not Continue

After showing the handoff message, stop. Do not proceed to the next step in the same session unless the user explicitly asks.
