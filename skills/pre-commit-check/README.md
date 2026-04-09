# g-pre-commit-check

Automatic self-review before git commits. Summarizes staged changes, checks for missing items, and performs a security review. Must complete before any commit proceeds.

## Features

- **Staged Diff Analysis** — Analyzes `git diff --cached` to understand all staged changes
- **4-Category Checklist** — Reviews correctness, security, code quality, and completeness
- **Mandatory Security Check** — Security review is never skipped regardless of change size
- **Issue Resolution Flow** — When issues are found, prompts user to fix and re-run or proceed anyway
- **Auto-Trigger** — Hooks into `git commit` via PreToolUse hook for automatic activation
- **Structured Output** — Presents review results in a clear, categorized format

## Usage

```
/g-pre-commit-check
```

Also triggers automatically when a `git commit` command is detected via the PreToolUse hook.

## How It Works

```
git commit (or /g-pre-commit-check)
  → Collect staged changes (git diff --cached)
  → Summarize changes
  → Run checklist review
    ├── Correctness: logic errors, missing edge cases
    ├── Security: injection, secrets, OWASP top 10
    ├── Code Quality: naming, duplication, complexity
    └── Completeness: missing tests, docs, types
  → Output structured results
  → If issues found: user decides (fix + re-run / proceed)
```

## Requirements

- Claude Code CLI
- Git

## License

MIT
