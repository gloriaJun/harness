# Step 1: Inventory

## A. Collect

```bash
bash ~/.claude/skills/g-wrap/scripts/collect-artifacts.sh
```

Check first with
`test -e ~/.claude/skills/g-wrap/scripts/collect-artifacts.sh`. It fails, or
the run exits non-zero, or the output carries an `error` row: run
`git status --porcelain` instead, report the git state plus one line naming
the failure, and end the skill. Do not improvise the other surfaces.

The script is macOS-only and silences per-surface errors, so an empty surface
and a broken surface look the same. Never claim a surface is clean; report
only what the rows show.

Output columns: `surface`, `path`, `detail`, `deletable`. The first row is
`window`; report its epoch as a local time in one line above the table so the
user can sanity-check the scope, then drop it from the table.

## B. Add conversation-derived rows

The collector never inspects processes. From this conversation only, add one
row per item:

- `server` (`deletable = yes`): a dev or sample server started this session
  and still running. Record how it stops: a shell started through the
  client's background-shell tool stops with that tool's kill action (Claude:
  KillShell + shell id); a known pid stops with `kill <pid>`.
- `branch` (`deletable = yes`): a local branch created this session, by name.

Nothing in the conversation: add nothing. Never scan listening ports and
never list a process this session did not start.

## C. Table

Number every row from 1, group by surface, report-only rows last:

```
| # | surface | path | detail | default |
```

Default column:

- `delete`: `scratchpad`, `plans` (machine scaffolding).
- `keep`: `untracked`, `worktree`, `server`, `branch`, and `vault` rows with
  `deletable = yes` (untracked files include new source; vault rows wait on
  the Step 2 record decision).
- `-`: every `deletable = no` row (`git-dirty`, `git-unpushed`, `memory`,
  hand-written `vault`, untracked directories). These are report-only and
  can never be picked.

Vault rows carry a time window, not a session id: a `deletable = yes` vault
row whose path this conversation never wrote or named belongs to another
session. Downgrade it to report-only with the detail
`other session, report only`; it can never be picked.

More than 30 deletable rows: show the first 30, state the remaining count in
one line, and note that the rest is `/g-cleanup` territory.

## Termination

- Zero deletable rows: report the git state, state that there is nothing to
  clean, and end. Do not load Step 2.
- One or more deletable rows: load `steps/step-2-decide.md`.
