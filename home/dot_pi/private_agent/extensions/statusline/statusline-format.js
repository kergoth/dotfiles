import { usagePace, paceDuration } from "../model-alias/usage-pacing.js";
import { windowThreshold } from "../model-alias/model-alias-core.js";

const RESET = "\x1b[0m";
const BOLD = "\x1b[1m";

// Keep these palettes aligned with home/dot_claude/statusline-command.sh.
// Dark is Dracula; light is Catppuccin Latte.
export const PALETTES = {
  dark: {
    name: "Dracula",
    modelPill: { background: "\x1b[48;2;68;71;90m", foreground: "\x1b[38;2;248;248;242m" },
    path: "\x1b[38;2;189;147;249m",
    branch: "\x1b[38;2;98;114;164m",
    context: {
      green: { background: "\x1b[48;2;34;51;34m", foreground: "\x1b[38;2;80;250;123m" },
      yellow: { background: "\x1b[48;2;241;250;140m", foreground: "\x1b[38;2;40;42;54m" },
      red: { background: "\x1b[48;2;255;85;85m", foreground: "\x1b[38;2;40;42;54m" },
    },
  },
  light: {
    name: "Catppuccin Latte",
    modelPill: { background: "\x1b[48;2;172;176;190m", foreground: "\x1b[38;2;76;79;105m" },
    path: "\x1b[38;2;136;57;239m",
    branch: "\x1b[38;2;156;160;176m",
    context: {
      green: { background: "\x1b[48;2;223;239;221m", foreground: "\x1b[38;2;64;160;43m" },
      yellow: { background: "\x1b[48;2;223;142;29m", foreground: "\x1b[38;2;239;241;245m" },
      red: { background: "\x1b[48;2;210;15;57m", foreground: "\x1b[38;2;239;241;245m" },
    },
  },
};

export const CONTEXT_COLORS = {
  dark: PALETTES.dark.context,
  light: PALETTES.light.context,
};

