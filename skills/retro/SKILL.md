---
name: g-retro
description: >
  /g-retro command only. Generate a session retrospective note capturing
  decisions, learnings, mistakes, and next steps. Can be invoked manually
  at session end, or called by g-work-plan-close when installed.
  Manual invocation only — do NOT auto-trigger.
---

# g-retro Skill

Generate a session retrospective and save it to the Obsidian vault.

## Vault Path

```
retrospect: ~/Documents/obsidian-vault/02.Wiki/retrospect/
filename:   YYYY-MM-DD-<task-name>-retrospect.md
```

## Workflow

```mermaid
flowchart TD
    A(["/g-retro"]) --> B["Step 1: Gather Context"]
    B --> C{"work-plan context\nprovided?"}
    C -- Yes --> D["Use work-plan slug\nas task-name"]
    C -- No --> E["Propose task-name\nfrom session content"]
    E --> F{"User confirms\ntask-name?"}
    F -- Edit --> E
    F -- Confirmed --> G["Step 2: Generate Retro Note"]
    D --> G
    G --> H["Step 3: Save to Vault"]
    H --> I(["Done"])
```

## Step Router

Read ONLY the step file for the current step.

| Step | File | Description |
|------|------|-------------|
| 1 | `steps/step-1-gather.md` | Collect session context and resolve task-name |
| 2 | `steps/step-2-generate.md` | Draft the retrospective note |
| 3 | `steps/step-3-save.md` | Save to Obsidian vault |

## Invocation Modes

| Mode | Trigger | task-name source |
|------|---------|-----------------|
| Manual | `/g-retro` | Proposed from session content → user confirms |
| From work-plan-close | Called with work-plan folder path as argument | Work-plan folder slug (auto) |
