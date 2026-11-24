import json
import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "home/dot_pi/private_agent/modify_settings.json"

LIVE_SETTINGS = {
    "packages": [
        "npm:pi-web-access",
        "npm:pi-subagents",
        "npm:@sherif-fanous/pi-dracula",
    ],
    "liveOnly": {"a": 1},
}


def package_key(entry: str | dict) -> str:
    source = entry if isinstance(entry, str) else entry["source"]
    for prefix in ("npm:", "git:"):
        source = source.removeprefix(prefix)
    head, separator, tail = source.rpartition("@")
    if separator and head and "@" not in head.rsplit("/", 1)[-1]:
        return head
    return source


PINS = [
    {"source": "npm:@sherif-fanous/pi-catppuccin@0.3.0"},
    {"source": "npm:@sherif-fanous/pi-dracula@0.3.0"},
    {"source": "npm:@anthropic-ai/claude-agent-sdk@0.3.322"},
    {"source": "npm:pi-web-access@0.47.0"},
    {
        "source": "npm:pi-subagents@0.88.0",
        "skills_exclude": ["skills/council-mode/SKILL.md"],
    },
]


def render() -> dict:
    rendered = subprocess.run(
        [
            "chezmoi",
            "execute-template",
            "--file",
            "--with-stdin",
            "--override-data",
            json.dumps(
                {
                    "work": False,
                    "personal": True,
                    "pi_packages": PINS,
                    "git_lock": {
                        "pi_claude_bridge": "53e797fba31c9d04fb5f068c9d4aa0c911543dd7"
                    },
                }
            ),
            str(TEMPLATE),
        ],
        cwd=ROOT,
        input=json.dumps(LIVE_SETTINGS),
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return json.loads(rendered)


def test_live_unversioned_entries_collapse_into_managed_pins():
    keys = [package_key(entry) for entry in render()["packages"]]
    assert len(keys) == len(set(keys))
    assert sorted(keys) == [
        "@anthropic-ai/claude-agent-sdk",
        "@sherif-fanous/pi-catppuccin",
        "@sherif-fanous/pi-dracula",
        "github.com/kergoth/pi-claude-bridge",
        "pi-subagents",
        "pi-web-access",
    ]


def test_managed_pinned_entries_win_over_live_ones():
    by_key = {package_key(entry): entry for entry in render()["packages"]}
    assert by_key["pi-web-access"] == "npm:pi-web-access@0.47.0"
    assert by_key["pi-subagents"]["source"] == "npm:pi-subagents@0.88.0"
    assert by_key["@sherif-fanous/pi-dracula"] == "npm:@sherif-fanous/pi-dracula@0.3.0"


def test_live_only_keys_survive_the_merge():
    assert render()["liveOnly"] == {"a": 1}
