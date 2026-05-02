import json
import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "home/.chezmoiscripts/darwin/run_onchange_after_30_configure-settings.tmpl"


def test_darwin_configure_settings_uses_local_quartz_helper_without_remote_fetch():
    override_data = {
        "osid": "darwin",
        "hostname": "vaelin",
        "chezmoi": {
            "hostname": "vaelin",
            "os": "darwin",
        },
        "ephemeral": False,
        "ui": {
            "global": {
                "macos": {
                    "dock_tilesize": 48,
                },
            },
        },
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

    assert "display_manager_lib.py" not in rendered
    assert "curl -Lfso" not in rendered
    assert "python3 -m venv" not in rendered
    assert "pip install pyobjc-core" not in rendered
    assert '"$CHEZMOI_WORKING_TREE/scripts/macos/prefer-integer-display-scaling.py"' in rendered
