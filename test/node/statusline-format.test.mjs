import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import {
  CONTEXT_COLORS,
  PALETTES,
  formatBurnText,
  formatStatusLine,
  formatStatusLineForWidth,
  usageWindows,
  formatTokenCount,
  selectDegradationTier,
} from "../../home/dot_pi/private_agent/extensions/statusline/statusline-format.js";

const repositoryRoot = join(dirname(fileURLToPath(import.meta.url)), "../..");

test("keeps formatter helpers outside Pi's top-level extension discovery", () => {
  assert.equal(existsSync(join(repositoryRoot, "home/dot_pi/private_agent/extensions/statusline-format.js")), false);
  assert.equal(existsSync(join(repositoryRoot, "home/dot_pi/private_agent/extensions/statusline/index.ts")), true);
});

test("formats the compact Pi footer with a green context pill below the warning threshold", () => {
  const line = formatStatusLine({
    model: "gpt-5.6-terra",
    cwd: "/Users/testuser/projects/myapp",
    branch: "main",
    inputTokens: 12000,
    outputTokens: 3400,
    costUsd: 0.42,
    contextPercent: 49,
    palette: "dark",
  });

  assert.match(line, /PI·gpt-5\.6-terra/);
  assert.match(line, /p\/myapp/);
  assert.match(line, /main/);
  assert.match(line, /↑12k ↓3\.4k \$0\.420/);
  assert.match(line, /ctx 49%/);
  assert.ok(line.includes(CONTEXT_COLORS.dark.green.background));
});

