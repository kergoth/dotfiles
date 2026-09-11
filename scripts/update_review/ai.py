from __future__ import annotations

import shutil
import subprocess
from contextlib import suppress
from typing import Protocol

from update_review.models import AIReviewRequest

AGENT_CLIS = ["codex", "agent", "qwen", "pi", "claude"]
AGENT_DEFAULT_TIMEOUTS = {
    "claude": 120,
    "codex": 120,
    "agent": 120,
    "pi": 120,
    "qwen": 480,
}
FALLBACK_AGENT_TIMEOUT = 480
AI_AGENT_ALIASES = {"cursor": "agent"}


class Console(Protocol):
    def print(self, *args: object, **kwargs: object) -> None: ...


def normalize_agent(agent: str) -> str:
    return AI_AGENT_ALIASES.get(agent, agent)


def agent_candidates(request: AIReviewRequest, config: dict) -> list[str]:
    if "fallback_chain" in config:
        candidates = [agent for agent in config["fallback_chain"] if shutil.which(agent)]
    else:
        candidates = [agent for agent in AGENT_CLIS if shutil.which(agent)]

    if request.preferred_agent is None:
        return candidates

    preferred = normalize_agent(request.preferred_agent)
    if not shutil.which(preferred):
        return candidates
    return [preferred] + [agent for agent in candidates if agent != preferred]


def resolve_model(agent: str, request: AIReviewRequest, config: dict, preferred: bool) -> str | None:
    if preferred and request.model is not None:
        return request.model
    agent_config = config.get("agents", {}).get(agent, {})
    return agent_config.get("model")


def resolve_timeout(agent: str, model: str | None, request: AIReviewRequest, config: dict) -> int:
    if request.timeout is not None:
        return request.timeout
    agent_config = config.get("agents", {}).get(agent, {})
    if model is not None and model in agent_config.get("model_timeouts", {}):
        return agent_config["model_timeouts"][model]
    if agent_config.get("timeout") is not None:
        return agent_config["timeout"]
    if config.get("fallback_timeout") is not None:
        return config["fallback_timeout"]
    return AGENT_DEFAULT_TIMEOUTS.get(agent, FALLBACK_AGENT_TIMEOUT)


def build_agent_command(agent: str, model: str | None) -> list[str]:
    if agent == "claude":
        return ["claude", "--model", model or "sonnet", "--print", "--no-session-persistence"]
    if agent == "codex":
        command = ["codex"]
        if model:
            command.extend(["--model", model])
        return command + ["exec", "--ephemeral"]
    if agent == "agent":
        command = ["agent"]
        if model:
            command.extend(["--model", model])
        return command + ["-m"]
    if agent == "qwen":
        return ["qwen", "--prompt"]
    if agent == "pi":
        command = ["pi"]
        if model:
            command.extend(["--model", model])
        return command + ["-p", "--no-session"]
    return [agent]


def dispatch_ai_review(request: AIReviewRequest, config: dict, console: Console) -> str | None:
    for agent in agent_candidates(request, config):
        preferred = agent == normalize_agent(request.preferred_agent) if request.preferred_agent else False
        model = resolve_model(agent, request, config, preferred)
        timeout = resolve_timeout(agent, model, request, config)
        console.print(f"Running AI review via {agent}...")
        with suppress(subprocess.TimeoutExpired, OSError):
            result = subprocess.run(
                build_agent_command(agent, model) + [request.prompt],
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        console.print(f"AI review via {agent} produced no output.")
    return None
