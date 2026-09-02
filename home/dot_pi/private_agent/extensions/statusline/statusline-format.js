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

// Route tags identify the execution backend when model display names collide.
// Recognizable applications have explicit tags, local variants share LO, and
// other providers fall back to generated initials.
const ROUTE_TAGS = {
  cursor: "CU",
  "claude-bridge": "CC",
  "openai-codex": "CX",
};

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
  if (id.startsWith("local-")) return "LO";
  return ROUTE_TAGS[id] ?? generatedRouteTag(id);
}

function modelLabel(data) {
  const tag = routeTag(data.provider);
  return tag ? `${tag}·${data.model}` : data.model;
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

function plainSegmentTexts(data) {
  return {
    model: `PI·${modelLabel(data)}`,
    path: shortenPath(data.cwd),
    branch: data.branch ?? "",
    burn: formatBurnText(data),
    context: `ctx ${data.contextPercent}%`,
  };
}

// Returns tier 0-4. Context always survives; burn drops before context.
export function selectDegradationTier(cols, segments) {
  const padding = 6;
  const segWidth = (...texts) => {
    let total = padding;
    for (const text of texts) {
      if (text) total += text.length + 2;
    }
    return total;
  };

  const { model, path, branch, burn, context } = segments;
  if (segWidth(model, path, branch, burn, context) <= cols) return 0;
  if (segWidth(model, branch, burn, context) <= cols) return 1;
  if (segWidth(model, burn, context) <= cols) return 2;
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
  }
  segments.push(`${context.background}${context.foreground} ctx ${data.contextPercent}% ${RESET}`);

  return segments.join("  ");
}

export function formatStatusLineForWidth(data, width) {
  const tier = selectDegradationTier(width, plainSegmentTexts(data));
  return formatStatusLine(data, tier);
}
