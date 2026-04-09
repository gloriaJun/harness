# g-cleanup

Diagnose and clean up old Claude Code sessions, Codex CLI sessions, logs, caches, and temporary files. Always performs a dry-run preview before any destructive action.

## Features

- **Disk Usage Diagnosis** — Scans Claude Code and Codex CLI directories for space consumption
- **Mandatory Dry Run** — Always shows a preview of what will be deleted before execution; never skippable
- **Protected Paths** — Enforces a protected-paths list; `projects/*/memory/` is never deleted
- **Smart Truncation** — `history.jsonl` files are truncated rather than deleted to preserve recent history
- **Worktree Safety** — Checks each worktree individually for uncommitted changes before cleanup
- **Flexible Mode Selection** — Choose full cleanup, category-specific cleanup, or cancel

## Usage

```
/g-cleanup
```

## How It Works

```
/g-cleanup
  → Step 1: Diagnose disk usage across all targets
  → Step 2: Select mode (full / category / cancel)
  → Step 3: Set retention period (default: 30 days)
  → Step 4: Dry-run preview (mandatory)
  → User confirms
  → Step 5: Execute cleanup
```

### Cleanup Targets

| Category | What gets cleaned |
|----------|-------------------|
| Sessions | Old Claude Code session data |
| Codex CLI | Codex CLI session artifacts |
| Logs | Log files beyond retention period |
| Caches | Temporary caches and build artifacts |
| Worktrees | Abandoned git worktrees (with uncommitted change check) |

## Requirements

- Claude Code CLI

## License

MIT
