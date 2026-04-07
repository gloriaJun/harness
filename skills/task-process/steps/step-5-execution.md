# Step 5: Feature Execution (per feature loop)

Execute features one at a time, in order.

## Loop: For Each Feature in `_state.json.features` where `status != "done"`

### 5a. Implementation

1. State which feature is being worked on.
2. Read the feature spec from `artifacts.featureSpecs[index]`.
3. Invoke the `feature-executor` agent with:
   - The feature spec content
   - PRD and TRD paths for context
4. The feature-executor asks the user: **Claude or Codex** for implementation.
5. Update `features[i].status` to `"in-progress"` and set `executor`.
6. Implementation proceeds based on user choice.

### 5b. Cross-Review

After implementation, update `features[i].status` to `"review"`:

| Executor | Reviewer | Method |
|----------|----------|--------|
| Claude | Codex | Invoke `code-reviewer` agent -> delegates to `/codex:review` |
| Codex | Claude | Invoke `code-reviewer` agent -> reviews with Claude |

Set `features[i].reviewer` accordingly.

If the feature involves frontend changes:
- Additionally invoke `frontend-reviewer` agent.

### 5c. Review Resolution

1. Present review findings to the user.
2. If changes requested: fix and re-review (max 2 iterations).
3. Update `features[i].status` to `"done"`.
4. Log to `history`.

**Confirm with user before starting the next feature.**

## Loop Exit

When all features have `status: "done"`:
1. Set `currentStep` to `6`
2. Append `5` to `completedSteps`
