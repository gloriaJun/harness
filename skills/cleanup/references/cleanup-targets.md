# Cleanup Targets

## Claude Code (`~/.claude/`)

| ID | Category | Path | Description |
|----|----------|------|-------------|
| C1 | Sessions | `sessions/`, `session-env/` | Session metadata |
| C2 | Transcripts | `transcripts/` | Session transcripts |
| C3 | Project sessions | `projects/*/[uuid].jsonl` | Per-project conversation logs (preserve `memory/` dirs) |
| C4 | Backups | `backups/` | File backups |
| C5 | Cache | `cache/`, `paste-cache/` | Cache data |
| C6 | Logs | `logs/`, `debug/` | Debug and error logs |
| C7 | History | `history.jsonl` | Command history |
| C8 | File history | `file-history/` | File change history |
| C9 | Shell snapshots | `shell-snapshots/` | Shell state snapshots |
| C10 | Todos/Plans | `todos/`, `plans/`, `tasks/` | Task and plan data |
| C11 | Stats | `usage-data/`, `statsig/` | Usage statistics and analytics |

## Codex CLI (`~/.codex/`)

| ID | Category | Path | Description |
|----|----------|------|-------------|
| X1 | Worktrees | `worktrees/` | Git worktrees (often the largest) |
| X2 | Sessions | `sessions/`, `archived_sessions/` | Active and archived sessions |
| X3 | Temp files | `.tmp/`, `tmp/` | Temporary files |
| X4 | Logs | `log/` | TUI logs |
| X5 | Shell snapshots | `shell_snapshots/` | Shell state snapshots |
| X6 | Database | `sqlite/` | SQLite data |

## Memory (`~/.claude/projects/*/memory/`)

| ID | Category | Path | Description |
|----|----------|------|-------------|
| M1 | Memory audit | `projects/*/memory/` | Auto-memory files — audit for orphaned project paths, broken MEMORY.md indexes, and duplicate entries across old/renamed project dirs. Does NOT delete content blindly; presents issues for user confirmation. |

## Temp files (`/tmp/`)

| ID | Category | Pattern | Description |
|----|----------|---------|-------------|
| T1 | Reports | `my-claude-audit-*.html` | Audit skill HTML reports |
| T2 | Claude temp | `claude-*` | Claude Code temp files |
