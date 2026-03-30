import json
import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "home/.chezmoiscripts/posix/run_onchange_before_25_install-tools.tmpl"


def test_chimera_install_tools_template_renders_valid_bash():
    override_data = {
        "osid": "linux-chimera",
        "user_setup": True,
        "work": False,
        "secrets": False,
        "paths": {
            "home_bins": [],
            "home_bins_windows": [],
            "system_bins_darwin": [],
            "system_bins_linux": [],
            "system_bins_freebsd": [],
            "system_bins_windows": [],
        },
        "git_lock": {
            "claude_code": "v2.1.86",
            "gh_pr_review": "v1.6.2",
            "distrobox": "1.8.1.2",
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

    syntax_check = subprocess.run(
        ["bash", "-n"],
        input=rendered,
        capture_output=True,
        text=True,
    )

    assert syntax_check.returncode == 0, (
        "expected Chimera install-tools render to be valid bash, "
        f"got rc={syntax_check.returncode}: {syntax_check.stderr}\n"
        f"Rendered script:\n{rendered}"
    )
