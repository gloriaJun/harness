# Skill Authoring Convention

Skills in this project follow these authoring rules.
These rules also apply when using the skill-creator plugin to generate new skills.

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

## skill-creator Integration

When using skill-creator to generate a new skill, also apply these rules:
1. Review whether logic separation fits the orchestrator principle
2. Add a mermaid diagram if the draft lacks one
3. Propose `scripts/` extraction for reusable logic
