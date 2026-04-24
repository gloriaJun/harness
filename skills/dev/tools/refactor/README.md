# g-refactor

Code restructuring and quality improvement skill with before/after diffs and rationale-driven proposals.

## Features

- **Clean Architecture** — Detect layer violations, circular dependencies, and tight coupling
- **TypeScript Types** — Find `any` usage, missing interfaces, and type assertion overuse
- **Deduplication** — Identify copy-paste code, scattered utilities, and cloned components
- **Naming & SRP** — Spot misleading names, large functions, and inconsistent conventions
- **Performance Patterns** — Catch re-render issues, N+1 access, memory leaks, bundle bloat
- **Before/After Diffs** — Every proposal shows current vs proposed code with file paths
- **Selective Approval** — Approve all changes or pick specific items by ID

## Usage

```
/g-refactor
```

Also triggers on natural language:
- "리팩토링 해줘", "코드 정리해줘", "클린 아키텍처 적용해줘"
- "중복 코드 정리해줘", "타입 추가해줘", "성능 개선해줘"

## How It Works

```
Step 0: Scope → Step 1: Analysis → Step 2: Proposal → Step 3: Confirm → Step 4: Execute → Step 5: Review
```

| Step | Description |
|------|-------------|
| 0. Scope | Collect target files, detect analysis mode |
| 1. Analysis | Explore agent scans codebase; apply mode checklist |
| 2. Proposal | Present before/after diffs with rationale per issue |
| 3. Confirm | User approves all, selects by ID, or requests revision |
| 4. Execute | Apply approved changes in dependency order |
| 5. Review | Summary, optional cross-review, test suggestions |

### Modes

| Mode | Focus |
|------|-------|
| architecture | Layer separation, dependency direction |
| types | TypeScript type coverage |
| deduplication | DRY, code extraction |
| naming | Naming clarity, SRP |
| performance | Static performance patterns |
| auto | Full scan across all modes |

### External Dependencies

| Tool | Purpose |
|------|---------|
| Explore agent | Parallel codebase analysis |
| code-reviewer agent | Optional cross-review (Step 5) |
| /g-test-writer | Behavioral regression tests (Step 5) |

## Installation

```bash
ln -s /path/to/grimoire/skills/refactor ~/.claude/skills/refactor
```

Or run `setup.sh` from the grimoire repo root.

## License

MIT
