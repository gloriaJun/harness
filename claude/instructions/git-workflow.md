# Git Workflow

## Commit Message Convention

Format: `<type>: <subject>`

### Types
| Type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| perf | Performance improvement |
| refactor | Refactoring |
| revert | Revert previous commit |
| style | Code style (formatting, semicolons; no logic change) |
| docs | Documentation (add, update, delete) |
| test | Tests (add, update, delete; no logic change) |
| build | Build script changes |
| ci | CI/CD script changes |
| chore | Miscellaneous (package install, config changes) |

### Format Rules
- Subject: max 50 characters, lowercase first letter, imperative mood, no trailing period
- Body: max 72 characters per line, explain "what" and "why" (not "how"), use `-` for multiple points
- Separate subject and body with a blank line
- Write commit messages (title and body) in English only

## Rules
- Co-Authored-By line is optional — include only when user requests
- Always create new commits, never amend unless explicitly asked
- Stage specific files, avoid `git add -A`
