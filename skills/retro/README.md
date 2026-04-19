# g-retro

Generate a session retrospective note and save it to the Obsidian vault.

## Features

- **Session capture** — records decisions, learnings, mistakes, and next steps
- **Smart naming** — proposes a task-name from session content; user confirms
- **Obsidian integration** — saves to `02.Wiki/retrospect/` with checkbox next steps
- **work-plan-close integration** — auto-invoked when closing a work-plan (if installed)

## Usage

```
/g-retro
```

Called manually at session end, or automatically by `g-work-plan-close`.

## How It Works

1. **Gather** — detects work-plan context or proposes task-name from session content
2. **Generate** — drafts retro note (Decisions / Learnings / Mistakes / Next Steps)
3. **Save** — writes to `~/Documents/obsidian-vault/02.Wiki/retrospect/YYYY-MM-DD-<task-name>-retrospect.md`

## Installation

```bash
ln -s /path/to/harness/skills/retro ~/.claude/skills/retro
```

Then run `setup.sh` from the harness repo to sync symlinks.

## Requirements

- Claude Code CLI
- Obsidian vault at `~/Documents/obsidian-vault/`
