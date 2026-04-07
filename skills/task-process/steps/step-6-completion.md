# Step 6: Completion

When all features are done.

## Process

1. Final update of PRD and TRD to reflect any changes made during execution.
2. Update `_state.json`:
   - Set `currentStep` to `6`
   - Append `6` to `completedSteps`
3. If documents were saved in the task subdirectory (temporary):
   - Ask: "These files were saved temporarily. Delete, keep, or move?"
   - Delete only after explicit confirmation.
4. Present summary:
   - What was built
   - Files changed
   - Follow-up items
5. Clean up `_state.json`: optionally archive or delete based on user preference.
