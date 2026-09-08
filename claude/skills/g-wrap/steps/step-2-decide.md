# Step 2: Record Decision and Per-Item Pick

## A. Record gate

Evaluate this session against three conditions:

- (a) a diagnosed root cause
- (b) a conclusion drawn from 2 or more sources
- (c) a reasoned technical decision

This session already ran g-vault-log and wrote at least one note:
`record = written`. Ask nothing, and carry every written path into B.

None of (a) to (c), or all of them already landed in a repo file or a commit
message: treat the record as unnecessary, ask nothing, go to B with
`record = declined`.

Otherwise ask exactly once (the client's question tool if it has one, else a
plain chat question), one question, two options in this order:

1. `no record` (recommended) - one line naming what would go unrecorded.
2. `record it` - hands off to g-vault-log.

Never ask twice, and never re-raise the question after a decline.

## B. Apply the decision

`record = written`:

- Every path this session wrote is locked to `keep` and stays out of C.
- No vault row switches to `delete`; the decline branch below never applies.
- Other surfaces keep their Step 1 defaults.

`record = declined`:

- Every `vault` row with `deletable = yes` switches its default to `delete`.
  Hand-written vault rows stay report-only and are never touched.
- Write nothing to the vault: no new note, no append, no relocation, no
  promotion to `wiki/`. A request to remove a note is a removal, not a move.

`record = accepted`:

- Invoke the g-vault-log skill (Claude: Skill tool), no arguments.
- Every path it reports as written switches to `keep` and is locked out of C.
- Refresh the vault surface afterwards so notes created during the handoff
  appear: `bash ~/.claude/skills/g-wrap/scripts/collect-artifacts.sh vault`.
  Its first row is the `window` row again; drop it as in Step 1.
- It reports no written path (vault missing, or the user declined inside it):
  treat that as `record = declined` and apply the branch above.

## C. Per-item pick

Present the updated table and collect picks:

1. Non-vault rows: ask the user to confirm the `default` column as shown or
   name exceptions by row number (for example "3, 5 keep").
2. Vault rows: ask row by row, one confirmation per row. A bulk answer never
   covers a vault row; re-ask each one individually.

Report-only rows are never pickable. An answer that names a row number not in
the table, or that cannot be mapped to keep or delete, is not guessed at:
restate the unresolved rows and ask again, at most twice. Still unresolved
after the second re-ask: default those rows to `keep`.

## Termination

- Zero `delete` rows after the picks: report that nothing was removed,
  restate the git state, end. Do not load Step 3.
- One or more `delete` rows: load `steps/step-3-execute.md`.
