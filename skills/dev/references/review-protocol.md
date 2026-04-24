# Review Protocol

Standard review workflow for planning artifacts: PRD, TRD, and feature breakdown.
Loaded inline by plan.md, design.md, and breakdown.md at review time.

The calling step file specifies the **artifact** and **Codex focus**.

---

## 1. Mode Selection

Ask the user before proceeding:

```
Review mode:
  1) Plannotator visual review (default)
  2) Inline text review
  3) Skip

> Enter number
```

---

## 2. Review Execution

**Mode 1 — Plannotator:**
1. Check `plannotator` command availability.
2. If available: run `plannotator` on the artifact file.
3. If unavailable or launch fails:
   ```
   [WARN] Plannotator CLI unavailable — falling back to inline text review.
   Continue? (Y/n)
   ```
   - `n` → stay; let user choose retry or skip
   - `Y` (default) → fall back to inline text

**Mode 2 — Inline:** display artifact contents and prompt for feedback inline.

**Mode 3 — Skip:** proceed without review.

---

## 3. User Approval

- Wait for explicit approval.
- If revision requested: re-invoke the artifact-generating agent. Do NOT advance step.
- Repeat until approved.

---

## 4. Codex Cross-Review

Run automatically after user approval. No additional prompt needed.

**Invocation priority (try in order):**
1. `codex-plugin-cc`: `/codex:rescue "<codex-focus>: <artifact-path>"`
2. Codex CLI: `codex exec -c model_reasoning_effort="low" --read <artifact-path> "<codex-focus>"`
3. `code-reviewer` agent (model: sonnet) — if Codex unavailable; record fallback reason in `_state.json` history.

Present Codex findings → user decides whether to incorporate.
If incorporated: re-confirm user approval before advancing.
