# Definition Files

Rules for creating or modifying any AI definition file: CLAUDE.md, AGENTS.md,
SKILL.md anywhere; files under agents/, commands/, instructions/, hooks/,
skills/ in a `.claude`, `.codex`, or grimoire `claude/` tree. Load on demand
BEFORE changing one.

## Change Flow

- Before writing, present the changed parts in the conversation (per section:
  quote the English before/after with a Korean rendering directly under each;
  for a new file, the full proposed content plus a per-section Korean summary)
  and get user confirmation. On rejection: revise and re-present, never write.
- After approval write the file itself in English - for definition files this
  overrides hard rule 6's file-language convention.
- Right after the approval, run
  `bash ~/.claude/hooks/def-review-approve.sh <approved paths>` (one
  permission prompt): subsequent writes to those exact paths skip the gate
  prompt for 5 minutes. Never run it without an explicit approval in chat.
- Mechanical backstop: the PreToolUse hook `hooks/def-review-gate.sh` raises a
  user approval prompt on every definition-file Write/Edit, even in
  acceptEdits mode - except paths recorded by def-review-approve.sh above.

## Quality Bar

Any instruction, skill, hook, or prompt file written for me must pass the
lightweight-model test - a cheap model following only that document should get
a good result. Write exact commands, numeric thresholds, and termination
conditions (including empty-result and error cases). Treat procedure-less
verbs, numberless criteria, and subjectless "judge appropriately" as defects.

## Sizing

Token estimation: `wc -c` / 4.

| File type | Load timing | Max |
|---|---|---|
| `~/.claude/CLAUDE.md` loaded total (`@AGENTS.md` expanded + `claude-only.md`) | Every session | ~3,500 tok (~14,000 chars) |
| `instructions/shared/*.md` (assembled into `~/.claude/AGENTS.md` and `~/.codex/AGENTS.md`) + `claude-only.md` | Every session (via assembly) | ~1,250 tok (~5,000 chars) each; loaded total within the CLAUDE.md budget |
| `instructions/references/*.md` | On-demand (Read) | ~1,250 tok (~5,000 chars) |
| `references/templates/*.md` | On-demand (Read) | ~2,250 tok (~9,000 chars) |
| `SKILL.md` body | On skill trigger | ~750 tok (~3,000 chars) |
| `skills/*/steps/*.md` | On-demand (Read) | ~1,500 tok (~6,000 chars) |
| `skills/*/references/*.md` | On-demand (Read) | ~1,250 tok (~5,000 chars) |
| `agents/*.md` | On agent dispatch | ~500 tok (~2,000 chars) |

- Budgets are advisory ceilings, not hard blocks. Exceeding one requires a
  one-line justification in the commit body.
- Enforcement: the PostToolUse hook `hooks/definition-check.sh` re-checks size
  and the English-only convention after every definition-file Write/Edit.
  Treat its findings as review findings: fix, or justify explicitly.

## Placement

| Condition | Placement | Loading |
|---|---|---|
| Needed every session | CLAUDE.md itself | Always loaded |
| Needed only for specific tasks | `instructions/references/` | Trigger row in CLAUDE.md's on-demand table + Read |
| Needed only in specific projects | That project's CLAUDE.md | Project-local |

Default to `references/`: an unnecessary CLAUDE.md line costs every session;
an on-demand Read costs only when relevant.

## When to Split or Trim

- A reference file exceeds its budget → split by topic, or move detail into a
  skill's `steps/`.
- Adding a rule to CLAUDE.md → compress or remove an equivalent line
  (one in, one out).
- Headroom check before adding a rule: `wc -c` the target file, and for a
  CLAUDE.md fragment also the assembled result
  (`cat instructions/shared/*.md claude-only.md | wc -c`). Headroom under 2%
  of the budget -> propose a split, or a move to `references/` with a trigger
  row, before writing. Never buy room by shaving neighbouring lines.
- One-off incidents belong in memory; only recurring patterns earn instruction lines.
