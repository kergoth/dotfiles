#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pyobjc-core",
#   "pyobjc-framework-Quartz",
# ]
# ///

from __future__ import annotations

import argparse
from dataclasses import dataclass
import platform

import Quartz


@dataclass(frozen=True)
class ModeRecord:
    raw: object
    width: int
    height: int
    pixel_width: int
    pixel_height: int
    refresh: int
    io_flags: int

    @property
    def scale_x(self) -> float:
        return self.pixel_width / self.width

    @property
    def scale_y(self) -> float:
        return self.pixel_height / self.height


@dataclass(frozen=True)
class Decision:
    current: ModeRecord
    selected: ModeRecord | None
    matching_pixel_mode_count: int
    integer_candidate_count: int


def is_supported_macos_version(version: str | None = None) -> bool:
    if version is None:
        version = platform.mac_ver()[0]
    if not version:
        return False
    major = int(version.split(".", 1)[0])
    return major >= 14


def _is_near_integer(value: float, tolerance: float = 0.02) -> bool:
    return abs(value - round(value)) <= tolerance


def normalize_mode(mode: object) -> ModeRecord:
    return ModeRecord(
        raw=mode,
        width=int(Quartz.CGDisplayModeGetWidth(mode)),
        height=int(Quartz.CGDisplayModeGetHeight(mode)),
        pixel_width=int(Quartz.CGDisplayModeGetPixelWidth(mode)),
        pixel_height=int(Quartz.CGDisplayModeGetPixelHeight(mode)),
        refresh=int(Quartz.CGDisplayModeGetRefreshRate(mode)),
        io_flags=int(Quartz.CGDisplayModeGetIOFlags(mode)),
    )


def is_integer_backed_mode(mode: ModeRecord) -> bool:
    return _is_near_integer(mode.scale_x) and _is_near_integer(mode.scale_y)


def _ui_area(mode: ModeRecord) -> int:
    return mode.width * mode.height


def choose_replacement_mode(
    modes: list[ModeRecord],
    current: ModeRecord,
) -> ModeRecord | None:
    if is_integer_backed_mode(current):
        return None

    larger_integer_modes = [
        mode
        for mode in modes
        if is_integer_backed_mode(mode)
        and mode.pixel_width == current.pixel_width
        and mode.pixel_height == current.pixel_height
        and _ui_area(mode) < _ui_area(current)
    ]
    if not larger_integer_modes:
        return None

    return max(larger_integer_modes, key=_ui_area)


def analyze_display_modes(
    modes: list[ModeRecord],
    current: ModeRecord,
) -> Decision:
    matching_pixel_modes = [
        mode
        for mode in modes
        if mode.pixel_width == current.pixel_width
        and mode.pixel_height == current.pixel_height
    ]
    integer_candidates = [
        mode for mode in matching_pixel_modes if is_integer_backed_mode(mode)
    ]
    return Decision(
        current=current,
        selected=choose_replacement_mode(modes, current),
        matching_pixel_mode_count=len(matching_pixel_modes),
        integer_candidate_count=len(integer_candidates),
    )


def get_main_display_modes(display_id: int) -> tuple[list[ModeRecord], ModeRecord]:
    options = {Quartz.kCGDisplayShowDuplicateLowResolutionModes: True}
    modes = [
        normalize_mode(mode)
        for mode in Quartz.CGDisplayCopyAllDisplayModes(display_id, options)
    ]
    current = normalize_mode(Quartz.CGDisplayCopyDisplayMode(display_id))
    return modes, current


def apply_mode(display_id: int, mode: ModeRecord) -> None:
    error, config_ref = Quartz.CGBeginDisplayConfiguration(None)
    if error:
        raise RuntimeError(f"CGBeginDisplayConfiguration failed: {error}")

    error = Quartz.CGConfigureDisplayWithDisplayMode(
        config_ref,
        display_id,
        mode.raw,
        None,
    )
    if error:
        Quartz.CGCancelDisplayConfiguration(config_ref)
        raise RuntimeError(f"CGConfigureDisplayWithDisplayMode failed: {error}")

    Quartz.CGCompleteDisplayConfiguration(
        config_ref,
        Quartz.kCGConfigurePermanently,
    )


def _mode_label(mode: ModeRecord) -> str:
    return (
        f"{mode.width}x{mode.height} @ {mode.pixel_width}x{mode.pixel_height} "
        f"({mode.scale_x:.2f}x)"
    )


def _mode_kind(mode: ModeRecord) -> str:
    if is_integer_backed_mode(mode):
        return "integer-backed"
    return "fractional"


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Prefer integer-backed scaling on the current main display.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the decision without applying any display change.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print the current mode, candidate summary, and decision.",
    )
    return parser


def _print_decision(decision: Decision, scanned_count: int) -> None:
    print(
        "current="
        f"{decision.current.width}x{decision.current.height}"
        f" @ {decision.current.pixel_width}x{decision.current.pixel_height}"
        f" ({decision.current.scale_x:.2f}x, {_mode_kind(decision.current)})"
    )
    print(
        f"scanned={scanned_count} "
        f"matching-pixel-modes={decision.matching_pixel_mode_count} "
        f"integer-backed={decision.integer_candidate_count}"
    )
    if decision.selected is None:
        print("decision=no-change")
    else:
        print(f"decision=apply {_mode_label(decision.selected)}")


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)

    if not is_supported_macos_version():
        return 0

    display_id = Quartz.CGMainDisplayID()
    modes, current = get_main_display_modes(display_id)
    decision = analyze_display_modes(modes, current)
    if args.verbose or args.dry_run:
        _print_decision(decision, len(modes))
    if args.dry_run or decision.selected is None:
        return 0

    apply_mode(display_id, decision.selected)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
