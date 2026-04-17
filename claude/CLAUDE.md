# Claude Code Instructions

## Core Principles
- Respond in Korean
- Never modify code without user confirmation
- Provide rationale and explanation for every proposed change
- Review first, then proceed — no autonomous code modifications

## Recommended Model
- Default CLI model: **Sonnet** (cost-efficient orchestrator)
- Opus: invoked as advisor only via Agent tool (direction/judgment, never as main session)

## References
@instructions/tech-stack.md
@instructions/git-workflow.md
@instructions/agent-guidelines.md

## On-Demand References (instructions/references/)
- Session start: check `../_claude/work-plan/` for plan folders matching current repo name.
  - None found → proceed without loading work-plan instructions
  - 1 found → ask whether to continue [folder-name] (Y/n)
  - 2+ found → list folders with numbers, ask which to continue (0: none)
  - Selected → load `@instructions/references/work-plan.md` and resume that plan
  - Not selected (n / 0) → proceed without loading work-plan instructions
- When creating or modifying definition files, load `@instructions/references/token-budget.md`
- When creating or modifying skills, load `@instructions/references/skill-authoring.md`
- When invoking Opus as advisor, load `@instructions/references/opus-advisor-pattern.md`

@RTK.md
