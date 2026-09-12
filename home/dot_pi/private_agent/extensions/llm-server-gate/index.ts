import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MODEL_TO_PROFILE: Record<string, string> = {
  "mlx-community/Qwen3.6-35B-A3B-4bit": "agent",
  "mlx-community/gemma-4-26B-A4B-it-qat-4bit": "assistant",
  "mlx-community/Qwen3.8-27B-4bit": "quality",
};

const LLM_SERVER = join(homedir(), "bin", "llm-server");
const PORT = 5413;
const READY_TIMEOUT_MS = 120_000;

function profileFor(modelId: string | undefined): string | null {
  if (!modelId) return null;
  return MODEL_TO_PROFILE[modelId] ?? null;
}

function llmServer(...args: string[]): { ok: boolean; stdout: string } {
  try {
    const stdout = execFileSync(LLM_SERVER, args, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 90_000,
    });
    return { ok: true, stdout };
  } catch {
    return { ok: false, stdout: "" };
  }
}

function isRunning(profile: string): boolean {
  return llmServer("is-running", profile).ok;
}

function probeReady(): boolean {
  try {
    execFileSync("curl", ["-sf", "-o", "/dev/null", "--max-time", "2", `http://127.0.0.1:${PORT}/v1/models`], {
      stdio: "ignore",
      timeout: 5_000,
    });
    return true;
  } catch {
    return false;
  }
}

function waitForReady(): boolean {
  const deadline = Date.now() + READY_TIMEOUT_MS;
  while (Date.now() < deadline) {
    if (probeReady()) return true;
    try {
      execFileSync("sleep", ["1"], { stdio: "ignore" });
    } catch {
      break;
    }
  }
  return false;
}

function ensureServer(profile: string): boolean {
  if (isRunning(profile)) return true;

  if (!llmServer("switch", profile).ok) return false;

  if (probeReady()) return true;
  return waitForReady();
}

export default function (pi: ExtensionAPI) {
  pi.on("model_select", (event: any, ctx: any) => {
    const profile = profileFor(event.model?.id);
    if (!profile) return;
    if (isRunning(profile)) return;

    if (ctx.hasUI) {
      ctx.ui.notify(`llm-server: ${profile} will start on first request`, "warning");
    }
  });

  pi.on("before_provider_request", (event: any) => {
    const profile = profileFor(event?.payload?.model);
    if (!profile) return;

    ensureServer(profile);
  });

  pi.registerCommand("llm-server", {
    description: "Show llm-server status for all model profiles.",
    handler: async (_args, ctx) => {
      const { stdout } = llmServer("status");
      ctx.ui.notify(`llm-server:\n${stdout}`, "info");
    },
  });
}
