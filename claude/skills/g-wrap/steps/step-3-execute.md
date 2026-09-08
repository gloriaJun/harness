# Step 3: Guarded Execution

Run the groups in this order, rows by ascending number. A failure in one row
never stops the remaining rows: record it and continue.

## A. Files (`vault`, `plans`, `scratchpad`, `untracked`)

```bash
rm -f "<path>"
```

Always quote the path: collected paths may contain spaces or non-ASCII
characters. Vault paths use `rm` only, never `git add`, `git commit`, or
`git push` inside `~/Documents/obsidian-vault`. A row whose path is a
directory is skipped with the reason `directory, use /g-cleanup`; never
`rm -rf` here.

## B. Servers

Run the stop method recorded in Step 1.B: the background-shell tool's kill
action (Claude: KillShell + shell id), or `kill <pid>` for a known pid. Verify
a pid stop with `kill -0 <pid>` (non-zero exit means stopped); a tool-side
stop needs no verification. Still alive: report `still running` and leave it.

## C. Worktrees

Per worktree path `WT`:

```bash
[ "$(cd "$WT" && pwd -P)" = "$(pwd -P)" ] && echo SKIP_CURRENT
git -C "$WT" status --porcelain; echo "STATUS_EXIT=$?"
git branch -r --contains "$(git -C "$WT" rev-parse HEAD)"
```

Skip with the reason `current worktree` when the output contains
`SKIP_CURRENT`. Remove only when `STATUS_EXIT=0` AND no path is printed
before it AND the third command prints at least one remote branch:

```bash
git worktree remove "$WT"
```

Any check failing, including a non-zero exit code, is a skip with its reason
(`uncommitted work`, `commits not on any remote`, or `status check failed`).
Never pass `--force`.

## D. Branches

Never delete the branch currently checked out. Per branch `B`:

```bash
git branch -d "$B"
```

Success: removed. Failure for any reason: skip and report `unmerged, kept`.
`git branch -D` is not used by this skill under any condition.

## E. Result

```
| # | surface | path | result |
```

`result` is `removed`, `skipped: <reason>`, or `failed: <command output>`.
Close with one line: `removed N, skipped M, failed K`, plus the git state
from Step 1 when anything is still uncommitted or unpushed. Any `failed` row
present: report the run as partially complete, never as done.
