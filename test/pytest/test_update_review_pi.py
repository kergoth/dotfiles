from __future__ import annotations

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "scripts"))

from update_review.providers.pi import PiProvider

DATA = """\
pi_packages:
  - source: "npm:@sherif-fanous/pi-catppuccin@0.3.0"
  - source: "npm:pi-web-access@0.47.0"
  - source: "npm:pi-subagents@0.88.0"
    skills_exclude:
      - "skills/council-mode/SKILL.md"
  - source: "git:github.com/kergoth/pi-claude-bridge@53e797fba31c9d04fb5f068c9d4aa0c911543dd7"
"""


def make_root(tmp_path: pathlib.Path, data: str = DATA) -> pathlib.Path:
    root = tmp_path / "repo"
    path = root / "home/.chezmoidata/pi-extensions.yml"
    path.parent.mkdir(parents=True)
    path.write_text(data, encoding="utf-8")
    return root


def provider_with(root: pathlib.Path, latest: dict[str, str]) -> PiProvider:
    return PiProvider(root, fetch_latest=lambda name: latest.get(name, ""))


def test_resolve_reports_only_newer_versions(tmp_path):
    root = make_root(tmp_path)
    provider = provider_with(
        root,
        {"pi-web-access": "0.47.0", "pi-subagents": "0.89.0"},
    )

    candidates = provider.resolve()

    assert [(c.name, c.old_version, c.new_version) for c in candidates] == [
        ("pi-subagents", "0.88.0", "0.89.0")
    ]


def test_resolve_compares_versions_numerically(tmp_path):
    root = make_root(tmp_path, 'pi_packages:\n  - source: "npm:pi-web-access@0.9.0"\n')
    provider = provider_with(root, {"pi-web-access": "0.10.0"})

    assert [c.new_version for c in provider.resolve()] == ["0.10.0"]


def test_resolve_ignores_git_and_local_sources(tmp_path):
    root = make_root(tmp_path)
    provider = provider_with(
        root,
        {
            "github.com/kergoth/pi-claude-bridge": "9.9.9",
        },
    )

    assert provider.resolve() == []


def test_apply_rewrites_only_approved_versions(tmp_path):
    root = make_root(tmp_path)
    provider = provider_with(root, {"pi-subagents": "0.89.0"})
    candidates = provider.resolve()
    original = (root / "home/.chezmoidata/pi-extensions.yml").read_text(
        encoding="utf-8"
    )

    summaries = provider.apply(candidates)

    updated = (root / "home/.chezmoidata/pi-extensions.yml").read_text(encoding="utf-8")
    assert summaries == [
        {
            "id": "npm:pi-subagents@0.88.0",
            "name": "pi-subagents",
            "old_version": "0.88.0",
            "new_version": "0.89.0",
        }
    ]
    assert "npm:pi-subagents@0.89.0" in updated
    assert updated == original.replace(
        "npm:pi-subagents@0.88.0", "npm:pi-subagents@0.89.0"
    )
