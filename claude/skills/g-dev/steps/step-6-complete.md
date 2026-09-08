# Step 6: Complete

Entry condition: every task file at status done, or at review with only
`manual:` criteria outstanding (those resolve in A.3). Any task at pending,
in-progress, or blocked -> list each offender as `t<NN> (<status>)` and
stop.

## A. Fresh verification

1. For EVERY task, run every executable completion criterion again, from
   the main working tree (`repo-path` in state.md), not a leftover
   worktree.
2. Any failure -> print the task id, the criterion, and the command output;
   set that task's status back to review; stop. Never gloss a failure.
3. Collect all `manual:` criteria into one list with their task ids; the
   user must confirm that list before proceeding. On confirmation, set each
   review task with no other outstanding criteria to done (the review ->
   done transition), with a Log entry naming what was confirmed.
4. architecture.md Directory Layout defines a tree (not the
   follows-existing line) -> run `ls <root>/README.md` for the repo
   root and each package root in that tree; a miss is handled like an
   item-2 failure (report it, set the task whose criteria list that
   README back to review, stop). Backstop for task files written
   before the step-4 README gate existed.

## B. Close out

1. Set `state.md` `current-step: complete`, updated today.
2. Invoke the g-vault-log skill with args
   `complete <domain>/<slug>`. It proposes the archive move, the assets
   disposition, and wiki candidates - every move and deletion is
   per-item user-confirmed there.
3. Final report with evidence: per-task criteria results, the project's
   commit list (collect the commit hashes recorded in each task file's Log
   and show each via `git log --oneline -1 <hash>`), and the vault paths
   written.
