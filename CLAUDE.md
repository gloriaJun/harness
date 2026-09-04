# grimoire

Source of truth for the user-level Claude Code configuration (v2). `claude/` is copy-synced one-way to `~/.claude/`, and a migration layer (`codex-sync.sh`) generates the Codex CLI config surface (`~/.codex/`) from the same Claude-side sources. v1 is preserved on the `v1` branch.

## Critical rules

- Edit only in this repo. Direct edits in `~/.claude/` are overwritten on the next sync.
- Sync runs automatically on commit: `githooks/post-commit` (wired via `git config core.hooksPath githooks`) calls `sync.sh` then `codex-sync.sh` when the commit touched `claude/` or `ccstatusline/`. It syncs the working tree state, not the commit. Preview with `./sync.sh --dry-run` and `./codex-sync.sh --dry-run`.
- Sync ownership (see header of `sync.sh`):
  - `claude/instructions/shared/*.md` → assembled (filename order) into `~/.claude/AGENTS.md`. `~/.claude/CLAUDE.md` is a generated stub: `@AGENTS.md` import line + `claude/claude-only.md`. There is no `claude/CLAUDE.md` source file anymore. Codex has no import syntax, so `codex-sync.sh` writes the same shared body as a full copy into `~/.codex/AGENTS.md`.
  - `claude/instructions/`, `claude/hooks/`, `claude/agents/` → full mirror with `--delete`. Deleting a file here deletes it live.
  - `claude/skills/`: only `g-*` entries are managed. `l-*` belongs to the company repo (`~/Documents/GitHubWork/toolbox/ai-configuration`); anything else is warn-only.
  - `claude/settings.hooks.json` → merged into the `hooks` key of `~/.claude/settings.json` via jq; `claude/settings.statusline.json` → merged into the `statusLine` key and `claude/settings.permissions.json` into the `permissions` key the same way. None of these files are copied; other settings keys stay untouched.
  - `claude/settings.mcpServers.json` → source of truth for user-scope MCP servers. Claude Code reads them only from `~/.claude.json`, so bootstrap.sh applies missing entries via `claude mcp add-json --scope user`; sync.sh never writes `~/.claude.json` and only warns on drift. `disabled: true` = declared but not installed.
  - `ccstatusline/` (repo root) → rendered to `~/.config/ccstatusline/` with the `{{HOME}}` placeholder substituted, so no username is committed.
- All definition files under `claude/` are English-only. Korean readability comes from the doc viewer (`tools/doc-viewer`), never from Korean source files. Korean is allowed inside files only as quoted examples (style pairs, trigger phrases) or template skeleton labels inside code fences.
- External installs (plugin marketplaces, plugins, third-party skills) are declared in `external.json` and installed by `./bootstrap.sh` - never install ad hoc without adding the entry to the manifest. Company marketplaces/plugins stay out of this repo (the live environment may carry them; bootstrap reports but never touches undeclared entries).
- v1 backup at `~/.claude_bak` is read-only reference. It contains company-specific data (e.g. Jira ticket prefixes); never copy such content into this repo.
- Instruction change review: pre-save Korean confirmation follows the global definition-file change flow (`claude/instructions/references/definition-files.md`). After saving definition-file changes under `claude/` and before the final commit proposal, ask the user whether to run the doc-viewer diff review (`/g-docs-ko`). On yes: regenerate translations (`pnpm build skeleton grimoire` → fill empty `ko` → `pnpm build`), start the viewer (launch.json `doc-viewer`), and wait for diff-panel confirmation. On no: proceed straight to the commit proposal; translation sidecars then stay stale until the next `/g-docs-ko` run (accepted). The post-commit sync makes the commit live.

## Layout

