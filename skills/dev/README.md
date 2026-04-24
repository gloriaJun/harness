# dev

Unified development workflow skill — single entry point for the full lifecycle from ideation to documentation.

## Features

- **Planning lifecycle** — idea → plan → design → breakdown → build → complete (devlog-tracked, cross-session)
- **Utility tools** — test, refactor, troubleshoot, review, retro, wiki (devlog optional)
- **State persistence** — `_state.json` in devlogs enables seamless session resumption
- **Cross-agent review** — Plannotator + Codex + frontend-reviewer across all planning artifacts
- **Natural language routing** — refactoring and debugging requests auto-routed without `/dev` prefix
- **insight integration** — post-completion grimoire improvement suggestions via isolated agent

## Usage

```
/dev                    # active devlog check → resume or entry menu
/dev idea               # ideation → brainstorm.md
/dev plan               # requirements → PRD
/dev design             # PRD → TRD
/dev breakdown          # TRD → feature breakdown
/dev build              # implement one feature
/dev complete           # wrap-up + summary
/dev retro              # retrospective → vault note
/dev wiki               # process notes → vault + devlog cleanup
/dev review             # code review (PR URL or local diff)
/dev test               # test code generation
/dev refactor           # code restructuring
/dev troubleshoot       # debug errors and stack traces
/dev status             # show all devlog task statuses
/dev help               # show this command list
```

## How It Works

```
/dev [sub-command]
    │
    ├── no sub-command → Active devlog check → resume or entry menu
    ├── planning sub-command → steps/<name>.md (devlog-tracked)
    └── utility sub-command → tools/<name>/SKILL.md (devlog optional)
```

### Planning Lifecycle

| Step | Sub-command | Agent | Output |
|------|-------------|-------|--------|
| 1 | `idea` | idea-explorer | brainstorm.md |
| 2 | `plan` | requirements-analyst | PRD |
| 3 | `design` | system-architect | TRD |
| 4 | `breakdown` | (inline) | features.md + feature specs |
| 5 | `build` | feature-executor | implemented feature |
| 6 | `complete` | — | wrap-up + insight |

Steps 2–4 use shared Plannotator + Codex review protocol (`references/review-protocol.md`).

### Devlog

State file (`_state.json`) lives at `<workspace>/_claude/devlogs/<YYYY-MM-DD-repo-task>/`.

| Workspace | Devlogs root |
|-----------|-------------|
| GitHubWork | `~/Documents/GitHubWork/_claude/devlogs/` |
| GitHubPrivate | `~/Documents/GitHubPrivate/_claude/devlogs/` |

### External Dependencies

| Tool | Purpose |
|------|---------|
| Plannotator | Visual review of PRD / TRD / feature breakdown |
| codex-plugin-cc / Codex CLI | Cross-review of artifacts and code |
| vault-retro | Retrospective note to Obsidian vault |
| vault-wiki-process | Process notes to Obsidian vault |

## Installation

```bash
ln -s /path/to/grimoire/skills/dev ~/.claude/skills/dev
```

Or run `setup.sh` from the grimoire repo root.

## License

MIT
