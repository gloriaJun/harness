# g-sync-config

Link shared configuration files from a workspace's `_claude/config/` directory to the current project's `.claude/` directory via symlinks.

## Features

- **Workspace Auto-Detection** — Automatically detects the parent workspace (GitHubWork / GitHubPrivate) from the project path
- **Relative Symlinks** — Always creates relative symlinks for portability; never uses absolute paths
- **Safe Overwrites** — Prompts for confirmation before overwriting existing files
- **Directory Creation** — Asks before creating missing config directories
- **Link Status Display** — Shows current state of each file: linked, unlinked, or linked elsewhere
- **Summary Report** — Outputs a summary of all link operations performed

## Usage

```
/g-sync-config
```

## How It Works

```
/g-sync-config
  → Step 1: Detect project context and parent workspace
  → Step 2: Verify source (_claude/config/) exists
  → Step 3: Select files to link
  → Step 4: Create symlinks (relative paths)
  → Step 5: Summary of results
```

### Expected Directory Structure

```
~/Documents/GitHubWork/              # Workspace
  _claude/config/                    # Shared config source
    settings.local.json
  project-a/.claude/                 # Project target
    settings.local.json → ../../_claude/config/settings.local.json
```

## Requirements

- Claude Code CLI
- Shared config files must exist in the workspace's `_claude/config/` directory

## License

MIT
