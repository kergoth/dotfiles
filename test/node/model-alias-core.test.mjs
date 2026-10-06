import assert from "node:assert/strict";
import test from "node:test";

import {
  classifyFailure,
  parseClaudeRateLimit,
  parseCodexRateLimits,
  parseConfig,
  parseModelRef,
  parseOpenCodeUsage,
  recordFailure,
  recordSuccess,
  selectTarget,
  recoveryAction,
  advanceResume,
} from "../../home/dot_pi/private_agent/extensions/model-alias/model-alias-core.js";

const base = { coding: ["claude-bridge/sonnet", "openai-codex/terra"], light: ["opencode-go/mimo"] };

test("parseConfig preserves role and target order", () => {
  const parsed = parseConfig(base);
  assert.deepEqual([...parsed.roles], [["coding", ["claude-bridge/sonnet", "openai-codex/terra"]], ["light", ["opencode-go/mimo"]]]);
  assert.deepEqual(parseModelRef("huggingface/org/model"), { provider: "huggingface", modelId: "org/model" });
});

test("parseConfig applies defaults and compatibility warnings", () => {
  const parsed = parseConfig({ ...base, $settings: { statusRefreshMs: 3 }, $defaults: { timeouts: { commitMs: 9 } } });
  assert.deepEqual(parsed.settings, { confirmSwitchAboveTokens: 131072, confirmTimeoutMs: 60000, unattendedSwitch: "compact", compactionAlias: "light", switchAboveUsedPercent: 95, opencodeUsagePollMs: 300000 });
  assert.deepEqual(parsed.defaults, { timeouts: { firstEventMs: 60000, stallMs: 90000 }, cooldown: { baseMs: 300000, capMs: 3600000, resetSuccesses: 3 } });
  assert.equal(parsed.warnings.length, 2);
});

test("parseConfig rejects malformed configuration", () => {
  assert.throws(() => parseConfig({ coding: [] }), /usable target/);
  assert.throws(() => parseConfig({ coding: ["broken"], light: ["x/y"] }), /provider\/model/);
  assert.throws(() => parseConfig({ coding: ["x/y"], $settings: { compactionAlias: "missing" } }), /compactionAlias/);
  assert.throws(() => parseConfig({ ...base, $settings: { unattendedSwitch: "explode" } }), /unattendedSwitch/);
});

const failures = [
  ["Claude rate limit (five_hour) — resets 8:00:00 PM", "claude-bridge", "quota"],
  ["Codex error: The usage limit has been reached", "openai-codex", "quota"],
  ['402: {"type":"server_error","message":"Upstream request failed: Insufficient account funds"}', "opencode-go", "quota"],
  ["HTTP 503 server error", "x", "transient"],
  ["bad syntax", "x", "other"],
];
for (const [message, provider, kind] of failures) test(`classifyFailure ${kind}: ${message.slice(0, 20)}`, () => assert.equal(classifyFailure(message, provider, Date.UTC(2026, 0, 1)).kind, kind));

test("usage parsers normalize provider windows", () => {
  assert.equal(parseCodexRateLimits({ type: "codex.rate_limits", rate_limits: { primary: { used_percent: 95, reset_at: 2000 }, limit_reached: false } }, 1).windows[0].usedPercent, 95);
  assert.equal(parseClaudeRateLimit({ status: "allowed_warning", utilization: .96, rateLimitType: "five_hour", resetsAt: 3 }, 1).windows[0].usedPercent, 96);
  const oc = parseOpenCodeUsage({ usage: { monthly: { status: "rate-limited", percent: 100, resetsAt: "2026-10-18T17:23:10.000Z" } } }, 1);
  assert.equal(oc.windows[0].limited, true);
  assert.equal(oc.windows[0].resetsAt, Date.parse("2026-10-18T17:23:10.000Z"));
});

const selectBase = {
  chain: ["claude/a", "openai/b", "openai/c"], current: "claude/a", previous: "claude/a", failed: null,
  contextTokens: 1000, cooldowns: {}, usage: {}, settings: { confirmSwitchAboveTokens: 131072, switchAboveUsedPercent: 95 }, nowMs: 1000,
};

test("continuation keeps available previous and leaves unavailable previous", () => {
  assert.equal(selectTarget({ ...selectBase, routeReason: "continuation" }).target, "claude/a");
  const selected = selectTarget({ ...selectBase, routeReason: "continuation", cooldowns: { "claude/a": { nextRetryAt: 2000 } } });
  assert.equal(selected.target, "openai/b");
  assert.equal(selected.crossesProvider, true);
});

test("user selection is preferred when small and sticky when large", () => {
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", current: "openai/b" }).target, "claude/a");
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", current: "openai/b", contextTokens: 200000 }).target, "openai/b");
  const selected = selectTarget({ ...selectBase, routeReason: "user", contextTokens: 200000, cooldowns: { "claude/a": { nextRetryAt: 2000 } } });
  assert.equal(selected.target, "openai/b");
  assert.equal(selected.needsConfirmation, true);
});

test("retry advances after failed target", () => {
  assert.equal(selectTarget({ ...selectBase, routeReason: "retry", failed: "claude/a" }).target, "openai/b");
});

test("all unavailable selects earliest cooldown or lowest usage", () => {
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", cooldowns: { "claude/a": { nextRetryAt: 4000 }, "openai/b": { nextRetryAt: 3000 }, "openai/c": { nextRetryAt: 5000 } } }).target, "openai/b");
  const usage = { claude: { windows: [{ usedPercent: 99 }] }, openai: { windows: [{ usedPercent: 96 }] } };
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", usage }).target, "openai/b");
});

test("recovery policy degrades compact outside interactive modes", () => {
  assert.equal(recoveryAction("compact", "interactive", false), "compact");
  assert.equal(recoveryAction("compact", "rpc", false), "compact");
  assert.equal(recoveryAction("compact", "print", false), "switch");
  assert.equal(recoveryAction("compact", "json", true), "switch");
  assert.equal(recoveryAction("fail", "interactive", false), "stop");
});

test("automatic resume is capped and resets on a new user route", () => {
  assert.deepEqual(advanceResume({ routeId: 1, count: 2 }, 1, 2), { allowed: false, state: { routeId: 1, count: 2 } });
  assert.deepEqual(advanceResume({ routeId: 1, count: 2 }, 2, 2), { allowed: true, state: { routeId: 2, count: 1 } });
});

test("compact failure resumes by switching", () => {
  assert.equal(recoveryAction("compact", "interactive", true), "switch");
});

test("cooldown uses reset then clears after successes", () => {
  const policy = { baseMs: 300000, capMs: 3600000, resetSuccesses: 3 };
  let entry = recordFailure(undefined, { kind: "quota", resetsAt: 2_000_000 }, policy, 1_000_000);
  assert.equal(entry.nextRetryAt, 2_000_000);
  entry = recordSuccess(entry, 3);
  assert.equal(entry.successCount, 1);
  entry = recordSuccess(recordSuccess(entry, 3), 3);
  assert.equal(entry, undefined);
});
