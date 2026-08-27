import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { formatStatusLine, truncateToWidth } from "./statusline-format.js";

function contextPercent(ctx: any): number {
  const percent = ctx.getContextUsage()?.percent;
  return typeof percent === "number" && Number.isFinite(percent) ? Math.max(0, Math.min(100, Math.round(percent))) : 0;
}

function paletteName(ctx: any): "dark" | "light" {
  return ctx.ui.theme?.name === "light" ? "light" : "dark";
}

function installFooter(ctx: any): void {
  const model = ctx.model?.displayName ?? ctx.model?.name ?? ctx.model?.id ?? "Pi";

  ctx.ui.setFooter((tui: any, _theme: any, footerData: any) => ({
    dispose: footerData.onBranchChange(() => tui.requestRender()),
    invalidate() {},
    render(width: number) {
      const line = formatStatusLine({
        model,
        cwd: ctx.cwd,
        branch: footerData.getGitBranch(),
        contextPercent: contextPercent(ctx),
        palette: paletteName(ctx),
      });
      return [truncateToWidth(line, width)];
    },
  }));
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => installFooter(ctx));
  pi.on("turn_end", (_event, ctx) => installFooter(ctx));
  pi.on("model_select", (_event, ctx) => installFooter(ctx));
}
