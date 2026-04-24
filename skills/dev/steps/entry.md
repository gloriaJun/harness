# Entry: Starting Point Selection

## Active Task Check

Before showing the entry menu, check for an existing task:

1. Detect workspace from `cwd`:
   - Path contains `GitHubWork` → `~/Documents/GitHubWork/_claude/devlogs/`
   - Path contains `GitHubPrivate` → `~/Documents/GitHubPrivate/_claude/devlogs/`
   - Neither → ask the user which workspace to use

2. Scan for directories containing `_state.json` under the devlogs path.
   - Filter for entries where `currentStep` is NOT in `completedSteps` (step pending = active)
   - Step mapping: 6=complete, 7=retro, 8=wiki — tasks at any of these steps are still active
   - Prioritize entries whose `taskName` matches the current repo name

3. If incomplete tasks found:
   ```
   Active devlogs found:

     1. 2026-04-19-one-theme-restructure  (step 3: design)
     2. 2026-04-07-one-sentry-insight     (step 5: build — 2/4 features done)

   Resume one, or start a new task?
   > [number] to resume / [n] for new task
   ```
   - Resume: load `_state.json`, verify artifact paths, load the step file for `currentStep`
   - New task: continue to entry menu below

4. If no incomplete tasks: proceed directly to the entry menu.

---

## Entry Menu

```
Select your starting point:

  1. idea      — vague concept, start from ideation
  2. plan      — requirements ready, skip to PRD
  3. design    — PRD exists, go to TRD
  4. build     — planning done, go straight to implementation
  5. resume    — continue an existing task by path

> Enter number or sub-command name
```

| Choice | Starts at | Pre-condition |
|--------|-----------|---------------|
| idea   | `steps/idea.md` | none |
| plan   | `steps/plan.md` | none (creates new devlog) |
| design | `steps/design.md` | PRD exists |
| build  | `steps/build.md` | feature breakdown exists |
| resume | prompts for devlog path | `_state.json` exists |

## New Task Initialization

After entry point is confirmed:

1. Ask for task name (kebab-case, e.g., `one-auth-refactor`)
2. Create task directory: `<devlogs-root>/YYYY-MM-DD-<repo>-<task-name>/`
3. Create `_state.json` with:
   - `taskName`: confirmed name
   - `currentStep`: entry point step number
   - `entryPoint`: selected entry
   - `completedSteps`: `[0]`
   - All other fields at defaults
4. Update `_index.md`:
   - Read `<devlogs-root>/_index.md`
   - Append row under `## Active Tasks` table:
     `` | `YYYY-MM-DD-<repo>-<task-name>/` | <task-name> | Step N (<step-name>) | 진행 중 | ``
   - Update frontmatter `updated:` to today's date
5. Load the step file for the selected entry point

## External Document Handling

If the user has an existing PRD, TRD, or planning doc:
- Ask for the file path
- Copy it into the task directory and register in `_state.json` artifacts
- Use it as input for the appropriate step
