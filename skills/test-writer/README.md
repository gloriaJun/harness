# g-test-writer

Generates comprehensive test suites following TDD methodology. Analyzes target code, determines the optimal testing approach, and produces well-structured tests covering normal, edge, error, and boundary cases.

## Features

- **4 Testing Approaches** — Auto-selects from TDD (Red-Green-Refactor), Storybook TDD (story-first), Test-After (existing code), or Defer (prototype code)
- **4 Test Case Categories** — Covers normal paths, edge cases, error handling, and boundary values
- **Iterative Fix Loop** — When tests fail, analyzes failures and applies corrections automatically
- **UI Component Support** — Recommends Storybook TDD for UI components with story-first workflow
- **Prototype Detection** — Identifies exploratory code and recommends stabilization before testing
- **Cross-Review** — Offers Codex validation of test quality; falls back to Claude self-review

## Usage

```
/g-test-writer
```

## How It Works

```
/g-test-writer
  → Step 1: Code analysis + approach selection
    ├── TDD: new code, write tests first
    ├── Storybook TDD: UI components, stories first
    ├── Test-After: existing stable code
    └── Defer: prototype (recommend stabilization)
  → Step 2: Test case design (normal/edge/error/boundary)
  → Step 3: Test code generation
  → Step 4: Execute + review
    └── If failures: analyze → fix → re-run (loop)
```

### Approach Selection

| Approach | When used |
|----------|-----------|
| TDD | New features or functions not yet implemented |
| Storybook TDD | UI components (React, Vue, etc.) |
| Test-After | Existing stable code lacking test coverage |
| Defer | Prototype or exploratory code (suggest stabilization first) |

## Requirements

- Claude Code CLI
- Test runner: jest / vitest / mocha / pytest (falls back to manual run guidance)
- Storybook (optional — for UI component testing; falls back to standard component tests)

## License

MIT