- `claude/` - the synced payload: instructions/shared (tool-neutral CLAUDE.md/AGENTS.md fragments), claude-only.md (Claude-specific sections), instructions/references (writing-style, tech-stack, code-review, skill-authoring, definition-files, templates/), hooks (pr-guard.sh, emdash-check.sh, definition-check.sh, def-review-gate.sh, def-review-approve.sh, delegation-report-reminder.sh), settings.hooks.json, settings.statusline.json, settings.permissions.json
- `sync.sh`, `codex-sync.sh`, `githooks/post-commit` - sync mechanism
- `bootstrap.sh`, `external.json` - fresh-machine setup + external-install manifest
- `ccstatusline/` - statusline widget config, rendered to `~/.config/ccstatusline/`
- `bin/cwt` - worktree + Claude launcher CLI (symlinked from `~/.local/bin/cwt`)
- `templates/` - per-machine config skeletons (codex config.toml)
- `tools/doc-viewer/` - bilingual static-site viewer (TypeScript)
- `.claude/launch.json` - preview server config for the viewer (port 4173)

## Codex sync (codex-sync.sh)

- Generates the Codex config surface from Claude-side state; Codex has no hand-maintained sources. See the script header for full rules.
- `~/.codex/AGENTS.md` = generated header + `claude/instructions/shared/*.md` (byte-identical to `~/.claude/AGENTS.md`) + company workspace `~/Documents/GitHubWork/CLAUDE.md` as a scoped section (when present). Warns above 24576 bytes (self-imposed budget: Codex applies no size limit to the global file, `project_doc_max_bytes` counts project docs only).
- `~/.codex/skills/` = migrated copies of `~/.claude/skills/*` (minus the exclude list in the script, currently `g-insight`) plus skills inside installed Claude plugins (`mp-<plugin>-<skill>`). SKILL.md frontmatter is reduced to `name`/`description` because Codex rejects unknown keys; bodies are copied verbatim.
- Ownership via `~/.codex/codex-sync-manifest.json`: only manifest-listed entries are ever deleted. `~/.codex/skills/.system/` and unmanaged entries are never touched.
- Runs from post-commit after `sync.sh`; run manually after installing/updating Claude plugins.

## Hooks (claude/hooks/)

- Shell scripts reading tool-call JSON from stdin; exit 2 blocks (PreToolUse) or feeds back (PostToolUse).
- Inventory:
  - `pr-guard.sh` (PreToolUse, Bash): `gh pr create` must carry `--draft` and `--base`.
  - `emdash-check.sh` (PostToolUse, Write|Edit): flags em/en dashes written to md files.
  - `definition-check.sh` (PostToolUse, Write|Edit): definition-file size budgets, English-only check, mermaid/README presence for SKILL.md.
  - `def-review-gate.sh` (PreToolUse, Write|Edit): emits permissionDecision "ask" so definition-file writes raise a user approval prompt, unless the path was recorded by `def-review-approve.sh` within 5 minutes.
  - `def-review-approve.sh` (manual, not hook-registered): records in-chat Korean-review approvals to `~/.claude/.def-review-approvals` (TTL 5 min) for the gate's marker pass.
  - `delegation-report-reminder.sh` (PostToolUse, Task|Agent): feeds back a reminder to include the delegation report (task / model / reason) whenever an agent call returns.
- `settings.hooks.json` also carries an inline SessionStart hook that logs codex in from `$OPENAI_CODEX_API_KEY`. It exists solely so explicit codex requests work; autonomous codex use stays forbidden (user CLAUDE.md).
- Test manually before commit: `echo '<tool-call json>' | claude/hooks/<script>.sh; echo $?`.
- All except `def-review-approve.sh` are registered in `claude/settings.hooks.json`, which references them at their live path `$HOME/.claude/hooks/`.
- Changes take effect from the next Claude Code session (settings load at session start).

## doc-viewer (tools/doc-viewer/)

- `pnpm install` once; `pnpm build` regenerates `dist/`; `pnpm build skeleton [rootName]` regenerates translation sidecars in `translations/` (carries over `ko` for unchanged segments; fill only the empty `ko` fields).
- `dist/` and `translations/` are gitignored: translations are display-only, the English source is the sole authority.
- Roots (this repo + company repo) are defined in `doc-viewer.config.json`.
- Serve with the preview tool (launch.json `doc-viewer`) or `node tools/doc-viewer/serve.mjs`.