function shortenPath(cwd) {
  const home = process.env.HOME;
  const relative = home && cwd.startsWith(`${home}/`) ? cwd.slice(home.length + 1) : cwd.replace(/^\//, "");
  const parts = relative.split("/").filter(Boolean);

  if (parts.length === 0) return home === cwd ? "~" : cwd;
  if (parts.length === 1) return home && cwd.startsWith(home) ? `~/${parts[0]}` : `/${parts[0]}`;

  const abbreviated = [...parts.slice(0, -1).map((part) => part.slice(0, 1)), parts.at(-1)].join("/");
  return home && cwd.startsWith(home) ? `~/${abbreviated}` : `/${abbreviated}`;
}

export function truncateToWidth(line, width) {
  let output = "";
  let visible = 0;

  for (let index = 0; index < line.length; ) {
    if (line[index] === "\x1b" && line[index + 1] === "[") {
      const match = /\x1b\[[0-?]*[ -/]*[@-~]/.exec(line.slice(index));
      if (match) {
        output += match[0];
        index += match[0].length;
        continue;
      }
    }

    if (visible >= width) break;
    output += line[index];
    index++;
    visible++;
  }

  return output;
}

function contextColor(palette, percentage) {
  if (percentage >= 80) return CONTEXT_COLORS[palette].red;
  if (percentage >= 50) return CONTEXT_COLORS[palette].yellow;
  return CONTEXT_COLORS[palette].green;
}

export const DEFAULT_USAGE_SETTINGS = Object.freeze({
  showAboveUsedPercent: 50,
  criticalAboveUsedPercent: 80,
  staleAfterMs: 30 * 60_000,
});

export function parseStatuslineConfig(raw = {}) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("statusline config must be an object");
  const usage = raw.usage === undefined ? {} : raw.usage;
  if (!usage || typeof usage !== "object" || Array.isArray(usage)) throw new Error("usage must be an object");
  const settings = { ...DEFAULT_USAGE_SETTINGS, ...usage };
  for (const key of ["showAboveUsedPercent", "criticalAboveUsedPercent"]) {
    if (typeof settings[key] !== "number" || !Number.isFinite(settings[key]) || settings[key] < 0 || settings[key] > 100) {
      throw new Error(`usage.${key} must be a number from 0 to 100`);
    }
  }
  if (settings.criticalAboveUsedPercent < settings.showAboveUsedPercent) throw new Error("usage.criticalAboveUsedPercent must be at least showAboveUsedPercent");
  if (typeof settings.staleAfterMs !== "number" || !Number.isFinite(settings.staleAfterMs) || settings.staleAfterMs <= 0) throw new Error("usage.staleAfterMs must be a positive number");
  return { usage: settings };
}
const WINDOW_LABELS = {
  five_hour: "5h", primary: "5h", rolling: "5h",
  seven_day: "7d", secondary: "7d", weekly: "7d",
  monthly: "mo",
};

// A trailing ~ marks stale percentages; stale readings never contribute pacing warnings.
export function usageWindows(snapshot, nowMs = Date.now(), settings = DEFAULT_USAGE_SETTINGS, aliasSettings = { switchAboveUsedPercent: 95 }) {
  const shown = [];
  for (const window of snapshot?.windows ?? []) {
    const pace = usagePace(window, snapshot, nowMs, windowThreshold(aliasSettings, snapshot.provider, window.id), aliasSettings.usagePacing);
    if (pace.expired) continue;
    const percent = typeof window.usedPercent === "number" && Number.isFinite(window.usedPercent) ? Math.round(window.usedPercent) : null;
    const stale = pace.stale || nowMs - (window.capturedAt ?? snapshot.capturedAt ?? nowMs) > settings.staleAfterMs;
    const overPace = !stale && pace.overPace === true;
    const earlyWarning = overPace && window.usedPercent >= pace.warningMinPercent;
    if (!window.limited && (percent === null || (percent < settings.showAboveUsedPercent && !earlyWarning))) continue;
    shown.push({ label: WINDOW_LABELS[window.id] ?? window.id, percent: percent === null ? null : window.limited ? Math.max(percent, 100) : percent, stale,
      ...(!window.limited && !stale && pace.projectedPercent !== undefined ? { overPace, timeToLimitMs: pace.timeToLimitMs } : {}) });
  }
  return shown;
}

function usageText(data) {
  return (data.usage ?? []).map((w) => `${w.label} ${w.overPace ? "⚠ " : w.overPace === false ? "✓ " : ""}${w.percent === null ? "limited" : `${w.percent}%`}${w.stale ? "~" : ""}${w.overPace ? ` ~${paceDuration(w.timeToLimitMs)}` : ""}`).join(" ");
}

function usageSegment(data) {
  const palette = PALETTES[data.palette];
  const critical = data.usage.some((w) => w.percent === null || (w.percent >= (data.usageSettings ?? DEFAULT_USAGE_SETTINGS).criticalAboveUsedPercent && w.overPace !== false));
  const warning = data.usage.some((w) => w.overPace !== false);
  const color = critical ? palette.context.red : warning ? palette.context.yellow : palette.context.green;
  return `${color.background}${color.foreground} ${usageText(data)} ${RESET}`;
}

// Route tags identify the execution backend when model display names collide.
// Recognizable applications have explicit tags, local variants share LO, and
// providers in TAG_DROP_PROVIDERS suppress the tag entirely (e.g. alias,
// where the model name already carries full identity). Other providers fall
// back to generated initials.
const ROUTE_TAGS = {
  cursor: "CU",
  "claude-bridge": "CC",
  "claude-cli": "CC",
  "openai-codex": "CX",
};

const TAG_DROP_PROVIDERS = new Set(["alias"]);

function generatedRouteTag(provider) {
  const parts = provider.split("-").filter(Boolean);
  if (parts.length >= 2) {
    return parts.map((part) => part[0].toUpperCase()).join("");
  }
  return provider.slice(0, 2).toUpperCase();
}

function routeTag(provider) {
  const id = provider?.trim();
  if (!id) return "";
  if (TAG_DROP_PROVIDERS.has(id)) return "";
  if (id.startsWith("local-")) return "LO";
  return ROUTE_TAGS[id] ?? generatedRouteTag(id);
}

function taggedLabel(provider, model) {
  const tag = routeTag(provider);
  return tag ? `${tag}·${model}` : model;
}

// `routed` is the physical model that answered last when the selection is a
// virtual model; omit it when it matches the selection.
function modelLabel(data) {
  const selected = taggedLabel(data.provider, data.model);
  return data.routed ? `${selected} → ${taggedLabel(data.routed.provider, data.routed.model)}` : selected;
}

// Match Pi default footer token compaction (footer.ts formatTokens).
export function formatTokenCount(count) {
  if (count < 1000) return String(count);
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

export function formatSessionCost(usd) {
  return `$${usd.toFixed(3)}`;
}

export function formatBurnText({ inputTokens = 0, outputTokens = 0, costUsd = 0 } = {}) {
  return `↑${formatTokenCount(inputTokens)} ↓${formatTokenCount(outputTokens)} ${formatSessionCost(costUsd)}`;
}

export function formatBurnSegment(data) {
  const palette = PALETTES[data.palette];
  return `${palette.branch}${formatBurnText(data)}${RESET}`;
}

function contextText(data) {
  const window = data.contextWindow > 0 ? `/${formatTokenCount(data.contextWindow)}` : "";
  return `ctx ${data.contextPercent}%${window}`;
}

function plainSegmentTexts(data) {
  return {
    model: `PI·${modelLabel(data)}`,
    path: shortenPath(data.cwd),
    branch: data.branch ?? "",
    burn: formatBurnText(data),
    usage: data.usage?.length ? usageText(data) : "",
    context: contextText(data),
  };
}

// Returns tier 0-4. Context always survives; burn and usage drop before context.
export function selectDegradationTier(cols, segments) {
  const padding = 6;
  const segWidth = (...texts) => {
    let total = padding;
    for (const text of texts) {
      if (text) total += text.length + 2;
    }
    return total;
  };

  const { model, path, branch, burn, usage, context } = segments;
  if (segWidth(model, path, branch, burn, usage, context) <= cols) return 0;
  if (segWidth(model, branch, burn, usage, context) <= cols) return 1;
  if (segWidth(model, burn, usage, context) <= cols) return 2;
  if (segWidth(model, context) <= cols) return 3;
  return 4;
}

export function formatStatusLine(data, tier = 0) {
  const palette = PALETTES[data.palette];
  const context = contextColor(data.palette, data.contextPercent);
  const segments = [
    `${palette.modelPill.background}${BOLD}${palette.modelPill.foreground} PI·${modelLabel(data)} ${RESET}`,
  ];

  if (tier <= 0) {
    segments.push(`${palette.path}${shortenPath(data.cwd)}${RESET}`);
  }
  if (tier <= 1 && data.branch) {
    segments.push(`${palette.branch}${data.branch}${RESET}`);
  }
  if (tier <= 2) {
    segments.push(formatBurnSegment(data));
    if (data.usage?.length) segments.push(usageSegment(data));
  }
  segments.push(`${context.background}${context.foreground} ${contextText(data)} ${RESET}`);

  return segments.join("  ");
}

export function formatStatusLineForWidth(data, width) {
  const tier = selectDegradationTier(width, plainSegmentTexts(data));
  return formatStatusLine(data, tier);
}
