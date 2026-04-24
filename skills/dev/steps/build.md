# Build: Feature Execution

Execute one feature per session.

## Session Start: Feature Selection

1. Read `_state.json` from the devlogs task subdirectory.
2. Display pending features:
   ```
   Pending features:
   [ ] feature-01-<name>
   [ ] feature-02-<name>
   ...

   Which feature would you like to work on? (enter number or name)
   ```
3. Wait for user selection.
4. Update `features[i].status` to `"in-progress"` in `_state.json`.

## Implementation

### Step A: Feature Execution

1. State which feature is being worked on.
2. Read the feature spec from `artifacts.featureSpecs[index]`.
3. Invoke the `feature-executor` agent (model: sonnet) with:
   - The feature spec content
   - PRD and TRD paths for context
4. The feature-executor asks the user to choose implementation agent (default: Codex). See agent prompt for numbered choice format.
5. Set `features[i].executor` in `_state.json`.
6. Implementation proceeds based on user choice.

### Step A-2: Simplify (Pre-Review)

Before cross-review, clean up the implementation:

1. Invoke the `simplify` skill on the changed files.
2. Wait for simplify to complete — code may be modified.
3. Proceed to cross-review with the simplified code.

### Step B: Cross-Review

After implementation, update `features[i].status` to `"review"`.

| Executor | Reviewer | Method |
|----------|----------|--------|
| Claude | Codex | Invoke `code-reviewer` agent → delegates to `/codex:review` |
| Codex | Claude | Invoke `code-reviewer` agent → reviews with Claude |

Set `features[i].reviewer` accordingly.

#### Parallel Review (frontend changes exist)

Dispatch `code-reviewer` and `frontend-reviewer` simultaneously (single message, 2 Agent tool calls).
Apply action markers per `agent-guidelines.md`. Wait for both, then aggregate findings.

#### Sequential Review (no frontend changes)

Invoke only `code-reviewer`.

### Step C: Review Resolution

1. Present review findings to the user.
2. If changes requested: fix and re-review (max 2 iterations).
3. Update `features[i].status` to `"done"`.

---

## Session Handoff

### State Update

- `features[i].status` ← `"done"`, `features[i].executor/reviewer` ← from selection
- If all features done: `currentStep` → 6, append 5 to `completedSteps`
- Append to `history`

### _index.md Update

- Find the row matching the current task directory in `<devlogs-root>/_index.md`
- If more features pending: update step column to `Step 5 (build — N/M done)`
- If all done: update step column to `Step 6 (complete)`
- Update frontmatter `updated:` to today's date

### Completion Message

```
✅ feature-<XX> complete

Remaining: N feature(s) pending

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next:  /dev build      (more features remain)
  OR
Next:  /dev complete   (all features done)
Start a new session and run `/dev` — it will detect this task automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Do NOT automatically start the next feature. Stop here.
