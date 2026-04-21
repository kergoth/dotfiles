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


def test_darwin_install_tools_template_renders_valid_bash_and_invokes_codex_helper():
    override_data = {
        "osid": "darwin",
        "user_setup": True,
        "work": False,
        "secrets": False,
        "steamdeck": False,
        "paths": {
            "home_bins": [],
            "home_bins_windows": [],
            "system_bins_darwin": [],
            "system_bins_linux": [],
            "system_bins_freebsd": [],
            "system_bins_windows": [],
        },
        "git_lock": {
            "claude_code": "v2.1.114",
            "codex_cli": "rust-v0.122.0",
            "gh_pr_review": "v1.6.2",
            "distrobox": "1.8.1.2",
        },
        "fetch_lock": {
            "codex_macos_arm64_release": "74e6885e1a58d78f0249faed126eb6ab220f9ce34e7623f9e4108255035d61cc",
            "rusage": "270e10853812f6c650f0eb4773354070a398f41738b95c4cb9f7e2f918d4833b",
            "eget_installer": "0e64b8a3c13f531da005096cc364ac77835bda54276fedef6c62f3dbdc1ee919",
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

    assert "install-codex" in rendered

    syntax_check = subprocess.run(
        ["bash", "-n"],
        input=rendered,
        capture_output=True,
        text=True,
    )

    assert syntax_check.returncode == 0, syntax_check.stderr
