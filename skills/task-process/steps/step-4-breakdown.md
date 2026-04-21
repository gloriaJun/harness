# Step 4: Feature Breakdown

Goal: Decompose work into features, each completable in a single session.

## Single-Session Principle

A feature is scoped so it can be fully implemented, tested, and committed within one Claude Code session. If a feature seems too large, split it further.

## Input

From `_state.json` artifacts:
- `artifacts.prd` (required)
- `artifacts.trd` (optional, may be `"skipped"`)

## Process

1. Based on PRD + TRD, produce a numbered feature list:
   - Feature name
   - Brief description
   - Files or modules affected
   - Acceptance criteria (from PRD)
2. Write `features.md` in the task subdirectory.
3. Write individual `feature-XX-<name>.md` files with detailed specs.
4. Register paths in `_state.json`:
   - `artifacts.features` = `"features.md"`
   - `artifacts.featureSpecs` = array of spec filenames
   - `features` = array of feature objects with `status: "pending"`
5. Ask review mode (required): Plannotator visual (default) / inline text / skip.

## Review (2-layer)

1. **Plannotator + User approval**:
   - If mode is Plannotator, check `plannotator` command availability first.
   - If available, run Plannotator review on the feature breakdown.
   - If unavailable or launch fails, show a visible warning and ask confirmation:
     - `[WARN] Plannotator CLI is unavailable. Switching to inline text review.`
     - `Continue with inline text review? (Y/n)`
   - If user says no: stay in this step and let the user choose retry/skip.
   - If user says yes (or default): fall back to inline text review.
   - If mode is inline text, present as text.
   - If mode is skip, proceed without Plannotator/text review.
   - If revision requested: adjust breakdown, do NOT advance step.
2. **Codex cross-review**: After user approval, request Codex review.
   - Focus: missing features, incorrect scoping (too large/small for single session), dependency ordering issues.
   - Via codex-plugin-cc: `/codex:rescue "Review this feature breakdown for missing items, scoping issues, and dependency order: <path>"`
   - Via Codex CLI: `codex task --effort low --read <features-path> "Review this feature breakdown: identify missing features, items too large for a single session, and dependency ordering issues"`
   - If Codex is not available (Bash restricted or CLI missing):
     - Invoke `code-reviewer` agent (model: sonnet) for cross-review instead.
     - Note the fallback in `_state.json` history.
3. Present Codex review results -> user decides whether to incorporate.

## State Update

After user confirms:
1. Set `currentStep` to `5`
2. Append `4` to `completedSteps`
3. Verify `artifacts.features` and `features` array are set
4. Record review metadata in `_state.json.reviews.features`:
   - `mode`: `plannotator | text | skipped`
   - `fallbackReason`: `plannotator_cli_unavailable | plannotator_launch_failed | null`
   - `approvedAt`: ISO 8601
5. Log to `history`

**Confirm with user before proceeding to Step 5.**
