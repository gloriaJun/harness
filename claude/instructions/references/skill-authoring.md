# Skill Authoring Convention

Skills in this project follow these authoring rules.
These rules also apply when using the skill-creator plugin to generate new skills.

## Language Convention

All skill and instruction files must be written in **English only**.
English is more token-efficient (~1.5-2x fewer tokens than Korean for the same content).
These files are loaded into context every session, so token savings compound.

- SKILL.md body, step files, mermaid labels, comments: **English**
- User-facing output (conversation responses): Determined by user preference (e.g. CLAUDE.md `Respond in Korean`), not hardcoded in skill files

## SKILL.md = Orchestrator Only

SKILL.md is a thin orchestrator — it routes to sub-files, not implements logic inline.

- Route the overall flow: what to do, in what order, under what conditions
- Delegate detailed logic to `steps/`, `scripts/`, `references/`
- Reference model: `skills/task-process/SKILL.md`

## README.md = Human Documentation

Every skill must include a `README.md` alongside `SKILL.md`. While SKILL.md is LLM-facing
(orchestration logic), README.md is human-facing (features, usage, architecture).

- Language: **English** (follows the same convention as SKILL.md)
- Reference model: `skills/my-claude-audit/README.md`

### Template

```markdown
# skill-name

One-line description.

## Features

- **Feature A** — explanation
- **Feature B** — explanation

## Usage

\`\`\`
/g-skill-name
\`\`\`

## How It Works

Brief architecture or workflow description.
Subagent table if applicable.

## Installation

\`\`\`bash
ln -s /path/to/skill ~/.claude/skills/skill-name
\`\`\`

## Requirements

- Claude Code CLI
- (optional dependencies)

## License

MIT
```

### Required vs Optional Sections

| Section | Required | Notes |
|---------|----------|-------|
| Name + description | Yes | H1 + one-line summary |
| Features | Yes | Bullet list of key capabilities |
| Usage | Yes | Command invocation example |
| How It Works | Yes | Workflow overview, subagent table if applicable |
| Installation | Optional | Include when install steps are non-obvious |
| Requirements | Optional | Include when external dependencies exist |
| License | Optional | Default MIT |

### Step Extraction

| Condition | Action |
|-----------|--------|
| 3+ steps, each independently describable | Extract to `steps/step-N-*.md` |
| 2 or fewer steps, or tightly coupled flow | Keep inline in SKILL.md |

### Script Extraction

Extract to `scripts/` when any of:
- Same logic is invoked 2+ times within the skill
- Shell commands composing external CLIs exceed 5 lines
- Deterministic processing (file parsing, aggregation, transformation)

## Persona Definition

### Skill-Level Persona

When the skill operates in a specialized domain, define a persona at the top of the
SKILL.md body (after the mermaid diagram, before the first step). A well-chosen persona
steers the LLM's reasoning toward domain-appropriate decisions.

**Format:**
```
You are a [role] specializing in [domain]. You [key trait that shapes behavior].
```

**Examples:**
- Test writer skill: `You are a senior QA engineer. You design tests that catch real bugs, not just confirm happy paths.`
- Architecture skill: `You are a system architect. You translate requirements into designs with clear trade-off analysis.`

| Condition | Persona needed? |
|-----------|----------------|
| Domain expertise shapes output quality (security, testing, architecture, a11y) | Yes |
| Skill is a mechanical workflow (file transform, config sync, cleanup) | No |
| Skill dispatches agents that each need different expertise | Define per-agent, not skill-level |

**Guidelines:**
- One sentence is enough — keep it under 30 words
- Focus on the trait that most affects decision-making, not a job description
- Do not stack multiple personas ("You are a QA engineer and a security expert and...")
- If the persona adds no reasoning value, omit it entirely

### Agent-Level Persona

Subagents run in isolated context windows with no inherited state from the parent.
A clear persona in each agent prompt is more impactful here than at the skill level,
because the agent has no surrounding context to infer its role from.

**Required structure for agent prompt files:**

```markdown
# Agent Name

[One-line persona statement]

## Role

[2-3 sentences expanding what this agent does and how it thinks]
```

