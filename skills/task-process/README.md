# g-task-process

Structured task workflow from ideation to completion. Orchestrates specialized agents with cross-review via Codex, supporting multiple entry points for different starting contexts.

## Features

- **5 Entry Points** — Start from idea, requirements, external PRD, existing design, or direct implementation
- **Agent Orchestration** — Dispatches idea-explorer, requirements-analyst, system-architect, feature-executor, and code-reviewer agents across workflow stages
- **3-Layer Cross Review** — Each document (PRD, TRD, Feature Breakdown) goes through Plannotator visual review, user review, and Codex cross-validation
- **Code Cross Review** — Claude implementations reviewed by Codex; Codex implementations reviewed by Claude's code-reviewer agent
- **Session Restore** — Persists progress in `_state.json` for resuming interrupted workflows
- **Lazy Step Loading** — Each step loaded on demand from `steps/` to minimize token usage
- **Post-Completion Insight** — Automatically invokes `/g-insight` after task completion

## Usage

```
/g-task-process
```

Select an entry point when prompted:
1. **Idea** — Start with a rough idea for brainstorming
2. **Requirements** — Start with requirements to define
3. **External PRD** — Import an existing PRD document
4. **Design ready** — Skip to architecture with existing requirements
5. **Direct implementation** — Jump straight to coding

## How It Works

```
/g-task-process
  → Step 0: Entry Point Selection
  → Step 1: Ideation (idea-explorer agent)
  → Step 2: Requirements / PRD (requirements-analyst agent)
  → Step 3: Design / TRD (system-architect agent)
  → Step 4: Feature Breakdown
  → Step 5: Execution Loop (feature-executor + cross-review)
  → Step 6: Completion → /g-insight
```

Each document produced (PRD, TRD, Feature Breakdown) goes through a 3-layer review:

| Layer | Reviewer | Purpose |
|-------|----------|---------|
| Plannotator | Visual plugin | Structural and visual review |
| User | Human | Approval and corrections |
| Codex | Cross-agent | Independent validation |

### Agents Used

| Agent | Role |
|-------|------|
| idea-explorer | Expand ideas through strategic questioning |
| requirements-analyst | Transform ideas into concrete PRD |
| system-architect | Design architecture and produce TRD |
| feature-executor | Implement features (Claude or Codex) |
| code-reviewer | Cross-agent code review |
| frontend-reviewer | Frontend-specific review (a11y, responsive) |

## Requirements

- Claude Code CLI
- Plannotator plugin (optional — falls back to inline text review)
- codex-plugin-cc (optional — falls back to Claude-only workflow)

## License

MIT
