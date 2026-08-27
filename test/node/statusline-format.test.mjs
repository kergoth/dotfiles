import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import {
  CONTEXT_COLORS,
  PALETTES,
  formatStatusLine,
} from "../../home/dot_pi/agent/extensions/statusline/statusline-format.js";

const repositoryRoot = join(dirname(fileURLToPath(import.meta.url)), "../..");

test("keeps formatter helpers outside Pi's top-level extension discovery", () => {
  assert.equal(existsSync(join(repositoryRoot, "home/dot_pi/agent/extensions/statusline-format.js")), false);
  assert.equal(existsSync(join(repositoryRoot, "home/dot_pi/agent/extensions/statusline/index.ts")), true);
});

test("formats the compact Pi footer with a green context pill below the warning threshold", () => {
  const line = formatStatusLine({
    model: "gpt-5.6-terra",
    cwd: "/Users/testuser/projects/myapp",
    branch: "main",
    contextPercent: 49,
    palette: "dark",
  });

  assert.match(line, /PI·gpt-5\.6-terra/);
  assert.match(line, /p\/myapp/);
  assert.match(line, /main/);
  assert.match(line, /ctx 49%/);
  assert.ok(line.includes(CONTEXT_COLORS.dark.green.background));
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
});

function lineFor(model, provider) {
  return formatStatusLine({
    model,
    provider,
    cwd: "/Users/testuser/projects/myapp",
    branch: "main",
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
    contextPercent: 50,
    palette: "light",
  });
  const red = formatStatusLine({
    model: "gpt-5.6-terra",
    cwd: "/Users/testuser/projects/myapp",
    branch: null,
    contextPercent: 80,
    palette: "light",
  });

  assert.ok(yellow.includes(CONTEXT_COLORS.light.yellow.background));
  assert.ok(red.includes(CONTEXT_COLORS.light.red.background));
});
