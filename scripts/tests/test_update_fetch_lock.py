import importlib.util
import pathlib


spec = importlib.util.spec_from_file_location(
    "update_fetch_lock",
    pathlib.Path(__file__).parent.parent / "update-fetch-lock.py",
)
assert spec is not None and spec.loader is not None
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

resolve_url = mod.resolve_url


def test_resolve_url_without_version_source_returns_template_as_is():
    data = {"git_lock": {"kitty": "v0.46.2"}}
    source = {"url_template": "https://example.invalid/plain-installer.sh"}

    assert resolve_url(data, source) == "https://example.invalid/plain-installer.sh"


def test_resolve_url_with_version_source_preserves_version_by_default():
    data = {"git_lock": {"zed": "v0.228.0"}}
    source = {
        "url_template": "https://example.invalid/{version}/install.sh",
        "version_source": "git_lock.zed",
    }

    assert resolve_url(data, source) == "https://example.invalid/v0.228.0/install.sh"


def test_resolve_url_with_version_source_preserves_kitty_tag():
    data = {"git_lock": {"kitty": "v0.46.2"}}
    source = {
        "url_template": "https://example.invalid/installer.sh?version={version}",
        "version_source": "git_lock.kitty",
    }

    assert (
        resolve_url(data, source)
        == "https://example.invalid/installer.sh?version=v0.46.2"
    )


def test_resolve_url_with_version_no_v_trims_leading_v():
    data = {"git_lock": {"kitty": "v0.46.2"}}
    source = {
        "url_template": "https://example.invalid/installer.sh?version={version_no_v}",
        "version_source": "git_lock.kitty",
    }

    assert (
        resolve_url(data, source)
        == "https://example.invalid/installer.sh?version=0.46.2"
    )


def test_resolve_url_with_version_source_but_no_placeholder_fails():
    data = {"git_lock": {"kitty": "v0.46.2"}}
    source = {
        "url_template": "https://example.invalid/plain-installer.sh",
        "version_source": "git_lock.kitty",
    }

    try:
        resolve_url(data, source)
        assert False, "resolve_url should reject version_source without {version}"
    except ValueError as exc:
        assert (
            str(exc)
            == "version_source requires {version} or {version_no_v} in url_template"
        )
