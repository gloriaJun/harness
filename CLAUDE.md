# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Harness is a personal AI coding assistant configuration hub — the single source of truth for Claude Code and Codex CLI settings. It manages instruction files, hooks, and skills via symlinks from `$HOME` config directories.

There is no build system, no package manager, and no test runner. The repo contains Markdown specifications, prompt templates, shell scripts, and static HTML/CSS/JS.

## Repository Structure

```
claude/          # Custom instruction files (CLAUDE.md, instructions/)
                 # instructions/references/ for on-demand guidelines
                 # Symlinked to ~/.claude/
hooks/           # Hook scripts, symlinked to ~/.claude/hooks/
agents/          # Custom agent definitions, symlinked to ~/.claude/agents/
  idea-explorer.md          # Idea exploration via strategic questioning
  requirements-analyst.md   # Requirements analysis -> PRD
  system-architect.md       # Architecture design -> TRD
  feature-executor.md       # Feature implementation (Claude/Codex selection)
  code-reviewer.md          # Cross-agent code review (Claude<->Codex)
  frontend-reviewer.md      # Frontend-specific review (a11y, responsive)
codex/           # Codex CLI settings
  rules/         # Shell command approval rules, symlinked to ~/.codex/rules/
skills/          # Claude Code skills, symlinked to ~/.claude/skills/
  my-claude-audit/
  task-process/  # Orchestrator: ideation -> design -> implementation
  sync-config/   # Link shared config to project .claude/
  cleanup/       # Diagnose and clean up sessions, logs, caches
  troubleshoot/  # Unified troubleshooting: error analysis, debug, performance
  pre-commit-check/  # Auto self-review before commit
  work-plan-close/   # Close completed work-plan: archive docs, delete artifacts, update _index.md
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

### Authoring Convention

For skill authoring rules (orchestrator pattern, mermaid diagrams, script extraction),
see `claude/instructions/references/skill-authoring.md`.

### Subagent Pattern (for my-claude-audit)

1. **Prompt files** in `analyzer-prompts/` define each subagent's task
2. Prompts are loaded via the **Read tool** (never `@`-import)
3. Subagents are dispatched via the **Agent tool** with `subagent_type: Explore`
4. Subagents return **JSON only** — no prose, no markdown
5. Results are combined and injected into an HTML template via `{{PLACEHOLDER}}` replacement

## Agent Anatomy

Each agent lives in `agents/<name>.md` with YAML frontmatter:

```yaml
---
name: agent-name
description: >
  When to use this agent. Claude matches tasks to agents by description.
model: sonnet
---
```

Agents run in isolated context windows. They do NOT inherit the parent's context, so all necessary information must be included in each agent's `.md` file or passed via the Agent tool prompt.

## Key Conventions

- **No hardcoded paths.** Discover paths from `~/.claude/settings.json` at runtime.
- **Read prompt files, don't @-import them.** Use the Read tool to get content, then pass it in the Agent prompt.
- **Token estimation:** `chars / 4`. Context window assumed at 200,000 tokens.
- **HTML reports** are written to `/tmp/` and opened in the browser. Do not delete them.
- **No secrets in repo.** `settings.json` and `config.toml` stay local. Templates in `templates/` for reference.

## Post-Task Workflow

When a task is completed in this repository, always ask the user whether to:
1. Commit and push the changes
2. Verify `$HOME` symlinks reflect the latest state (run `setup.sh` if needed)
