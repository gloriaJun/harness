# User-Level Instructions

Source of truth: `~/Documents/GitHubPrivate/grimoire/claude/`. On commit, sync scripts assemble the shared fragments into one tool-neutral body: `~/.claude/AGENTS.md` (imported by the `~/.claude/CLAUDE.md` stub) and `~/.codex/AGENTS.md` (full copy). Always edit in the repository and commit - direct edits to the generated files get overwritten on the next sync.
Project-specific rules (tech stack details, commands, architecture) go in each repository's own instruction file (CLAUDE.md / AGENTS.md) - this file is only about the 'user'.
