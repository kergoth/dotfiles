import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { formatStatusLineForWidth } from "./statusline-format.js";

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

function routedModel(ctx: any): { provider: string; model: string } | undefined {
  const selected = ctx.model;
  if (!selected) return undefined;

  const branch = ctx.sessionManager.getBranch();
  for (let i = branch.length - 1; i >= 0; i--) {
    const message = branch[i].type === "message" ? branch[i].message : undefined;
    if (message?.role !== "assistant") continue;
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
      return [
        formatStatusLineForWidth(
          {
            model,
            provider,
            routed: routedModel(ctx),
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
  pi.on("session_start", (_event, ctx) => installFooter(ctx));
  pi.on("turn_end", (_event, ctx) => installFooter(ctx));
  pi.on("model_select", (_event, ctx) => installFooter(ctx));
}
