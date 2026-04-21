#!/usr/bin/env python3
"""
Agent Usage Analyzer for Claude Code session logs.

Parses JSONL session logs across all projects to extract:
- Agent delegation count and patterns per session
- Model distribution (parent and subagent)
- Parallel execution patterns and 3-cap compliance
- Codex CLI usage via Bash tool
- Per-project breakdown

Output: JSON to stdout.

Usage:
  python3 agent-usage-analyzer.py [--days N] [--max-sessions N] [--project-filter SUBSTR]
"""

import json
import glob
import os
import sys
import re
import argparse
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path


CLAUDE_DIR = Path.home() / ".claude"
PROJECTS_DIR = CLAUDE_DIR / "projects"

CODEX_PATTERNS = re.compile(
    r"\bcodex\b", re.IGNORECASE
)

FILE_EXT_PATTERN = re.compile(
    r"agent-[a-f0-9]+\.jsonl$"
)


def parse_args():
    parser = argparse.ArgumentParser(description="Analyze agent usage in Claude Code sessions")
    parser.add_argument("--days", type=int, default=30, help="Analyze sessions from last N days (default: 30)")
    parser.add_argument("--max-sessions", type=int, default=50, help="Max sessions per project (default: 50)")
    parser.add_argument("--project-filter", type=str, default=None, help="Filter projects by substring in path")
    return parser.parse_args()


def decode_project_path(encoded):
    """Convert encoded project dir name back to a short display name.

    The encoding replaces '/' with '-', but original paths may contain '-' too,
    so exact reconstruction is impossible. We extract the last meaningful segments.
    Example: -Users-al03155147-Documents-GitHubLine-one -> GitHubLine/one
    """
    parts = encoded.lstrip("-").split("-")
    # Try common path anchors; take everything after the anchor
    for anchor in ("Documents", "projects", "workspace", "github", "src"):
        try:
            idx = parts.index(anchor)
            result = "/".join(parts[idx + 1:])
            if result:
                return result
        except ValueError:
            continue
    # Fallback: last 4 segments for more context
    n = min(4, len(parts))
    return "/".join(parts[-n:]) if n > 0 else encoded


def get_session_files(project_dir, max_sessions, cutoff_ts):
    """Get JSONL session files sorted by mtime, filtered by cutoff."""
    files = []
    for f in glob.glob(str(project_dir / "*.jsonl")):
        mtime = os.path.getmtime(f)
        if mtime >= cutoff_ts:
            files.append((f, mtime))
    files.sort(key=lambda x: x[1], reverse=True)
    return [f for f, _ in files[:max_sessions]]


def get_subagent_files(project_dir, session_id):
    """Get all subagent JSONL files for a session."""
    sa_dir = project_dir / session_id / "subagents"
    if not sa_dir.exists():
        return []
    return glob.glob(str(sa_dir / "agent-*.jsonl"))


def extract_subagent_model(sa_file):
    """Extract the model used by a subagent from its log file."""
    try:
        with open(sa_file) as f:
            for line in f:
                d = json.loads(line.strip())
                if d.get("type") == "assistant":
                    msg = d.get("message", {})
                    if isinstance(msg, dict) and msg.get("model"):
                        return msg["model"]
    except (json.JSONDecodeError, IOError):
        pass
    return "unknown"


