# External Skill Wrapping

Two external skills are used by name only - never copy their content into
this repo (wrap, do not fork). Both are prompt-only skills: no scripts, no
MCP servers.

## Presence check (both)

Look for the skill name in the current session's available-skills list (the
skill inventory in the system prompt / system-reminder). Accepted names:

| Skill | Accepted names |
|---|---|
| frontend-design | `frontend-design`, `example-skills:frontend-design` |
| design-taste-frontend | `design-taste-frontend` |

Plugin-installed skills can carry an arbitrary namespace prefix (e.g.
`9d2f1ae18723:frontend-design`): a listed name preceded by any `<prefix>:`
counts as present; invoke it by the full prefixed name.

Name present -> invoke that skill (Claude: Skill tool; Codex: `$<name>`). Name absent -> print the matching
install block below, use the fallback, and continue; never guess at an
invocation. Newly installed skills appear only in NEW sessions - right after
installing, the current session still counts as absent.

## frontend-design

Aesthetic direction; used in step-3-design (candidate directions) and
step-5-build (per-screen co-design on UI tasks). Source:
github.com/anthropics/skills (Apache 2.0). Install commands (the user runs
these inside Claude Code; they are interactive commands, not shell):

```
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

Step 3: invoke BEFORE drafting architecture.md with the goal and
constraints as context; produce 2-3 candidate directions recorded as
candidates - the theme is finalized only after the user picks from
rendered samples. Step 5 UI task: re-invoke scoped to the task's screens;
trigger, context source, and the 3-round cap are defined in
`steps/step-5-build.md`.

Fallback when absent - produce 2-3 candidates inline in the UI Direction
section, each covering exactly these 4 points:

1. palette of 4-6 named values
2. two typeface roles (display, body)
3. one-sentence layout concept
4. one signature element that is not a generic template pattern

## design-taste-frontend

Implementation taste check; used in step-5-build for UI tasks. Source:
github.com/Leonxlnx/taste-skill (MIT). The default version is v2, labeled
experimental by its author; `design-taste-frontend-v1` is the stable pin.
Install (shell; run only with user approval):

```bash
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

Invoke AFTER a UI task's criteria pass, on the changed screens/components.
It assumes React/Next + Tailwind; on other stacks apply only its
stack-agnostic rules and state which parts were skipped.

Fallback when absent - write `taste check skipped: design-taste-frontend not
installed` in the task Log and run this 5-point manual check instead:

1. exactly one accent color on the page
2. no placeholder or fake content shipped (avatars, lorem ipsum)
3. motion respects prefers-reduced-motion
4. empty, loading, and error states exist for every async view
5. the signature element does not read as a template default

## Precedence

- A theme the user picked from rendered samples outranks both skills.
- Creative-direction conflicts -> frontend-design output wins.
- Mechanical or implementation-rule conflicts -> design-taste-frontend wins,
  EXCEPT against the repo's own lint/format config: the repo config always
  wins.
- Both skills auto-trigger on generic "build UI" phrasing; g-dev invokes
  each only at its designated steps, so do not let either fire outside
  those steps.
