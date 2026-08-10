import importlib.util
import json
import pathlib
import sys
import types
from unittest.mock import patch


def _make_rich_stubs():
    rich = types.ModuleType("rich")
    console_mod = types.ModuleType("rich.console")
    panel_mod = types.ModuleType("rich.panel")
    syntax_mod = types.ModuleType("rich.syntax")

    class _FakeConsole:
        def __init__(self, *a, **kw):
            pass

        def print(self, *a, **kw):
            pass

    class _FakePanel:
        def __init__(self, *a, **kw):
            pass

    class _FakeSyntax:
        def __init__(self, *a, **kw):
            pass

    console_mod.Console = _FakeConsole
    panel_mod.Panel = _FakePanel
    syntax_mod.Syntax = _FakeSyntax
    return rich, console_mod, panel_mod, syntax_mod


_rich, _rc, _rp, _rs = _make_rich_stubs()
_stubs = {"rich": _rich, "rich.console": _rc, "rich.panel": _rp, "rich.syntax": _rs}

_spec = importlib.util.spec_from_file_location(
    "show_git_changes",
    pathlib.Path(__file__).parent.parent.parent / "scripts" / "show-git-changes.py",
)
assert _spec is not None and _spec.loader is not None
_mod = importlib.util.module_from_spec(_spec)
_prev = {k: sys.modules.get(k) for k in _stubs}
sys.modules.update(_stubs)
try:
    _spec.loader.exec_module(_mod)
finally:
    for k, v in _prev.items():
        if v is None:
            sys.modules.pop(k, None)
        else:
            sys.modules[k] = v

import pytest


