# dev retro

Capture a session retrospective note to the Obsidian vault. Works with or without a devlog.

## Features

- **Devlog-aware** — auto-detects post-complete tasks and pre-fills context from `_state.json`
- **Lifecycle confirmation** — asks before running when a matching devlog is found
- **Standalone mode** — works without a devlog; prompts for task name and description
- **vault-retro delegation** — saves to `04_Notes/retrospect/` in the Obsidian vault

## Usage

```
/dev retro
```

## How It Works

```
Entry Check
    │
    ├── devlog found (post-complete or retro in progress)
    │       └── Ask confirmation → yes → Execute with _state.json context
    │                            → no  → Stop (can run later)
    └── no devlog found
            └── Standalone mode → ask user for context → Execute
```

### Devlog Detection

Scans for task directories matching either condition:
- Post-complete: `currentStep == 6 AND 6 IN completedSteps`
- Retro in progress: `currentStep == 7 AND 7 NOT IN completedSteps`

Prioritizes tasks whose `taskName` matches the current repo (`git rev-parse --show-toplevel`).

### State Update (lifecycle mode)

- `currentStep` → 7, append 6 to `completedSteps`
- `artifacts.retro` ← vault file path

## Requirements

- Obsidian vault with `vault-retro` skill at `~/.claude/skills/` (or vault `.claude/skills/`)

## License

MIT
