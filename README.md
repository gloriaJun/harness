# Harness

Personal AI coding assistant configuration hub — single source of truth for Claude Code and Codex CLI settings.

## What This Repo Manages

| Directory | Purpose | Target |
|-----------|---------|--------|
| `claude/` | Custom instruction files (PRINCIPLES, RULES, FLAGS) | `~/.claude/*.md` (symlink) |
| `hooks/` | Hook scripts | `~/.claude/hooks/` (symlink) |
| `codex/rules/` | Codex shell approval rules | `~/.codex/rules/` (symlink) |
| `skills/` | Claude Code skills | `~/.claude/skills/` (symlink) |
| `templates/` | Settings templates (no secrets) | Reference only |
| `plugins.json` | Plugin manifest | Reference only |

Codex CLI's `AGENTS.md` is auto-generated from `claude/PRINCIPLES.md` + `claude/RULES.md` + `claude/FLAGS.md`.

## Setup

```bash
# Preview changes (no modifications)
./setup.sh --dry-run

# Apply symlinks + generate AGENTS.md + show plugin info
./setup.sh

# Regenerate ~/.codex/AGENTS.md only
./setup.sh --regenerate
```

The setup script:
1. Creates symlinks from `$HOME` config dirs to this repo
2. Backs up existing files before replacing (`.backup.YYYYMMDD_HHMMSS`)
3. Generates `~/.codex/AGENTS.md` from shared instruction files
4. Displays plugin manifest for manual configuration

## Skills

| Skill | Description |
|-------|-------------|
| [my-claude-audit](./skills/my-claude-audit/) | Comprehensive Claude Code configuration audit with interactive HTML dashboard |

## Plugins

Plugins are managed by their respective marketplaces, not version-controlled here.
See `plugins.json` for the list of tracked marketplaces and enabled plugins.
