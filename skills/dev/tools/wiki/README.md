# dev wiki

Capture process notes to the Obsidian vault and clean up the devlog directory. Works with or without a devlog.

## Features

- **Devlog-aware** — auto-detects post-retro tasks and pre-fills context from `_state.json`
- **Lifecycle confirmation** — asks before running when a matching devlog is found
- **Standalone mode** — works without a devlog; prompts for task name and retro path
- **vault-wiki-process delegation** — saves to `04_Notes/process/` in the Obsidian vault
- **Devlog cleanup** — offers delete / archive / keep after writing the process note

## Usage

```
/dev wiki
```

## How It Works

```
Entry Check
    │
    ├── devlog found (retro done or wiki in progress)
    │       └── Ask confirmation → yes → Step 1: Process notes
    │                                         → Step 2: Devlog cleanup
    │                            → no  → Stop (can run later)
    └── no devlog found
            └── Standalone mode → ask user for context → Step 1 only
```

### Devlog Detection

Scans for task directories matching either condition:
- Retro done, wiki not started: `currentStep == 7 AND 7 NOT IN completedSteps`
- Wiki in progress: `currentStep == 8 AND 8 NOT IN completedSteps`

Prioritizes tasks whose `taskName` matches the current repo (`git rev-parse --show-toplevel`).

### State Update (lifecycle mode)

- `currentStep` → 8, append 7 and 8 to `completedSteps`
- `artifacts.wiki` ← vault file path

## Requirements

- Obsidian vault with `vault-wiki-process` skill at `~/.claude/skills/` (or vault `.claude/skills/`)

## License

MIT