def analyze_session(session_file, project_dir):
    """Analyze a single session JSONL file for agent usage."""
    session_id = Path(session_file).stem
    result = {
        "sessionId": session_id,
        "agentCalls": [],
        "parallelBatches": [],
        "codexUsage": [],
        "parentModels": set(),
        "subagentModels": Counter(),
        "totalAgentCalls": 0,
        "totalTurns": 0,
        "timestamp": None,
        "warnings": [],
    }

    try:
        with open(session_file) as f:
            for line in f:
                try:
                    d = json.loads(line.strip())
                except json.JSONDecodeError:
                    continue

                msg_type = d.get("type")

                # Count user turns
                if msg_type == "user":
                    result["totalTurns"] += 1
                    if result["timestamp"] is None:
                        result["timestamp"] = d.get("timestamp")

                # Analyze assistant messages for Agent tool calls
                if msg_type != "assistant":
                    continue

                msg = d.get("message", {})
                if not isinstance(msg, dict):
                    continue

                parent_model = msg.get("model", "unknown")
                content = msg.get("content", [])
                if not isinstance(content, list):
                    continue

                # Collect Agent calls in this message
                batch_agents = []
                has_codex_bash = False

                for c in content:
                    if not isinstance(c, dict) or c.get("type") != "tool_use":
                        continue

                    tool_name = c.get("name", "")

                    # Check for Agent tool
                    if tool_name == "Agent":
                        inp = c.get("input", {})
                        agent_call = {
                            "description": inp.get("description", ""),
                            "subagentType": inp.get("subagent_type", "general-purpose"),
                            "requestedModel": inp.get("model"),
                            "runInBackground": inp.get("run_in_background", False),
                            "toolUseId": c.get("id", ""),
                        }
                        batch_agents.append(agent_call)
                        result["agentCalls"].append(agent_call)
                        result["parentModels"].add(parent_model)

                    # Check for Codex CLI in Bash
                    if tool_name == "Bash":
                        inp = c.get("input", {})
                        cmd = inp.get("command", "")
                        if CODEX_PATTERNS.search(cmd):
                            result["codexUsage"].append({
                                "command": cmd[:200],
                                "timestamp": d.get("timestamp"),
                            })

                # Record parallel batch
                if len(batch_agents) > 1:
                    result["parallelBatches"].append({
                        "count": len(batch_agents),
                        "agents": [a["description"] for a in batch_agents],
                        "timestamp": d.get("timestamp"),
                    })

    except IOError as e:
        result["warnings"].append({
            "type": "session_read_error",
            "file": session_file,
            "error": str(e),
        })

    result["totalAgentCalls"] = len(result["agentCalls"])

    # Analyze subagent logs for actual models used
    sa_files = get_subagent_files(project_dir, session_id)
    for sa_file in sa_files:
        model = extract_subagent_model(sa_file)
        result["subagentModels"][model] += 1

    # Convert sets to lists for JSON
    result["parentModels"] = list(result["parentModels"])
    result["subagentModels"] = dict(result["subagentModels"])

    return result


def check_guidelines_compliance(session_result):
    """Check agent-guidelines.md compliance for a session."""
    violations = []

    # Check parallel cap (max 3)
    for batch in session_result["parallelBatches"]:
        if batch["count"] > 3:
            violations.append({
                "rule": "PARALLEL_CAP_EXCEEDED",
                "detail": f"Dispatched {batch['count']} agents in parallel (max 3)",
                "agents": batch["agents"],
                "timestamp": batch.get("timestamp"),
            })

    # Check model: subagents should use sonnet by default, not opus
    for model, count in session_result["subagentModels"].items():
        if "opus" in model.lower():
            violations.append({
                "rule": "SUBAGENT_OPUS_WITHOUT_ESCALATION",
                "detail": f"Subagent used opus ({model}) {count} time(s) — should default to sonnet",
                "count": count,
            })

    return violations


