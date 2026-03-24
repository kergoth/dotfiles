#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = ["rich"]
# ///

"""Show changes between two commits in a git repository."""

import argparse
import json
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse

from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

console = Console(stderr=True)
stdout_console = Console()


def parse_args():
    parser = argparse.ArgumentParser(
        description="Show changes between two commits in a git repository."
    )
    parser.add_argument("repo_url", help="Git repository URL")
    parser.add_argument("old_sha", help="Old commit SHA")
    parser.add_argument("new_sha", help="New commit SHA")
    parser.add_argument("--name", help="Human-friendly label for output headers")
    parser.add_argument("--diff", action="store_true", help="Include full file diff")
    parser.add_argument(
        "--diff-only",
        action="store_true",
        help="Show only the diff, skipping shortlog and AI review",
    )
    parser.add_argument("--no-ai", action="store_true", help="Skip AI summary")
    parser.add_argument("--ai-cmd", help="Override agent CLI detection")
    parser.add_argument(
        "--ref",
        default="main",
        help="Branch ref for bare clone fallback (default: main)",
    )
    parser.add_argument(
        "--cache-dir",
        type=Path,
        help="Directory for cached bare clones (default: .cache/git-clones/ in repo root)",
    )
    parser.add_argument(
        "--review-note",
        help="Context injected into the AI prompt (e.g. which items are installed)",
    )
    return parser.parse_args()


def is_github_repo(url: str) -> bool:
    """Check if URL is a GitHub repo (not a gist)."""
    parsed = urlparse(url)
    return parsed.hostname == "github.com" and "gist." not in parsed.hostname


def parse_github_owner_repo(url: str) -> tuple[str, str] | None:
    """Extract owner/repo from a GitHub URL."""
    parsed = urlparse(url)
    parts = parsed.path.strip("/").removesuffix(".git").split("/")
    if len(parts) >= 2:
        return parts[0], parts[1]
    return None


def fetch_via_github_api(repo_url: str, old_sha: str, new_sha: str) -> dict | None:
    """Fetch commit comparison via gh CLI. Returns parsed JSON or None on failure."""
    if not is_github_repo(repo_url):
        return None

    owner_repo = parse_github_owner_repo(repo_url)
    if not owner_repo:
        return None

    if not shutil.which("gh"):
        return None

    owner, repo = owner_repo
    try:
        result = subprocess.run(
            ["gh", "api", f"repos/{owner}/{repo}/compare/{old_sha}...{new_sha}"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            return None
        return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError):
        return None


def get_cache_dir(explicit: Path | None) -> Path:
    """Determine cache directory for bare clones."""
    if explicit:
        return explicit
    # Walk up from script location to find repo root
    script_dir = Path(__file__).resolve().parent.parent
    return script_dir / ".cache" / "git-clones"


def fetch_via_bare_clone(
    repo_url: str,
    old_sha: str,
    new_sha: str,
    name: str | None,
    ref: str,
    cache_dir: Path,
) -> dict | None:
    """Fetch data via cached bare clone. Returns dict with 'log', 'shortlog', 'diff' keys."""
    clone_id = name or repo_url.split("/")[-1].removesuffix(".git")
    clone_path = cache_dir / clone_id

    console.print(
        f"Note: using cached clone for {name or clone_id} ({clone_path}/)",
        style="dim",
    )

    try:
        if clone_path.exists():
            subprocess.run(
                ["git", "-C", str(clone_path), "fetch", "origin"],
                capture_output=True,
                check=True,
                timeout=60,
            )
        else:
            clone_path.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                [
                    "git",
                    "clone",
                    "--bare",
                    "--single-branch",
                    "--branch",
                    ref,
                    repo_url,
                    str(clone_path),
                ],
                capture_output=True,
                check=True,
                timeout=120,
            )

        log_result = subprocess.run(
            ["git", "-C", str(clone_path), "log", "--oneline", f"{old_sha}..{new_sha}"],
            capture_output=True,
            text=True,
            check=True,
        )
        shortlog_result = subprocess.run(
            ["git", "-C", str(clone_path), "shortlog", f"{old_sha}..{new_sha}"],
            capture_output=True,
            text=True,
        )
        diff_result = subprocess.run(
            ["git", "-C", str(clone_path), "diff", old_sha, new_sha],
            capture_output=True,
            text=True,
        )

        return {
            "log": log_result.stdout.strip(),
            "shortlog": shortlog_result.stdout.strip(),
            "diff": diff_result.stdout.strip(),
        }
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError) as exc:
        console.print(
            f"Warning: bare clone failed for {name or clone_id}: {exc}", style="yellow"
        )
        return None