test("shows the active context window next to the percentage", () => {
  const base = { model: "Claude Sonnet 5.5", cwd: "/Users/testuser/projects/myapp", branch: null, contextPercent: 12, palette: "dark" };

  assert.match(formatStatusLine({ ...base, contextWindow: 272000 }), /ctx 12%\/272k/);
  assert.match(formatStatusLine({ ...base, contextWindow: 1000000 }), /ctx 12%\/1\.0M/);
  assert.match(formatStatusLine({ ...base, contextWindow: 0 }), /ctx 12% /);
  assert.doesNotMatch(formatStatusLine(base), /ctx 12%\//);
});

test("formats session burn tokens like the Pi default footer", () => {
  assert.equal(formatTokenCount(999), "999");
  assert.equal(formatTokenCount(5000), "5.0k");
  assert.equal(formatTokenCount(70000), "70k");
  assert.equal(formatBurnText({ inputTokens: 70000, outputTokens: 5000, costUsd: 0.5 }), "↑70k ↓5.0k $0.500");
});

test("drops session burn before context when width is tight", () => {
  const data = {
    model: "Composer 2.5",
    provider: "cursor",
    cwd: "/Users/testuser/.dotfiles",
    branch: "main",
    inputTokens: 70000,
    outputTokens: 5000,
    costUsd: 0.5,
    contextPercent: 80,
    palette: "dark",
  };

  const full = formatStatusLineForWidth(data, 120);
  assert.match(full, /↑70k ↓5\.0k \$0\.500/);
  assert.match(full, /ctx 80%/);

  const narrow = formatStatusLineForWidth(data, 24);
  assert.doesNotMatch(narrow, /↑70k/);
  assert.match(narrow, /ctx 80%/);
});

test("selectDegradationTier drops burn before context", () => {
  const widths = {
    model: "PI·CU·Opus",
    path: "~/.d/dotfiles",
    branch: "main",
    burn: "↑70k ↓5.0k $0.500",
    context: "ctx 80%",
  };

  assert.equal(selectDegradationTier(120, widths), 0);
  assert.equal(selectDegradationTier(40, widths), 3);
  assert.equal(selectDegradationTier(20, widths), 4);
});

test("keeps the complete Claude model name", () => {
  const line = formatStatusLine({
    model: "Claude Sonnet 4.6",
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    contextPercent: 35,
    palette: "dark",
  });

  assert.match(line, /PI·Claude Sonnet 4\.6/);
  assert.match(line, /↑0 ↓0 \$0\.000/);
});

function lineFor(model, provider) {
  return formatStatusLine({
    model,
    provider,
    cwd: "/Users/testuser/projects/myapp",
    branch: "main",
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
    contextPercent: 0,
    palette: "dark",
  });
}

test("uses CU and CC route tags to match the Cursor and Claude Code statuslines", () => {
  assert.match(lineFor("Auto", "cursor"), /PI·CU·Auto/);
  assert.match(lineFor("Claude Opus 4.6", "claude-bridge"), /PI·CC·Claude Opus 4\.6/);
});

test("uses CX as the explicit Codex route tag", () => {
  assert.match(lineFor("GPT-5.6 Terra", "openai-codex"), /PI·CX·GPT-5\.6 Terra/);
});

test("uses LO for local providers", () => {
  assert.match(lineFor("Coder", "local-coder"), /PI·LO·Coder/);
  assert.match(lineFor("llama3", "local-ollama"), /PI·LO·llama3/);
});

test("generates uppercase route tags for other provider ids", () => {
  assert.match(lineFor("Sonar", "mtplx"), /PI·MT·Sonar/);
});

test("drops the route tag for alias provider", () => {
  assert.match(lineFor("coding-budget", "alias"), /PI·coding-budget/);
  assert.doesNotMatch(lineFor("coding-budget", "alias"), /PI·[A-Z]+·coding-budget/);
});

test("shows the routed physical model after a virtual selection", () => {
  const data = {
    model: "coding",
    provider: "alias",
    routed: { provider: "claude-bridge", model: "claude-sonnet-5-5" },
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    contextPercent: 0,
    palette: "dark",
  };
  assert.match(formatStatusLine(data), /PI·coding → CC·claude-sonnet-5-5/);
});

test("budgets the routed model when choosing a degradation tier", () => {
  const data = {
    model: "coding",
    provider: "alias",
    routed: { provider: "claude-bridge", model: "claude-sonnet-5-5" },
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
    contextPercent: 0,
    palette: "dark",
  };
  const plain = formatStatusLineForWidth({ ...data, routed: undefined }, 60);
  const routed = formatStatusLineForWidth(data, 60);
  assert.match(plain, /myapp/);
  assert.doesNotMatch(routed, /myapp/);
  assert.match(routed, /ctx 0%/);
});

test("documents the Dracula and Catppuccin Latte palette sources", () => {
  assert.equal(PALETTES.dark.name, "Dracula");
  assert.equal(PALETTES.light.name, "Catppuccin Latte");
  assert.equal(PALETTES.dark.context.green.background, CONTEXT_COLORS.dark.green.background);
  assert.equal(PALETTES.light.context.red.background, CONTEXT_COLORS.light.red.background);
});

test("changes the context pill from yellow to red at the existing thresholds", () => {
  const yellow = formatStatusLine({
    model: "gpt-5.6-terra",
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
    contextPercent: 50,
    palette: "light",
  });
  const red = formatStatusLine({
    model: "gpt-5.6-terra",
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
    contextPercent: 80,
    palette: "light",
  });

  assert.ok(yellow.includes(CONTEXT_COLORS.light.yellow.background));
  assert.ok(red.includes(CONTEXT_COLORS.light.red.background));
});

test("usageWindows shows only unreset windows at 50% or more and marks stale readings", () => {
  const nowMs = 10_000_000;
  const windows = usageWindows({ capturedAt: nowMs, windows: [
    { id: "five_hour", usedPercent: 49, resetsAt: nowMs + 1000 },
    { id: "seven_day", usedPercent: 81, resetsAt: nowMs + 1000 },
    { id: "primary", usedPercent: 96, resetsAt: nowMs - 1 },
    { id: "monthly", usedPercent: 100, limited: true, capturedAt: nowMs - 31 * 60_000 },
  ] }, nowMs);
  assert.deepEqual(windows, [{ label: "7d", percent: 81, stale: false }, { label: "mo", percent: 100, stale: true }]);
  assert.deepEqual(usageWindows(undefined), []);
});

test("renders the usage segment before context and drops it before context", () => {
  const data = { model: "coding", provider: "alias", cwd: "/tmp", contextPercent: 10, contextWindow: 0, palette: "dark", usage: [{ label: "7d", percent: 81, stale: false }] };
  assert.match(formatStatusLineForWidth(data, 200), /7d 81%.*ctx 10%/);
  const narrow = formatStatusLineForWidth(data, 30);
  assert.doesNotMatch(narrow, /7d 81%/);
  assert.match(narrow, /ctx 10%/);
  assert.doesNotMatch(formatStatusLineForWidth({ ...data, usage: [] }, 200), /7d/);
});
