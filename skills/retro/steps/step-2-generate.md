# Step 2: Generate Retro Note

Draft the retrospective note using the context collected in Step 1.

## Output Format

```markdown
---
status: inbox
created: YYYY-MM-DD
updated: YYYY-MM-DD
title: [Session Retro] <task-name>
tags:
  - retro
  - <project>
summary: <one-line summary of the session>
---

# [Session Retro] <task-name>

## Decisions
- <decision 1>
- <decision 2>

## Learnings
- <learning 1>
- <learning 2>

## Mistakes / Issues
- <issue 1>
- <issue 2>

## Next Steps
- [ ] <task 1>
- [ ] <task 2>

## References
- Work plan: [[<work-plan-slug>]]
```

> Note: Include `## References` only when a work-plan folder exists. Omit entirely for standalone sessions.

## Writing Rules

- Each bullet is one concrete, specific item — no vague generalizations
- Decisions: state what was decided AND what was rejected (tradeoff captured)
- Learnings: prefer "discovered that X" or "confirmed that Y" phrasing
- Mistakes / Issues: state what happened and what to do differently next time
- Next Steps: use checkbox format `- [ ]` so Obsidian renders them as tasks
- Omit any section that has zero content rather than writing "N/A"

## Review Before Saving

Show the drafted note to the user before proceeding to Step 3.
Ask: "Ready to save? (y/n/edit)"
- `y` → proceed to Step 3
- `n` → discard
- `edit` → user provides corrections, regenerate