def analyze_project(project_dir, max_sessions, cutoff_ts):
    """Analyze all sessions in a project directory."""
    encoded_name = project_dir.name
    readable_path = decode_project_path(encoded_name)

    session_files = get_session_files(project_dir, max_sessions, cutoff_ts)
    if not session_files:
        return None

    sessions = []
    total_agent_calls = 0
    total_codex_calls = 0
    all_subagent_models = Counter()
    all_parent_models = Counter()
    all_violations = []
    all_warnings = []
    parallel_batches_total = 0
    max_parallel = 0

    for sf in session_files:
        sr = analyze_session(sf, project_dir)
        all_warnings.extend(sr.get("warnings", []))
        if sr["totalAgentCalls"] > 0 or sr["codexUsage"]:
            sessions.append({
                "sessionId": sr["sessionId"][:12] + "...",
                "turns": sr["totalTurns"],
                "agentCalls": sr["totalAgentCalls"],
                "parallelBatches": len(sr["parallelBatches"]),
                "codexCalls": len(sr["codexUsage"]),
                "subagentModels": sr["subagentModels"],
                "violations": check_guidelines_compliance(sr),
                "timestamp": sr["timestamp"],
            })
            total_agent_calls += sr["totalAgentCalls"]
            total_codex_calls += len(sr["codexUsage"])
            for m, c in sr["subagentModels"].items():
                all_subagent_models[m] += c
            for m in sr["parentModels"]:
                all_parent_models[m] += 1
            all_violations.extend(check_guidelines_compliance(sr))
            parallel_batches_total += len(sr["parallelBatches"])
            for batch in sr["parallelBatches"]:
                max_parallel = max(max_parallel, batch["count"])

    if not sessions:
        return None

    return {
        "project": readable_path,
        "encodedName": encoded_name,
        "sessionsAnalyzed": len(session_files),
        "sessionsWithAgents": len(sessions),
        "totalAgentCalls": total_agent_calls,
        "totalCodexCalls": total_codex_calls,
        "parallelBatchesTotal": parallel_batches_total,
        "maxParallelInBatch": max_parallel,
        "subagentModels": dict(all_subagent_models),
        "parentModels": dict(all_parent_models),
        "violations": all_violations,
        "warnings": all_warnings,
        "sessions": sessions,
    }


def main():
    args = parse_args()

    if not PROJECTS_DIR.exists():
        json.dump({"error": "No projects directory found", "path": str(PROJECTS_DIR)}, sys.stdout, indent=2)
        return

    cutoff = datetime.now(timezone.utc) - timedelta(days=args.days)
    cutoff_ts = cutoff.timestamp()

    projects = []
    global_stats = {
        "totalProjects": 0,
        "totalSessions": 0,
        "totalAgentCalls": 0,
        "totalCodexCalls": 0,
        "subagentModels": Counter(),
        "parentModels": Counter(),
        "totalViolations": 0,
        "violationsByRule": Counter(),
        "parallelCapCompliance": 0.0,
    }

    project_dirs = sorted(PROJECTS_DIR.iterdir())
    if args.project_filter:
        project_dirs = [p for p in project_dirs if args.project_filter in p.name]

    total_parallel_batches = 0

    for project_dir in project_dirs:
        if not project_dir.is_dir():
            continue

        result = analyze_project(project_dir, args.max_sessions, cutoff_ts)
        if result is None:
            continue

        projects.append(result)
        global_stats["totalProjects"] += 1
        global_stats["totalSessions"] += result["sessionsWithAgents"]
        global_stats["totalAgentCalls"] += result["totalAgentCalls"]
        global_stats["totalCodexCalls"] += result["totalCodexCalls"]
        for m, c in result["subagentModels"].items():
            global_stats["subagentModels"][m] += c
        for m, c in result["parentModels"].items():
            global_stats["parentModels"][m] += c
        for v in result["violations"]:
            global_stats["totalViolations"] += 1
            global_stats["violationsByRule"][v["rule"]] += 1
        total_parallel_batches += result["parallelBatchesTotal"]

    # Calculate parallel cap compliance rate
    cap_violations = global_stats["violationsByRule"].get("PARALLEL_CAP_EXCEEDED", 0)
    if total_parallel_batches > 0:
        global_stats["parallelCapCompliance"] = round(
            (total_parallel_batches - cap_violations) / total_parallel_batches * 100, 1
        )
    else:
        global_stats["parallelCapCompliance"] = 100.0

    # Convert Counters to dicts for JSON
    global_stats["subagentModels"] = dict(global_stats["subagentModels"])
    global_stats["parentModels"] = dict(global_stats["parentModels"])
    global_stats["violationsByRule"] = dict(global_stats["violationsByRule"])

    output = {
        "category": "agent-usage",
        "analyzedAt": datetime.now(timezone.utc).isoformat(),
        "parameters": {
            "days": args.days,
            "maxSessionsPerProject": args.max_sessions,
            "projectFilter": args.project_filter,
        },
        "globalStats": global_stats,
        "projects": projects,
    }

    json.dump(output, sys.stdout, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
