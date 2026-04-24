# dev review

On-demand code review. Supports PR URLs and local diffs. No devlog required.

## Features

- **Auto scope detection** — staged changes → unstaged → file path → PR URL
- **Cross-agent routing** — Claude reviews Codex output; Codex reviews Claude output
- **Parallel frontend review** — dispatches `frontend-reviewer` alongside `code-reviewer` when UI changes are detected
- **Plannotator support** — visual review when a PR URL is provided
- **Severity grouping** — findings presented as Blocking / Suggestions / Looks good

## Usage

```
/dev review
/dev review <PR-URL>
/dev review <file-path>
```

## How It Works

```
Scope Detection
    │
    ├── PR URL → plannotator-review skill
    └── diff / file
            ├── Detect authorship (Claude / Codex / mixed)
            ├── Dispatch code-reviewer agent
            └── Frontend changes? → also dispatch frontend-reviewer (parallel)
```

### Review Routing

| Author | Reviewer | Method |
|--------|----------|--------|
| Claude | Codex | `code-reviewer` agent → `/codex:review` |
| Codex | Claude | `code-reviewer` agent (Claude reviews) |
| Unknown / mixed | Claude | `code-reviewer` agent |

### Output Format

```
## Review Results

### 🔴 Blocking
- <issue> [file:line]

### 🟡 Suggestions
- <issue> [file:line]

### ✅ Looks good
- <summary>
```

## Requirements

- `code-reviewer` agent (`~/.claude/agents/code-reviewer.md`)
- `frontend-reviewer` agent (optional, for UI change detection)
- Plannotator plugin (optional, for PR URL review)

## License

MIT
