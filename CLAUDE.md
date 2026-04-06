# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Harness is a personal AI coding assistant configuration hub — the single source of truth for Claude Code and Codex CLI settings. It manages instruction files, hooks, and skills via symlinks from `$HOME` config directories.

There is no build system, no package manager, and no test runner. The repo contains Markdown specifications, prompt templates, shell scripts, and static HTML/CSS/JS.

## Repository Structure

```
claude/          # Custom instruction files (CLAUDE.md, instructions/)
                 # Symlinked to ~/.claude/
hooks/           # Hook scripts, symlinked to ~/.claude/hooks/
codex/           # Codex CLI settings
  rules/         # Shell command approval rules, symlinked to ~/.codex/rules/
skills/          # Claude Code skills, symlinked to ~/.claude/skills/
  my-claude-audit/
  task-process/  # Structured task workflow (PRD/TRD/features)
  sync-config/   # Link shared config to project .claude/
templates/       # Settings templates (no secrets, reference only)
plugins.json     # Plugin marketplace manifest (reference only)
setup.sh         # Symlink setup script
```

## Key Files

- **`claude/CLAUDE.md`** — Entry point instruction file, symlinked to `~/.claude/CLAUDE.md`.
- **`setup.sh`** — Creates symlinks, generates `~/.codex/AGENTS.md`, shows plugin info. Run with `--dry-run` to preview.
- **`plugins.json`** — Tracks which plugin marketplaces and plugins to install. Not auto-applied; reference for manual setup.

## Skill Anatomy

Each skill lives in `skills/<skill-name>/` and must have a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: >
  Trigger description. First line determines when Claude activates the skill.
---
```

### Subagent Pattern

1. **Prompt files** in `analyzer-prompts/` define each subagent's task
2. Prompts are loaded via the **Read tool** (never `@`-import)
3. Subagents are dispatched via the **Agent tool** with `subagent_type: Explore`
4. Subagents return **JSON only** — no prose, no markdown
5. Results are combined and injected into an HTML template via `{{PLACEHOLDER}}` replacement

## Key Conventions

- **No hardcoded paths.** Discover paths from `~/.claude/settings.json` at runtime.
- **Read prompt files, don't @-import them.** Use the Read tool to get content, then pass it in the Agent prompt.
- **Token estimation:** `chars / 4`. Context window assumed at 200,000 tokens.
- **HTML reports** are written to `/tmp/` and opened in the browser. Do not delete them.
- **No secrets in repo.** `settings.json` and `config.toml` stay local. Templates in `templates/` for reference.