class TestLoadAiConfig:
    def test_known_agents(self):
        assert getattr(_mod, "KNOWN_AGENTS", set()) == {"claude", "codex", "agent", "qwen", "pi"}

    def test_none_returns_empty(self):
        assert _mod.load_ai_config(None) == {}

    def test_empty_string_returns_empty(self):
        assert _mod.load_ai_config("") == {}

    def test_empty_object_returns_empty(self):
        assert _mod.load_ai_config("{}") == {}

    def test_valid_config(self):
        cfg = {"fallback_chain": ["claude"], "agents": {"claude": {"timeout": 120}}}
        result = _mod.load_ai_config(json.dumps(cfg))
        assert result == cfg

    def test_malformed_json_raises(self):
        with pytest.raises(SystemExit):
            _mod.load_ai_config("{bad json")

    def test_non_object_json_raises(self):
        with pytest.raises(SystemExit):
            _mod.load_ai_config("[1, 2, 3]")

    def test_unknown_agent_in_chain_raises(self):
        cfg = {"fallback_chain": ["claude", "unknown_agent"]}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_unknown_agent_in_agents_dict_raises(self):
        cfg = {"agents": {"unknown_agent": {"timeout": 120}}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_zero_timeout_raises(self):
        cfg = {"agents": {"claude": {"timeout": 0}}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_negative_timeout_raises(self):
        cfg = {"agents": {"claude": {"timeout": -5}}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_zero_fallback_timeout_raises(self):
        cfg = {"fallback_timeout": 0}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_negative_model_timeout_raises(self):
        cfg = {"agents": {"claude": {"timeout": 120, "model_timeouts": {"opus": -1}}}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_fallback_chain_not_list_raises(self):
        cfg = {"fallback_chain": "claude"}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_agents_not_dict_raises(self):
        cfg = {"agents": ["claude"]}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_agent_entry_not_dict_raises(self):
        cfg = {"agents": {"claude": "bad"}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_boolean_timeout_raises(self):
        cfg = {"agents": {"claude": {"timeout": True}}}
        with pytest.raises(SystemExit):
            _mod.load_ai_config(json.dumps(cfg))

    def test_config_with_all_fields(self):
        cfg = {
            "fallback_chain": ["claude", "codex", "pi"],
            "fallback_timeout": 480,
            "agents": {
                "claude": {"model": "sonnet", "timeout": 120, "model_timeouts": {"opus": 300}},
                "pi": {"timeout": 120, "model_timeouts": {"local": 60}},
            },
        }
        result = _mod.load_ai_config(json.dumps(cfg))
        assert result == cfg


class TestResolveTimeout:
    FULL_CONFIG = {
        "fallback_timeout": 480,
        "agents": {
            "claude": {"timeout": 120, "model_timeouts": {"opus": 300}},
            "pi": {"timeout": 120, "model_timeouts": {"local": 60}},
        },
    }

    def test_cli_override_wins(self):
        assert _mod.resolve_timeout("claude", "sonnet", 999, self.FULL_CONFIG) == 999

    def test_model_timeout_override(self):
        assert _mod.resolve_timeout("claude", "opus", None, self.FULL_CONFIG) == 300

    def test_agent_default_timeout(self):
        assert _mod.resolve_timeout("claude", "sonnet", None, self.FULL_CONFIG) == 120

    def test_agent_no_model_uses_agent_timeout(self):
        assert _mod.resolve_timeout("claude", None, None, self.FULL_CONFIG) == 120

    def test_fallback_timeout_for_unknown_agent(self):
        assert _mod.resolve_timeout("codex", None, None, self.FULL_CONFIG) == 480

    def test_hardcoded_fallback_no_config(self):
        result = _mod.resolve_timeout("claude", None, None, {})
        assert result == _mod.AGENT_DEFAULT_TIMEOUTS["claude"]

    def test_model_timeout_not_present_falls_to_agent(self):
        assert _mod.resolve_timeout("claude", "haiku", None, self.FULL_CONFIG) == 120

    def test_cli_none_does_not_override(self):
        assert _mod.resolve_timeout("pi", "local", None, self.FULL_CONFIG) == 60


class TestResolveModel:
    CONFIG = {
        "agents": {
            "claude": {"model": "sonnet"},
            "codex": {},
        },
    }

    def test_cli_model_for_preferred_agent(self):
        assert _mod.resolve_model("claude", "opus", self.CONFIG, is_preferred=True) == "opus"

    def test_cli_model_ignored_for_fallback_agent(self):
        assert _mod.resolve_model("claude", "opus", self.CONFIG, is_preferred=False) == "sonnet"

    def test_config_model(self):
        assert _mod.resolve_model("claude", None, self.CONFIG, is_preferred=False) == "sonnet"

    def test_no_config_model_returns_none(self):
        assert _mod.resolve_model("codex", None, self.CONFIG, is_preferred=False) is None

    def test_empty_config_returns_none(self):
        assert _mod.resolve_model("claude", None, {}, is_preferred=False) is None

    def test_agent_not_in_config_returns_none(self):
        assert _mod.resolve_model("qwen", None, self.CONFIG, is_preferred=False) is None


class TestGetCandidates:
    CONFIG = {"fallback_chain": ["claude", "codex", "pi"]}

    def test_chain_filtered_by_path(self):
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}" if x in ("claude", "pi") else None):
            result = _mod.get_candidates(None, self.CONFIG, "test-source")
        assert result == ["claude", "pi"]

    def test_preferred_agent_prepended(self):
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}" if x in ("claude", "codex") else None):
            result = _mod.get_candidates("codex", self.CONFIG, "test-source")
        assert result == ["codex", "claude"]

    def test_preferred_agent_deduplicated(self):
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}"):
            result = _mod.get_candidates("claude", self.CONFIG, "test-source")
        assert result == ["claude", "codex", "pi"]
        assert result.count("claude") == 1

    def test_missing_preferred_agent_warns_and_continues(self):
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}" if x != "qwen" else None):
            result = _mod.get_candidates("qwen", self.CONFIG, "test-source")
        assert "qwen" not in result
        assert result == ["claude", "codex", "pi"]

    def test_no_config_uses_hardcoded(self):
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}"):
            result = _mod.get_candidates(None, {}, "test-source")
        assert result == _mod.AGENT_CLIS

    def test_empty_chain_no_agents_available(self):
        with patch("shutil.which", return_value=None):
            result = _mod.get_candidates(None, self.CONFIG, "test-source")
        assert result == []

    def test_explicit_empty_chain_does_not_use_hardcoded(self):
        """fallback_chain: [] means no agents, NOT fallback to AGENT_CLIS."""
        config = {"fallback_chain": []}
        with patch("shutil.which", side_effect=lambda x: f"/usr/bin/{x}"):
            result = _mod.get_candidates(None, config, "test-source")
        assert result == []
