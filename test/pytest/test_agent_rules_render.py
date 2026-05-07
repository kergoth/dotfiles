import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATES = [
    ROOT / "home/dot_codex/AGENTS.md.tmpl",
    ROOT / "home/dot_claude/CLAUDE.md.tmpl",
    ROOT / "home/dot_cursor/rules/agent-rules.mdc.tmpl",
]


def render_template(template: pathlib.Path) -> str:
    return subprocess.run(
        ["chezmoi", "execute-template", "--file", str(template)],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def content_lines_without_frontmatter(rendered: str) -> list[str]:
    lines = rendered.splitlines()
    i = 0

    # Skip optional YAML frontmatter.
    if i < len(lines) and lines[i].strip() == "---":
        i += 1
        while i < len(lines) and lines[i].strip() != "---":
            i += 1
        if i < len(lines):
            i += 1

    while i < len(lines) and not lines[i].strip():
        i += 1

    return lines[i:]


def test_agent_rules_render_without_top_level_h1():
    for template in TEMPLATES:
        rendered = render_template(template)
        lines = content_lines_without_frontmatter(rendered)
        top_level_headings = [
            line for line in lines if line.startswith("# ")
        ]
        assert not top_level_headings, (
            f"expected no top-level headings in merged rules for {template}, "
            f"got: {top_level_headings!r}"
        )
