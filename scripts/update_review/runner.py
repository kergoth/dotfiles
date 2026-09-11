from __future__ import annotations

from collections import defaultdict
from collections.abc import Callable, Iterable
from subprocess import CalledProcessError
from typing import Any, Protocol

from update_review.ai import dispatch_ai_review
from update_review.models import RunResult


class Console(Protocol):
    def print(self, *args: object, **kwargs: object) -> None: ...


class Provider(Protocol):
    name: str

    def resolve(self) -> list[Any]: ...
    def review(self, candidate: Any) -> Any: ...
    def apply(self, approved: list[Any]) -> list[dict[str, Any]]: ...


def run_review_session(
    providers: Iterable[Provider],
    *,
    input_fn: Callable[[str], str],
    console: Console,
    ai_config: dict,
    dry_run: bool = False,
    no_review: bool = False,
    interactive: bool = True,
) -> RunResult:
    providers = list(providers)
    resolved = [
        (provider, candidate)
        for provider in providers
        for candidate in provider.resolve()
    ]
    if not ai_config:
        ai_config = next(
            (
                provider.ai_config
                for provider in providers
                if getattr(provider, "ai_config", None)
            ),
            {},
        )
    if not dry_run and not no_review and not interactive:
        raise RuntimeError(
            "interactive review requires a terminal; use --no-review to accept all candidates"
        )
    selected: dict[str, list[Any]] = defaultdict(list)
    states: dict[tuple[str, str], str] = {}
    legend_shown = False
    for provider, candidate in resolved:
        key = (provider.name, candidate.id)
        if no_review:
            selected[provider.name].append(candidate)
            states[key] = "accepted without review"
            continue
        if not candidate.requires_review:
            selected[provider.name].append(candidate)
            states[key] = "auto-accepted"
            continue
        try:
            prepared = provider.review(candidate)
            prepared.show(console)
        except (CalledProcessError, OSError) as error:
            console.print(
                f"Skipping {candidate.id}: unable to acquire review evidence ({error})"
            )
            states[key] = "skipped"
            continue
        request = prepared.ai_request()
        if request is not None:
            output = dispatch_ai_review(request, ai_config, console)
            if output:
                console.print(output)
        if dry_run:
            states[key] = "unprocessed"
            continue
        if not legend_shown:
            _print_legend(console)
            legend_shown = True
        while True:
            action = input_fn(
                "[a]pply [s]kip [d]iff [f]inish [c]ancel [?] help: "
            ).lower()
            if action == "a":
                selected[provider.name].append(candidate)
                states[key] = "accepted"
                break
            if action == "s":
                states[key] = "skipped"
                break
            if action == "d":
                prepared.show(console, diff_only=True)
                continue
            if action == "?":
                _print_help(console)
                continue
            if action == "c":
                _print_summary(console, resolved, states, "cancel")
                return RunResult("cancel", {})
            if action == "f":
                _print_summary(console, resolved, states, "finish")
                return _apply_selected(providers, selected, "finish")
            console.print("Please choose a, s, d, f, c, or ?.")
    if dry_run:
        _print_summary(console, resolved, states, "dry-run")
        return RunResult("dry-run", {})
    _print_summary(console, resolved, states, "complete")
    return _apply_selected(providers, selected, "complete")


def _print_legend(console: Console) -> None:
    console.print(
        "Review controls: [a]pply [s]kip [d]iff [f]inish [c]ancel [?] help",
        markup=False,
    )


def _print_help(console: Console) -> None:
    console.print(
        "Apply selects current update. Skip defers it. Diff re-shows evidence. Finish applies prior selections and exits. Cancel discards selections and exits."
    )


def _print_summary(
    console: Console,
    resolved: list[tuple[Provider, Any]],
    states: dict[tuple[str, str], str],
    outcome: str,
) -> None:
    rows = []
    for provider, candidate in resolved:
        state = states.get((provider.name, candidate.id), "unprocessed")
        if outcome == "cancel" and state in {
            "accepted",
            "auto-accepted",
            "accepted without review",
        }:
            state = "discarded"
        elif outcome == "dry-run" and state == "unprocessed":
            state = "previewed"
        rows.append(f"{candidate.id} ({state})")
    console.print("Review summary: " + ", ".join(rows))


def _apply_selected(
    providers: Iterable[Provider], selected: dict[str, list[Any]], outcome: str
) -> RunResult:
    return RunResult(
        outcome,
        {
            provider.name: provider.apply(selected.get(provider.name, []))
            if selected.get(provider.name)
            else []
            for provider in providers
        },
    )
