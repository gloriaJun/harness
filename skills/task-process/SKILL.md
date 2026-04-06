---
name: task-process
description: >
  /task-process command only. Structured task workflow with PRD,
  TRD, and feature breakdown. Manual invocation only — do NOT
  auto-trigger. Use when user explicitly calls /task-process.
---

# task-process Skill

Structured task workflow: Requirements Discovery → PRD → TRD → Feature Breakdown → Execution → Completion.

**Confirmation required at every step before proceeding.**

---

## Setup: Detect Work Directory

Before starting, resolve the work directory from the current project path:

- Path contains `GitHubWork` → work dir: `~/Documents/GitHubWork/_claude/work-plan/`
- Path contains `GitHubPrivate` → work dir: `~/Documents/GitHubPrivate/_claude/work-plan/`
- Otherwise → ask the user to confirm which work directory to use.

Read `_index.md` in the work directory at session start (if it exists) to resume any active tasks.

---

## Step 1: Requirements Discovery

Goal: Clarify the scope and intent before writing anything.

1. If the `brainstorming` skill is available, invoke it to drive requirements discovery via Socratic dialogue.
2. Otherwise, ask the following questions directly:
   - What problem does this solve, and for whom?
   - What is the expected input/output or user interaction?
   - What systems or files are involved?
   - Are there constraints (performance, compatibility, deadlines)?
   - Are there UI or design changes involved?
3. Summarize the gathered requirements and present them to the user.
4. **Confirm with user before proceeding to Step 2.**

---

## Step 2: PRD (Product Requirements Document)

Goal: Write a concise PRD capturing what to build and why.

### Location
- If the project has a `docs/` directory → save as `docs/PRD-<task-name>.md`
- Otherwise → save as `<work-dir>/PRD-<task-name>.md` (temporary, do not push)

### Contents
- Background and problem statement
- Goals and non-goals
- User stories or acceptance criteria
- Known constraints and dependencies

Present the PRD to the user.
**Confirm with user before proceeding to Step 3.**

---

## Step 3: TRD (Technical Requirements Document)

### Skip Condition
Skip this step if **both** of the following are true:
- No UI or design changes are involved
- The change is logic-only within a single system or file

If skipping, inform the user and proceed directly to Step 4.

### Location
- If the project has a `docs/` directory → save as `docs/TRD-<task-name>.md`
- Otherwise → save as `<work-dir>/TRD-<task-name>.md` (temporary, do not push)

### Contents
- Technical approach and architecture decisions
- Data models, API contracts, or interface changes
- File/module breakdown
- Testing strategy

Present the TRD to the user.
**Confirm with user before proceeding to Step 4.**

---

## Step 4: Feature Breakdown

Goal: Decompose the work into features, each completable in a single session.

**Single-session principle**: A feature is scoped so that it can be fully implemented, tested, and committed within one Claude Code session. If a feature seems too large, split it further.

1. If the `writing-plans` skill is available, invoke it to generate the feature breakdown.
2. Otherwise, produce a numbered list of features with:
   - Feature name
   - Brief description
   - Files or modules affected
   - Acceptance criteria

Update `_index.md` in the work directory with the task name, status (`in-progress`), and feature list.

Present the breakdown to the user.
**Confirm with user before proceeding to Step 5.**

---

## Step 5: Execution

Execute features one at a time, in order.

For each feature:
1. State which feature is being worked on.
2. Implement the changes.
3. Verify against acceptance criteria.
4. Update `_index.md` to mark the feature complete.
5. **Confirm with user before starting the next feature.**

---

## Step 6: Completion

When all features are done:

1. Do a final update of PRD and TRD (if they exist) to reflect any changes made during execution.
2. Update `_index.md`: mark the task as `complete`.
3. If PRD/TRD were saved in `_claude/work-plan/` (temporary), ask the user:
   - "These files were saved temporarily. Confirm to delete them, or specify if you want to keep/move them."
   - Delete only after explicit confirmation.
4. Present a summary: what was built, files changed, and any follow-up items.

---

## External Skill Integration (Wrapping Pattern)

When delegating to an external skill, pass the current task context (project path, requirements gathered so far) as input. If the skill is unavailable or returns no output, fall back to the internal logic defined in this file without interrupting the workflow.

---

## _index.md Schema

```markdown
# Claude Work Index

## Active Tasks

### <task-name>
- Status: in-progress | complete
- PRD: <path>
- TRD: <path> | skipped
- Features:
  - [ ] Feature 1
  - [x] Feature 2
```
