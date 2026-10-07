import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

import { formatStatusLineForWidth, usageWindows } from "./statusline-format.js";

// Same location model-alias writes; the footer only reads it, and at most once every few seconds.
const aliasStateFile = join(
  process.env.PI_MODEL_ALIAS_STATE_DIR || join(process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent"), "state", "model-alias"),
  "state.json",
);
let cachedUsage: { at: number; usage: Record<string, any> } = { at: 0, usage: {} };

function providerUsage(provider: string | undefined) {
  if (!provider) return [];
  const now = Date.now();
  if (now - cachedUsage.at > 5000) {
    try {
      cachedUsage = { at: now, usage: JSON.parse(readFileSync(aliasStateFile, "utf8")).usage ?? {} };
    } catch {
      cachedUsage = { at: now, usage: {} };
    }
  }
  return usageWindows(cachedUsage.usage[provider], now);
}

function contextPercent(ctx: any): number {
  const percent = ctx.getContextUsage()?.percent;
  return typeof percent === "number" && Number.isFinite(percent) ? Math.max(0, Math.min(100, Math.round(percent))) : 0;
}

function contextWindow(ctx: any): number {
  const window = ctx.getContextUsage()?.contextWindow;
  return typeof window === "number" && Number.isFinite(window) && window > 0 ? window : 0;
}

const LIGHT_THEMES = new Set(["light", "catppuccin-latte"]);

function paletteName(ctx: any): "dark" | "light" {
  return LIGHT_THEMES.has(ctx.ui.theme?.name ?? "") ? "light" : "dark";
}

function sessionUsage(ctx: any): { inputTokens: number; outputTokens: number; costUsd: number } {
  const totals = { input: 0, output: 0, cost: 0 };

  const addUsage = (usage: any) => {
    if (!usage) return;
    totals.input += usage.input ?? 0;
    totals.output += usage.output ?? 0;
    totals.cost += usage.cost?.total ?? 0;
  };

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      addUsage(entry.message.usage);
    } else if (entry.type === "message" && entry.message.role === "toolResult") {
      addUsage(entry.message.usage);
    } else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
      addUsage(entry.usage);
    }
  }

  return { inputTokens: totals.input, outputTokens: totals.output, costUsd: totals.cost };
}

// Entry id of the last assistant message at the moment the model was switched; a routed model
// recorded on that message answered for the previous selection, so it is not shown.
let staleAssistantId: string | undefined;

function routedModel(ctx: any): { provider: string; model: string } | undefined {
  const selected = ctx.model;
  if (!selected) return undefined;

  const branch = ctx.sessionManager.getBranch();
  for (let i = branch.length - 1; i >= 0; i--) {
    const message = branch[i].type === "message" ? branch[i].message : undefined;
    if (message?.role !== "assistant") continue;
    if (branch[i].id === staleAssistantId) return undefined;
    if (message.provider === selected.provider && message.model === selected.id) return undefined;
    return { provider: message.provider, model: message.model };
  }
  return undefined;
}

function installFooter(ctx: any): void {
  const provider = ctx.model?.provider;
  const model =
    provider === "alias" ? ctx.model.id : (ctx.model?.displayName ?? ctx.model?.name ?? ctx.model?.id ?? "Pi");

  ctx.ui.setFooter((tui: any, _theme: any, footerData: any) => ({
    dispose: footerData.onBranchChange(() => tui.requestRender()),
    invalidate() {},
    render(width: number) {
      const usage = sessionUsage(ctx);
      const routed = routedModel(ctx);
      return [
        formatStatusLineForWidth(
          {
            model,
            provider,
            routed,
            usage: providerUsage(routed?.provider ?? provider),
            cwd: ctx.cwd,
            branch: footerData.getGitBranch(),
            inputTokens: usage.inputTokens,
            outputTokens: usage.outputTokens,
            costUsd: usage.costUsd,
            contextPercent: contextPercent(ctx),
            contextWindow: contextWindow(ctx),
            palette: paletteName(ctx),
          },
          width,
        ),
      ];
    },
  }));
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    staleAssistantId = undefined;
    installFooter(ctx);
  });
  pi.on("turn_end", (_event, ctx) => installFooter(ctx));
  pi.on("model_select", (_event, ctx) => {
    const branch = ctx.sessionManager.getBranch();
    staleAssistantId = branch.findLast((entry: any) => entry.type === "message" && entry.message?.role === "assistant")?.id;
    installFooter(ctx);
  });
}
