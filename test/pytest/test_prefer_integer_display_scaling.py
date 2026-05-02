from __future__ import annotations

from dataclasses import dataclass
import importlib.util
import io
import pathlib
from contextlib import redirect_stdout
import sys
import types


SCRIPT = (
    pathlib.Path(__file__).resolve().parents[2]
    / "scripts"
    / "macos"
    / "prefer-integer-display-scaling.py"
)


def _load_module():
    quartz_stub = types.SimpleNamespace(CGMainDisplayID=lambda: 0)
    previous = sys.modules.get("Quartz")
    previous_target = sys.modules.get("set_resolution_scale_2")
    sys.modules["Quartz"] = quartz_stub
    try:
        spec = importlib.util.spec_from_file_location("set_resolution_scale_2", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module
    finally:
        if previous is None:
            del sys.modules["Quartz"]
        else:
            sys.modules["Quartz"] = previous
        if previous_target is None:
            del sys.modules["set_resolution_scale_2"]
        else:
            sys.modules["set_resolution_scale_2"] = previous_target


MODULE = _load_module()


@dataclass(frozen=True)
class FakeMode:
    width: int
    height: int
    pixel_width: int
    pixel_height: int
    refresh: int = 60
    io_flags: int = 0

    @property
    def scale_x(self) -> float:
        return self.pixel_width / self.width

    @property
    def scale_y(self) -> float:
        return self.pixel_height / self.height


def make_mode(width: int, height: int, pixel_width: int, pixel_height: int) -> FakeMode:
    return FakeMode(
        width=width,
        height=height,
        pixel_width=pixel_width,
        pixel_height=pixel_height,
    )


def test_choose_mode_leaves_integer_backed_current_mode_unchanged() -> None:
    current = make_mode(1512, 982, 3024, 1964)
    modes = [
        make_mode(1800, 1169, 3024, 1964),
        current,
        make_mode(1280, 832, 2560, 1664),
    ]

    assert MODULE.choose_replacement_mode(modes, current) is None


def test_choose_mode_rounds_fractional_mode_up_to_next_integer_candidate() -> None:
    current = make_mode(1800, 1169, 3024, 1964)
    larger_integer = make_mode(1512, 982, 3024, 1964)
    smaller_integer = make_mode(1008, 655, 3024, 1964)
    modes = [
        current,
        larger_integer,
        smaller_integer,
    ]

    selected = MODULE.choose_replacement_mode(modes, current)

    assert selected == larger_integer


def test_choose_mode_returns_none_when_no_clear_integer_candidate_exists() -> None:
    current = make_mode(1800, 1169, 3024, 1964)
    modes = [
        current,
        make_mode(1344, 873, 3024, 1964),
        make_mode(1180, 766, 3024, 1964),
    ]

    assert MODULE.choose_replacement_mode(modes, current) is None


def test_supports_current_macos_major_versions_only() -> None:
    assert MODULE.is_supported_macos_version("14.7.5") is True
    assert MODULE.is_supported_macos_version("15.3") is True
    assert MODULE.is_supported_macos_version("26.0") is True
    assert MODULE.is_supported_macos_version("13.7.4") is False


def test_analyze_display_prefers_next_larger_integer_mode() -> None:
    current = make_mode(1800, 1169, 3024, 1964)
    larger_integer = make_mode(1512, 982, 3024, 1964)
    smaller_integer = make_mode(1008, 655, 3024, 1964)

    decision = MODULE.analyze_display_modes(
        [current, larger_integer, smaller_integer],
        current,
    )

    assert decision.current == current
    assert decision.selected == larger_integer
    assert decision.matching_pixel_mode_count == 3
    assert decision.integer_candidate_count == 2


def test_main_dry_run_verbose_reports_no_change_without_applying(monkeypatch) -> None:
    current = make_mode(1512, 982, 3024, 1964)
    output = io.StringIO()

    monkeypatch.setattr(MODULE, "is_supported_macos_version", lambda version=None: True)
    monkeypatch.setattr(MODULE.Quartz, "CGMainDisplayID", lambda: 1)
    monkeypatch.setattr(MODULE, "get_main_display_modes", lambda display_id: ([current], current))
    monkeypatch.setattr(MODULE, "apply_mode", lambda display_id, mode: (_ for _ in ()).throw(AssertionError("apply_mode should not be called")))

    with redirect_stdout(output):
        rc = MODULE.main(["--dry-run", "--verbose"])

    assert rc == 0
    assert "current=1512x982 @ 3024x1964 (2.00x, integer-backed)" in output.getvalue()
    assert "matching-pixel-modes=1 integer-backed=1" in output.getvalue()
    assert "decision=no-change" in output.getvalue()


def test_main_verbose_applies_selected_mode(monkeypatch) -> None:
    current = make_mode(1800, 1169, 3024, 1964)
    replacement = make_mode(1512, 982, 3024, 1964)
    applied: list[tuple[int, FakeMode]] = []
    output = io.StringIO()

    monkeypatch.setattr(MODULE, "is_supported_macos_version", lambda version=None: True)
    monkeypatch.setattr(MODULE.Quartz, "CGMainDisplayID", lambda: 7)
    monkeypatch.setattr(
        MODULE,
        "get_main_display_modes",
        lambda display_id: ([current, replacement], current),
    )
    monkeypatch.setattr(
        MODULE,
        "apply_mode",
        lambda display_id, mode: applied.append((display_id, mode)),
    )

    with redirect_stdout(output):
        rc = MODULE.main(["--verbose"])

    assert rc == 0
    assert applied == [(7, replacement)]
    assert "decision=apply 1512x982 @ 3024x1964 (2.00x)" in output.getvalue()