def fetch_changes(
    repo_url: str,
    old_sha: str,
    new_sha: str,
    name: str | None,
    ref: str,
    cache_dir: Path,
) -> dict | None:
    """Fetch changes via GitHub API or bare clone fallback.

    Returns dict with 'log', 'shortlog', 'diff' keys, or None on total failure.
    """
    # Try GitHub API first for non-gist GitHub repos
    api_data = fetch_via_github_api(repo_url, old_sha, new_sha)
    if api_data is not None:
        commits = api_data.get("commits", [])
        log_lines = [
            f"{c['sha'][:7]} {c['commit']['message'].splitlines()[0]}" for c in commits
        ]
        # Build shortlog (group by author)
        by_author: dict[str, list[str]] = {}
        for c in commits:
            author = c["commit"]["author"]["name"]
            msg = c["commit"]["message"].splitlines()[0]
            by_author.setdefault(author, []).append(msg)
        shortlog_lines = []
        for author, msgs in by_author.items():
            shortlog_lines.append(f"{author} ({len(msgs)}):")
            for msg in msgs:
                shortlog_lines.append(f"      {msg}")
            shortlog_lines.append("")

        diff_text = api_data.get("diff", "")
        # gh api returns patch format; fetch raw diff if needed
        if not diff_text:
            owner_repo = parse_github_owner_repo(repo_url)
            if owner_repo:
                owner, repo = owner_repo
                diff_result = subprocess.run(
                    [
                        "gh",
                        "api",
                        f"repos/{owner}/{repo}/compare/{old_sha}...{new_sha}",
                        "-H",
                        "Accept: application/vnd.github.diff",
                    ],
                    capture_output=True,
                    text=True,
                )
                if diff_result.returncode == 0:
                    diff_text = diff_result.stdout

        return {
            "log": "\n".join(log_lines),
            "shortlog": "\n".join(shortlog_lines),
            "diff": diff_text,
        }

    # Fallback to bare clone
    return fetch_via_bare_clone(repo_url, old_sha, new_sha, name, ref, cache_dir)


AGENT_CLIS = ["codex", "claude", "agent"]

SUPPLY_CHAIN_PROMPT = """\
Analyze the following git changes for a software dependency update.
Focus on:
1. Behavioral changes — what does this update DO differently?
2. Supply chain risk flags — new network calls, credential access, obfuscated code,
   unexpected binary files, new dependencies, changes to build/install scripts
3. Breaking changes requiring user action

Be concise. Flag only genuine concerns, not stylistic changes.
{review_context}
--- GIT LOG ---
{log}

--- GIT DIFF ---
{diff}
"""


def find_agent_cli(override: str | None = None) -> str | None:
    """Find the first available agent CLI."""
    if override:
        if shutil.which(override):
            return override
        return None
    for cli in AGENT_CLIS:
        if shutil.which(cli):
            return cli
    return None


def run_ai_review(
    agent_cmd: str,
    log: str,
    diff: str,
    name: str | None,
    review_note: str | None = None,
) -> str | None:
    """Run AI agent to produce a supply chain review summary."""
    review_context = f"--- REVIEW CONTEXT ---\n{review_note}\n\n" if review_note else ""
    prompt = SUPPLY_CHAIN_PROMPT.format(
        log=log, diff=diff, review_context=review_context
    )

    try:
        if agent_cmd == "claude":
            result = subprocess.run(
                ["claude", "--print", "--no-session-persistence", prompt],
                capture_output=True,
                text=True,
                timeout=120,
            )
        elif agent_cmd == "codex":
            result = subprocess.run(
                ["codex", "exec", "--ephemeral", prompt],
                capture_output=True,
                text=True,
                timeout=120,
            )
        elif agent_cmd == "agent":
            result = subprocess.run(
                ["agent", "-m", prompt],
                capture_output=True,
                text=True,
                timeout=120,
            )
        else:
            return None

        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
        return None
    except (subprocess.TimeoutExpired, OSError):
        console.print(
            f"Warning: AI review timed out for {name or 'unknown'}", style="yellow"
        )
        return None


def render_changes(
    name: str | None,
    old_sha: str,
    new_sha: str,
    data: dict,
    show_diff: bool = False,
    ai_cmd: str | None = None,
    skip_log: bool = False,
    skip_ai: bool = False,
    review_note: str | None = None,
):
    """Render the tiered review output."""
    label = name or "unknown"
    header = f"{label}: {old_sha[:7]} → {new_sha[:7]}"

    # Tier 1: Shortlog (always)
    if not skip_log:
        shortlog = data.get("shortlog") or data.get("log", "(no commits found)")
        stdout_console.print(
            Panel(shortlog, title=f"[bold]{header}[/bold]", subtitle="shortlog")
        )

    # Tier 2: AI-generated review (if available)
    if not skip_ai:
        agent = find_agent_cli(ai_cmd)
        if agent:
            console.print(f"Running AI review via {agent}...", style="dim")
            review = run_ai_review(
                agent, data.get("log", ""), data.get("diff", ""), name, review_note
            )
            if review:
                stdout_console.print(
                    Panel(
                        review,
                        title=f"[bold]AI Review — {label}[/bold]",
                        subtitle=agent,
                    )
                )
            else:
                console.print(f"AI review produced no output for {label}", style="dim")
        else:
            console.print(
                "(no AI agent available for summary — showing shortlog only)",
                style="dim",
            )

    # Tier 3: Full diff (opt-in)
    if show_diff and data.get("diff"):
        stdout_console.print(
            Panel(
                Syntax(data["diff"], "diff", theme="monokai", line_numbers=True),
                title=f"[bold]Diff — {label}[/bold]",
            )
        )


def main():
    args = parse_args()
    cache_dir = get_cache_dir(args.cache_dir)

    data = fetch_changes(
        args.repo_url, args.old_sha, args.new_sha, args.name, args.ref, cache_dir
    )
    if data is None:
        console.print(
            f"Error: could not fetch changes for {args.name or args.repo_url}",
            style="red",
        )
        return 1

    render_changes(
        name=args.name,
        old_sha=args.old_sha,
        new_sha=args.new_sha,
        data=data,
        show_diff=args.diff or args.diff_only,
        ai_cmd=args.ai_cmd,
        skip_ai=args.no_ai or args.diff_only,
        skip_log=args.diff_only,
        review_note=args.review_note,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
