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

test("cooldown uses reset then clears after successes", () => {
  const policy = { baseMs: 300000, capMs: 3600000, resetSuccesses: 3 };
  let entry = recordFailure(undefined, { kind: "quota", resetsAt: 2_000_000 }, policy, 1_000_000);
  assert.equal(entry.nextRetryAt, 2_000_000);
  entry = recordSuccess(entry, 3);
  assert.equal(entry.successCount, 1);
  entry = recordSuccess(recordSuccess(entry, 3), 3);
  assert.equal(entry, undefined);
});
