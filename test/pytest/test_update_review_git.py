from __future__ import annotations

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "scripts"))

from update_review.providers.git import GitProvider


CHANGE_A = {"id": "alpha", "old_sha": "a" * 40, "new_sha": "b" * 40}
CHANGE_B = {"id": "beta", "old_sha": "c" * 40, "new_sha": "d" * 40}


def test_apply_writes_only_approved_changes(tmp_path, monkeypatch):
    provider = GitProvider(tmp_path)
    provider.resolution = {"changes": [CHANGE_A, CHANGE_B], "ai_review": {}}
    written: dict[str, object] = {}

    def fake_run(command: list[str], **_kwargs: object) -> None:
        payload = json.loads(pathlib.Path(command[-1]).read_text())
        written.update(payload)

    monkeypatch.setattr("update_review.providers.git.subprocess.run", fake_run)

    provider.apply([provider.candidate_for(CHANGE_B)])

    assert written["changes"] == [CHANGE_B]