**When skill and agent personas should differ:**

| Scenario | Example |
|----------|---------|
| Agent performs a different discipline than the skill | Skill: test-writer (QA), Agent: code-analyzer (static analysis) |
| Agent acts as a counterpart for cross-review | Skill: feature-executor (builder), Agent: code-reviewer (critic) |
| Agent handles a sub-task requiring distinct expertise | Skill: task-process (orchestrator), Agent: requirements-analyst (BA) |

**When to share the same persona:**
- Agent is a parallelized instance of the same skill task (e.g., running the same analysis on different inputs)
- Agent is a grader/evaluator of the skill's own output with no domain shift

## Mermaid Diagram Required

Every skill must include a mermaid diagram in SKILL.md, placed at the top of the body (before the first step/phase section).

### Diagram Type Guide

| Situation | Recommended type |
|-----------|-----------------|
| Linear step flow | `flowchart TD` |
| Branching / conditional process | `flowchart TD` with diamond nodes |
| Complex state transitions with sub-states | `stateDiagram-v2` |
| Agent-to-agent interactions | `sequenceDiagram` |

### Minimum Requirements

- Show the full path from trigger to completion
- Include all branch/condition paths
- Mark external tool dependencies as distinct nodes

## Skill-Local Agent Definitions

Skills that dispatch subagents can define agent prompts within their own directory
instead of registering them globally in `.claude/agents/`.

### Directory Convention

```
skills/<skill-name>/agents/
  <agent-name>.md    # agent prompt file
```

### When to Use

| Scope | Location | Registration |
|-------|----------|-------------|
| **Global** — used by multiple skills or invoked independently | `.claude/agents/` | Auto-registered as `subagent_type` |
| **Global (standalone value)** — currently used by one skill, but provides independent value when invoked directly (e.g. idea exploration, requirements analysis) | `.claude/agents/` | Auto-registered as `subagent_type` |
| **Skill-local** — tightly coupled to one skill with no standalone value | `skills/<skill>/agents/` | Read via Read tool, dispatched via Agent tool |

### Invocation Pattern

Skill-local agents are NOT auto-registered. Invoke them as follows:

1. Read the prompt file: `Read("agents/<agent-name>.md")`
2. Prepend context data (inputs, discovery results)
3. Dispatch: `Agent(subagent_type: "Explore", prompt: <combined prompt>)`

Reference implementation: `skills/my-claude-audit/analyzer-prompts/` (predates this convention; new skills should use `agents/`).

### Migration

Existing skills using non-standard folder names (e.g. `analyzer-prompts/`) are not required to rename immediately. New skills must use `agents/`.

## Agent Rules

For model selection and parallel execution limits, see `@instructions/agent-guidelines.md`.
These rules apply to both skill-local and global agents.

## Runtime Behavior Checklist

When designing a skill, review these items to ensure the skill leverages the full
agent and tool ecosystem. Static structure (files, steps, mermaid) is not enough —
consider how the skill behaves at runtime.

| Check | Question | Action if yes |
|-------|----------|---------------|
| Parallel work | Are there steps where independent work can run simultaneously? | Dispatch Agent (Explore or custom) for parallel tasks |
| Cross-review | Does the skill produce code changes or fix implementations? | Offer code-reviewer / Codex cross-review (mandatory or user-optional) |
| Global agent reuse | Can an existing global agent (`agents/*.md`) handle a sub-task? | Reuse it instead of writing inline logic |
| External tools | Does a step benefit from MCP tools, CLI commands, or web lookups? | Document as external dependency with fallback |
| Skill escalation | Could a step's scope grow beyond the skill's expertise? | Define escalation path to a specialized skill (e.g., `/g-test-writer`) |

## Post-Task Workflow

When a skill is created, modified, or deleted, always ask the user whether to:
1. Commit and push the changes
2. Run `setup.sh` (or equivalent) to sync symlinks to `$HOME`

## Skill Review & skill-creator Integration

When creating or modifying a skill, load and follow `@instructions/references/skill-review.md`
for reuse check, duplication detection, and Codex review protocol.
This also includes skill-creator integration rules.
