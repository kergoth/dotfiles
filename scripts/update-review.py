#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["rich", "typer"]
# ///

from __future__ import annotations

import json
from pathlib import Path

import typer
from rich.console import Console

from update_review.providers.git import GitProvider
from update_review.runner import run_review_session

app = typer.Typer(add_completion=False)


@app.command()
def run(
    providers: list[str] = typer.Argument(["git"]),
    result_file: Path = typer.Option(..., "--result-file"),
    dry_run: bool = typer.Option(False, "--dry-run", "-n"),
    no_review: bool = typer.Option(False, "--no-review"),
) -> None:
    root = Path(__file__).resolve().parent.parent
    registry = {"git": GitProvider(root)}
    selected = []
    for name in providers:
        if name not in registry:
            raise typer.BadParameter(f"unknown provider: {name}")
        selected.append(registry[name])
    result = run_review_session(
        selected,
        input_fn=input,
        console=Console(),
        ai_config={},
        dry_run=dry_run,
        no_review=no_review,
        interactive=__import__("sys").stdin.isatty(),
    )
    result_file.write_text(json.dumps({"outcome": result.outcome, "providers": result.summaries}))


if __name__ == "__main__":
    app()
