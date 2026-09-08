# State and Task File Formats

Canonical path variables:

```bash
VAULT="$HOME/Documents/obsidian-vault"
# DOMAIN: work when $PWD is under $HOME/Documents/GitHubWork, else dev;
# on resume, DOMAIN and SLUG come from the matched state.md path instead
ASSETS="$VAULT/projects/$DOMAIN/assets/$SLUG"
DOC="$VAULT/projects/$DOMAIN/$SLUG.md"
```

Direct step entry (SLUG unknown) resolves the project via the shared
lookup script:

```bash
bash ~/.claude/skills/g-dev/scripts/find-repo-projects.sh
```

`GUARD_FAIL` = repo or vault invalid: fix that first, never treat as
0 matches. 1 match -> DOMAIN and SLUG come from that path. 0 matches ->
say "no g-dev project for this repo; run /g-dev idea first" and stop.
2+ -> print `<slug> (<current-step>)` per match and ask.

The Bash tool does NOT persist variables between calls: every command block
must define, in that same call, each variable it uses. An unset variable
silently empties the path and turns errors into false "no results" - when a
lookup returns 0 matches, first confirm the inputs were non-empty before
acting on the zero.

Ownership: g-dev writes only under `$ASSETS`, plus two exceptions on `$DOC`:
the init skeleton (step 1) and the goal section (step 2). Everything else in
`$DOC` (status block, decision and work-log entries, frontmatter refresh) is
written only by g-vault-log. Goal wording made stale by a later approved
decision is fixed via the post-handoff amendment rule in the g-dev
SKILL.md (non-build sessions: edit per step-2 D, then
g-vault-log update with a revision summary); g-vault-log itself never
edits the goal.

## state.md (`$ASSETS/state.md`)

```markdown
---
slug: <slug>
repo: <main checkout basename, as find-repo-projects.sh derives it>
repo-path: </absolute/path/to/main/checkout>
created: YYYY-MM-DD
updated: YYYY-MM-DD
current-step: idea | design | breakdown | build | complete
---

## Artifacts
- architecture: assets/<slug>/architecture.md (or: none)
```

Update rules: `repo` is always the main checkout's basename, never a linked
worktree's dir name (worktree sessions still resolve to the same project).
Set `current-step` to the NEXT step during handoff, before
printing the completion message. Refresh `updated` (`date +%F`) on every
write. Only the session running a step transition writes this file; a build
session working a task never does.

## Task file (`$ASSETS/tasks/t<NN>-<kebab-name>.md`, NN = 01..99)

```markdown
---
id: t<NN>
title: <one line>
status: pending | in-progress | review | done | blocked
depends: []            # or [t01, t02]
session: none          # claiming session marker
updated: YYYY-MM-DD
---

## Goal
<the deliverable, 1-3 sentences>

## Scope
<files / modules expected to change>

## Plan
<3-7 numbered steps>

## Completion criteria
<2-5 items; each is a command plus its expected result, or manual:>
- [ ] `pnpm test src/auth` exits 0
- [ ] `pnpm lint` exits 0
- [ ] manual: user confirms the login screen matches the UI direction

## Log
<newest first; one entry per handoff or stagnation decision>
### YYYY-MM-DD <title>
<what happened; evidence: commands + results, commit hash>
```

`manual:` is the only allowed non-executable criterion form; a task whose
criteria are ALL `manual:` is valid only for doc-only or user-verification
tasks. Status meanings: `review` = implementation done, a manual criterion
or user check pending; `blocked` = stagnation menu chose escalation.

## Review file (`$ASSETS/reviews/YYYY-MM-DD-<kebab-topic>.md`)

Written only when a standalone design run (step 3b) is merged into a
project on the user's explicit yes. Create `$ASSETS/reviews/` if missing.

```markdown
---
topic: <one line>
mode: proposal-review | investigation
created: YYYY-MM-DD
---

## Result
<mode A: final verdict + approval tables; mode B: one block per question>
```

Merge rules: never write `state.md` (a standalone run is not a step
transition; `current-step` stays unchanged); the formal doc is updated only
via the handoff procedure below.

## Handoff procedure (shared by steps 2-5; step 3b on merge)

1. Write the files this step owns: the task file (build) or `state.md`
   (step transitions: set the next `current-step`). Step 3b merge: the
   review file only, never `state.md`.
2. Invoke the g-vault-log skill with args
   `update <domain>/<slug>` plus a summary block containing: the step just
   finished, decisions made (with the why), work done (with evidence:
   commands run, results, commit hashes), open questions. g-vault-log
   regenerates the formal doc's status block from `tasks/*.md` and appends
   the entries.
3. If the Skill invocation errors, append the same entries directly to
   `$DOC` following
   `~/.claude/skills/g-vault-log/references/note-format.md`, and report
   that the fallback path was used.
4. Print a completion message: step finished, artifacts written (paths),
   what comes next.
5. STOP. Do not load the next step file in the same session unless the user
   explicitly asks.
