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

## Post-Task Workflow

When a skill is created, modified, or deleted, always ask the user whether to:
1. Commit and push the changes
2. Run `setup.sh` (or equivalent) to sync symlinks to `$HOME`

## skill-creator Integration

When using skill-creator to generate a new skill, also apply these rules:
1. Review whether logic separation fits the orchestrator principle
2. Add a mermaid diagram if the draft lacks one
3. Propose `scripts/` extraction for reusable logic
