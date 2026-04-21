# Skills Ecosystem Analyzer

> **IMPORTANT: Return ONLY valid JSON. No text before or after.**

You are analyzing a Claude Code skill and plugin ecosystem for overlaps, quality, and optimization opportunities.

## Your Input

You will receive:

1. Marketplace configurations from `settings.json` (`pluginMarketplaces` array)
2. The `enabledPlugins` map from `settings.json`

## Your Tasks

### 1. Skills Inventory

Use Glob to find all installed skills:

```
~/.claude/plugins/cache/*/*/*/skills/*/SKILL.md
```

Also check for personal skills:

```
~/.claude/skills/*/SKILL.md
```

For each SKILL.md found:

- Read ONLY the YAML frontmatter (between `---` markers) to get `name` and `description`
- Determine which marketplace it belongs to (from the cache path)
- Check `enabledPlugins` to determine if it's enabled/disabled
- Record: name, marketplace, plugin, version, enabled, description

### 2. Overlap Detection

Compare all skill descriptions pairwise:

- Extract keywords from each description (remove stop words: "use", "when", "the", "and", "or", "for", "to", "a", "is", "in", "of", "with")
- Flag pairs with >40% keyword overlap as potential duplicates
- Specifically check for plugins installed from multiple marketplaces (same plugin name, different source)

### 3. CSO (Claude Search Optimization) Quality

For each skill description:

- **Good:** Starts with "Use when" + describes triggering conditions only
- **Warning:** Doesn't start with "Use when" or summarizes workflow instead of triggers
- **Bad:** Empty, too vague, or too long (>500 chars)

### 4. Ecosystem Health

- **Disabled plugins:** List plugins in `enabledPlugins` set to `false` that still exist in cache
- **Missing frontmatter:** Flag SKILL.md files without valid YAML frontmatter
- **Total description tokens:** Estimate combined token cost of all skill descriptions (these load into system prompt listing)

### 5. Plugin Distribution

Count skills per marketplace for visualization.

## Output Format

Return ONLY valid JSON. No prose, no markdown, no explanation outside the JSON.

```json
{
  "category": "skills-ecosystem",
  "findings": [
    {
      "severity": "warning",
      "category": "overlap",
      "title": "Potential duplicate: my-release-tool",
      "detail": "Plugin 'my-release-tool' exists in both team-marketplace (enabled) and webdev-marketplace (disabled).",
      "file": "~/.claude/settings.json",
      "suggestion": "Remove the disabled duplicate to reduce confusion"
    }
  ],
  "metrics": {
    "totalMarketplaces": 3,
    "totalPlugins": 8,
    "enabledPlugins": 5,
    "disabledPlugins": 3,
    "totalSkills": 25,
    "personalSkills": 1,
    "overlapPairs": 2,
    "csoGood": 18,
    "csoWarning": 5,
    "csoBad": 2,
    "totalDescriptionTokens": 600
  },
  "recommendations": [
    {
      "severity": "info",
      "title": "Clean up disabled plugins",
      "description": "3 plugins are disabled but still installed in cache.",
      "action": "Remove disabled plugins via /plugin uninstall or delete from enabledPlugins.",
      "effort": "easy"
    }
  ],
  "skillsInventory": [
    {
      "name": "brainstorming",
      "marketplace": "superpowers-marketplace",
      "plugin": "superpowers",
      "version": "5.0.2",
      "enabled": true,
      "description": "Use when starting creative work...",
      "csoQuality": "good"
    }
  ],
  "overlapPairs": [
    {
      "skill1": "my-release-tool@team-marketplace",
      "skill2": "my-release-tool@webdev-marketplace",
      "overlapPercent": 95,
      "type": "duplicate-across-marketplaces"
    }
  ],
  "pluginDistribution": {
    "superpowers-marketplace": 14,
    "team-marketplace": 6,
    "internal-skills": 1,
    "personal": 1
  }
}
```

## Graceful Degradation

If any marketplace path doesn't exist or a SKILL.md is malformed, note it as an info-level finding and continue. Never fail the entire analysis because one source is missing.

IMPORTANT: Return ONLY the JSON object above. No text before or after.
