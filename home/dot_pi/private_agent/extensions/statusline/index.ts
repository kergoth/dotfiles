import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { formatStatusLineForWidth } from "./statusline-format.js";

function contextPercent(ctx: any): number {
  const percent = ctx.getContextUsage()?.percent;
  return typeof percent === "number" && Number.isFinite(percent) ? Math.max(0, Math.min(100, Math.round(percent))) : 0;
}

function paletteName(ctx: any): "dark" | "light" {
  return ctx.ui.theme?.name === "light" ? "light" : "dark";
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

function installFooter(ctx: any): void {
  const model = ctx.model?.displayName ?? ctx.model?.name ?? ctx.model?.id ?? "Pi";
  const provider = ctx.model?.provider;

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
            cwd: ctx.cwd,
            branch: footerData.getGitBranch(),
            inputTokens: usage.inputTokens,
            outputTokens: usage.outputTokens,
            costUsd: usage.costUsd,
            contextPercent: contextPercent(ctx),
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
