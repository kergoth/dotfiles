import json
import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "settings/pi/settings.json.tmpl"
BRIDGE_SHA = "53e797fba31c9d04fb5f068c9d4aa0c911543dd7"
PI_PACKAGES = [
    {"source": "npm:@sherif-fanous/pi-catppuccin@0.3.0"},
    {"source": "npm:@sherif-fanous/pi-dracula@0.3.0"},
    {"source": "npm:@anthropic-ai/claude-agent-sdk@0.3.322"},
    {"source": "npm:pi-web-access@0.47.0"},
    {
        "source": "npm:pi-subagents@0.88.0",
        "skills_exclude": ["skills/council-mode/SKILL.md"],
    },
    {"source": "npm:pi-cursor-sdk@0.5.46", "when": "work"},
]


def render(*, work: bool) -> dict:
    override_data = {
        "work": work,
        "personal": not work,
        "git_lock": {"pi_claude_bridge": BRIDGE_SHA},
        "pi_packages": PI_PACKAGES,
        "chezmoi": {"homeDir": "/home/tester"},
    }
    rendered = subprocess.run(
        [
            "chezmoi",
            "execute-template",
            "--file",
            "--override-data",
            json.dumps(override_data),
            str(TEMPLATE),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return json.loads(rendered)


def test_skills_exclude_renders_object_form():
    packages = render(work=False)["packages"]
    objects = [entry for entry in packages if isinstance(entry, dict)]
    assert objects == [
        {
            "skills": ["-skills/council-mode/SKILL.md"],
            "source": "npm:pi-subagents@0.88.0",
        }
    ]


def test_bridge_entry_interpolates_git_lock_sha():
    packages = render(work=False)["packages"]
    bridge = [entry for entry in packages if isinstance(entry, str) and "pi-claude-bridge" in entry]
    assert bridge == [f"git:github.com/kergoth/pi-claude-bridge@{BRIDGE_SHA}"]


def test_work_only_entry_is_gated():
    work_sources = [
        entry if isinstance(entry, str) else entry["source"]
        for entry in render(work=True)["packages"]
    ]
    personal_sources = [
        entry if isinstance(entry, str) else entry["source"]
        for entry in render(work=False)["packages"]
    ]
    assert any("pi-cursor-sdk" in source for source in work_sources)
    assert not any("pi-cursor-sdk" in source for source in personal_sources)
