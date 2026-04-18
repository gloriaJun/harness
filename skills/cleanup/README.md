# g-cleanup

Diagnose and clean up old Claude Code sessions, Codex CLI sessions, logs, caches, and temporary files. Always performs a dry-run preview before any destructive action.

## Features

- **Disk Usage Diagnosis** — Scans Claude Code and Codex CLI directories for space consumption
- **Memory Audit** — Detects orphaned project paths, broken MEMORY.md indexes, and duplicate entries from renamed directories
- **Mandatory Dry Run** — Always shows a preview of what will be deleted before execution; never skippable
- **Protected Paths** — Enforces a protected-paths list; `projects/*/memory/` content is never deleted blindly
- **Smart Truncation** — `history.jsonl` is truncated (not deleted) via script that handles Unix ms timestamp format
- **Empty Dir Cleanup** — After C3 session deletion, removes empty project dirs (memory-less only)
- **Worktree Safety** — Checks each worktree individually for uncommitted changes before cleanup
- **Flexible Mode Selection** — Choose full cleanup, category-specific cleanup, or cancel

## Usage

```
/g-cleanup
```

## How It Works

```
/g-cleanup
  → Step 1: Diagnose disk usage + memory audit (scripts/audit-memory.sh)
  → Step 2: Select mode (full / category / cancel)
  → Step 3: Set retention period (default: 30 days)
  → Step 4: Dry-run preview (mandatory)
  → User confirms
  → Step 5: Execute cleanup
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/audit-memory.sh` | Scan `projects/*/memory/` for orphaned paths, broken indexes, duplicates |
| `scripts/truncate-history.sh <days>` | Truncate `history.jsonl` keeping last N days (handles Unix ms timestamps) |

### Cleanup Targets

| ID | Category | What gets cleaned |
|----|----------|-------------------|
| C1-C2 | Sessions / Transcripts | Old Claude Code session metadata and transcripts |
| C3 | Project sessions | Per-project `.jsonl` logs + empty dirs after cleanup |
| C4 | Backups | `.claude.json` backup files |
| C5-C6 | Cache / Logs | Temporary caches and debug logs |
| C7 | History | `history.jsonl` — truncated, not deleted |
| C8-C9 | File history / Shell snapshots | File edit history and shell state snapshots |
| C10-C11 | Todos / Stats | Task/plan data and usage statistics |
| M1 | Memory audit | Orphaned/broken/duplicate memory entries |
| X1-X6 | Codex CLI | Worktrees, sessions, temp files, logs, snapshots, DB |
| T1-T2 | /tmp | Audit HTML reports and Claude temp files |

## Requirements

- Claude Code CLI

## License

MIT
