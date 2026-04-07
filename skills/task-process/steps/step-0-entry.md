# Step 0: Entry Point Selection

Ask the user to select their starting point:

| Choice | What you have | Starts at |
|--------|--------------|-----------|
| "I have an idea" | Vague concept | Step 1 (idea-explorer) |
| "I want to define requirements" | Rough requirements | Step 2 (requirements-analyst) |
| "I have a PRD / planning doc" | External PRD | Step 3 (system-architect) |
| "Design is done" | PRD + TRD | Step 4 (feature breakdown) |
| "Just implement" | Clear scope | Step 5 (feature-executor) |

## External Document Handling

If the user has an external document (planning doc, PRD, etc.):
- Ask for the file path
- Copy or link it into the task subdirectory
- Register it in `_state.json` artifacts
- Use it as input for the appropriate agent

## State Update

After user confirms selection:
1. Set `entryPoint` in `_state.json`
2. Set `currentStep` to the selected step number
3. Append to `completedSteps`: `[0]`
4. Log to `history`

**Confirm selection with user before proceeding.**
