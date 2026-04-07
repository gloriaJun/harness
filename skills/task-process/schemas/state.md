# _state.json Schema

Task state file that tracks orchestration progress. Stored in the task subdirectory.

## Schema

```json
{
  "taskName": "string — kebab-case task identifier",
  "currentStep": "number — 0-6, the step to resume from",
  "entryPoint": "idea | requirements | external-prd | design | direct",
  "completedSteps": [0, 1],
  "artifacts": {
    "brainstorm": "string | null — relative path from task dir",
    "prd": "string | null",
    "trd": "string | null",
    "features": "string | null — path to features.md",
    "featureSpecs": ["feature-01-auth.md", "feature-02-api.md"]
  },
  "features": [
    {
      "id": "01",
      "name": "string",
      "status": "pending | in-progress | review | done",
      "executor": "claude | codex | null",
      "reviewer": "claude | codex | null"
    }
  ],
  "history": [
    {
      "step": 0,
      "action": "string — what happened",
      "timestamp": "ISO 8601"
    }
  ]
}
```

## Rules

### Creation
- Created at Step 0 (Entry Point Selection) with initial values.
- `currentStep` is set to the entry point step number.
- `artifacts` fields default to `null`.

### Updates
- Update `currentStep` BEFORE loading the next step file.
- Append to `completedSteps` AFTER user confirms step completion.
- Register artifact paths in `artifacts` as soon as the file is created.
- Append to `history` at every state transition.

### Session Restoration
1. Read `_state.json` from the task directory.
2. Set `currentStep` as the active step.
3. Verify all artifact paths in `artifacts` still exist on disk.
4. If an artifact is missing, warn the user and block progression.
5. Load the step file for `currentStep` via the Read tool.

### Artifact Registry
- All paths are **relative to the task subdirectory**.
- Exception: PRD/TRD may be stored in the project's `docs/` directory.
  In this case, store the **absolute path**.
- The orchestrator resolves artifact paths from this registry,
  never from hardcoded filenames.

### Feature Tracking
- `features` array is populated at Step 4 (Breakdown).
- Each feature's `status` is updated during Step 5 (Execution).
- A feature transitions: `pending` -> `in-progress` -> `review` -> `done`.
- `executor` and `reviewer` are set when the user chooses at Step 5a.
