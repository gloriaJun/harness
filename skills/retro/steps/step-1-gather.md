# Step 1: Gather Context

Collect session context and resolve the task-name for the retrospective file.

## 1-1. Detect Invocation Mode

Check whether a work-plan folder path was passed as an argument:

- **Argument provided** → work-plan mode. Extract slug from folder name.
  - Example: `2026-04-07-one-sentry-insight` → slug = `one-sentry-insight`
  - Skip to Step 1-3.
- **No argument** → standalone mode. Proceed to Step 1-2.

## 1-2. Propose task-name (standalone mode only)

Analyze the current session to propose a concise task-name:

- Review the conversation: what was the main topic or goal?
- Check recent git log (`git log --oneline -10`) for commit subjects as signal
- Derive a short kebab-case slug (2–4 words) that captures the session theme
  - Examples: `retro-skill-setup`, `auth-bug-fix`, `onboarding-flow-review`

Present the proposal to the user:

```
Task name for this retro: <proposed-name>
OK? (press Enter to confirm, or type a new name)
```

Repeat until confirmed.

## 1-3. Collect Session Content

Gather the raw material for the retrospective:

1. **Decisions** — key design or direction decisions made this session
2. **Learnings** — new knowledge, discovered patterns, or clarified understanding
3. **Mistakes / Issues** — wrong turns, failed attempts, blockers encountered
4. **Next steps** — unfinished work, follow-up tasks, open questions

Sources to draw from:
- Current conversation context
- Git log output (recent commits as evidence of completed work)
- Work-plan documents if in work-plan mode (read key files for context)

Store the collected content for Step 2.
