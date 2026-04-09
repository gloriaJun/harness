# g-insight

Reviews completed work and suggests improvements to instructions, new skill candidates, config sharing opportunities, and agent prompt enhancements. Also invoked automatically from `g-task-process` Step 6.

## Features

- **7 Analysis Categories** — Instruction candidates, skill candidates, config sharing, agent improvements, agent candidates, token efficiency, and memory updates
- **Quality Gate** — Only surfaces meaningful insights; outputs "No suggestions" when nothing actionable is found
- **3-Way User Decision** — Each suggestion can be Applied (immediate), Deferred (saved to MEMORY.md), or Skipped
- **Context-Aware** — When called from `g-task-process`, also analyzes `_state.json`, PRD, TRD, and feature breakdown artifacts
- **No Subagents** — Runs entirely in the main context window to access the full conversation history

## Usage

```
/g-insight
```

Also invoked automatically after `g-task-process` completion (Step 6).

## How It Works

```
/g-insight (or auto-invoked from g-task-process)
  → 1. Collect context (conversation history, artifacts)
  → 2. Pattern analysis across 7 categories
  → 3. Generate insights (skip if nothing meaningful)
  → 4. Present recommendations
  → 5. User decision per insight:
       ├── Apply — execute immediately
       ├── Defer — save to MEMORY.md for later
       └── Skip — discard
```

### Analysis Categories

| Category | What it looks for |
|----------|-------------------|
| Instruction candidates | Patterns worth adding to CLAUDE.md |
| Skill candidates | Repeated workflows that could become skills |
| Config sharing | Settings reusable across projects |
| Agent improvements | Prompt refinements for existing agents |
| Agent candidates | New agent opportunities |
| Token efficiency | Ways to reduce context token usage |
| Memory updates | Outdated or missing entries in MEMORY.md |

## Requirements

- Claude Code CLI

## License

MIT
