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
  mergeUsage,
  selectTarget,
  recoveryAction,
  advanceResume,
  filterResolvedTargets,
  ownsSessionState,
  pendingRecoveryTarget,
  watchdogStillCurrent,
  clearCooldowns,
  configuredTargets,
  formatStatus,
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
  ["This operation was aborted", "claude-bridge", "aborted"],
  ["Operation aborted", "claude-bridge", "aborted"],
  ["Request was aborted", "openai-codex", "aborted"],
  ["Connection aborted by peer", "x", "transient"],
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

test("large and direct routes advance from unavailable current without bouncing backward", () => {
  const input = { ...selectBase, chain: ["a/1", "b/2", "c/3"], current: "b/2", previous: "b/2", contextTokens: 200000, cooldowns: { "b/2": { nextRetryAt: 2000 } } };
  assert.equal(selectTarget({ ...input, routeReason: "user" }).target, "c/3");
  assert.equal(selectTarget({ ...input, routeReason: "direct", cooldowns: {} }).target, "b/2");
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

test("expired usage windows do not exclude recovered providers", () => {
  const usage = { claude: { windows: [{ usedPercent: 100, resetsAt: 999 }] } };
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", usage, nowMs: 1000 }).target, "claude/a");
});

test("usage snapshots merge distinct windows and replace matching windows", () => {
  const previous = { provider: "claude-bridge", capturedAt: 1, windows: [{ id: "seven_day", usedPercent: 99 }, { id: "five_hour", usedPercent: 80 }] };
  const incoming = { provider: "claude-bridge", capturedAt: 2, windows: [{ id: "five_hour", usedPercent: 10 }] };
  assert.deepEqual(mergeUsage(previous, incoming).windows, [{ id: "seven_day", usedPercent: 99 }, { id: "five_hour", usedPercent: 10 }]);
});

test("usage threshold excludes only user-turn candidates at 95 percent", () => {
  for (const [usedPercent, expected] of [[94.9, "claude/a"], [95, "openai/b"], [100, "openai/b"]]) {
    const usage = { claude: { windows: [{ usedPercent }] } };
    assert.equal(selectTarget({ ...selectBase, routeReason: "user", usage }).target, expected);
    assert.equal(selectTarget({ ...selectBase, routeReason: "continuation", usage }).target, "claude/a");
  }
});

test("mixed exclusions prefer a usage-limited target over a cooled target", () => {
  const usage = { openai: { windows: [{ usedPercent: 99 }] } };
  const selected = selectTarget({ ...selectBase, chain: ["claude/a", "openai/b"], routeReason: "user", cooldowns: { "claude/a": { nextRetryAt: 2000 } }, usage });
  assert.equal(selected.target, "openai/b");
});

test("all unavailable selects earliest cooldown or lowest usage", () => {
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", cooldowns: { "claude/a": { nextRetryAt: 4000 }, "openai/b": { nextRetryAt: 3000 }, "openai/c": { nextRetryAt: 5000 } } }).target, "openai/b");
  const usage = { claude: { windows: [{ usedPercent: 99 }] }, openai: { windows: [{ usedPercent: 96 }] } };
  assert.equal(selectTarget({ ...selectBase, routeReason: "user", usage }).target, "openai/b");
});

test("compaction direct routes cannot consume pending recovery target", () => {
  assert.equal(pendingRecoveryTarget("direct", "openai/b", ["openai/b"]), undefined);
  assert.equal(pendingRecoveryTarget("continuation", "openai/b", ["openai/b"]), "openai/b");
});

test("unresolved targets are filtered while preserving order", () => {
  assert.deepEqual(filterResolvedTargets(["missing/a", "valid/b", "valid/c"], (target) => target.startsWith("valid/")), ["valid/b", "valid/c"]);
  assert.throws(() => filterResolvedTargets(["missing/a"], () => false), /resolvable/);
});

test("watchdog expiry is ignored after request generation changes", () => {
  assert.equal(watchdogStillCurrent(1, 1, true), true);
  assert.equal(watchdogStillCurrent(1, 2, true), false);
  assert.equal(watchdogStillCurrent(1, 1, false), false);
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
  assert.equal(recordFailure(entry, { kind: "quota" }, policy, 1_100_000).nextRetryAt, 2_000_000);
  entry = recordSuccess(entry, 3);
  assert.equal(entry.successCount, 1);
  entry = recordSuccess(recordSuccess(entry, 3), 3);
  assert.equal(entry, undefined);
});

test("ownsSessionState excludes direct requests", () => {
  assert.equal(ownsSessionState("direct"), false);
  for (const reason of ["user", "continuation", "retry"]) assert.equal(ownsSessionState(reason), true);
});

test("clearCooldowns clears one target or all and reports what it cleared", () => {
  const state = { targets: { "a/x": { nextRetryAt: 5 }, "b/y": { nextRetryAt: 5 } }, usage: {} };
  assert.deepEqual(clearCooldowns(state, "a/x"), ["a/x"]);
  assert.deepEqual(Object.keys(state.targets), ["b/y"]);
  assert.deepEqual(clearCooldowns(state, "missing/z"), []);
  assert.deepEqual(clearCooldowns(state), ["b/y"]);
  assert.deepEqual(state.targets, {});
});

test("configuredTargets dedupes targets across roles in order", () => {
  assert.deepEqual(configuredTargets(new Map([["coding", ["a/x", "b/y"]], ["light", ["b/y", "c/z"]]])), ["a/x", "b/y", "c/z"]);
});

test("formatStatus marks the active target, cooldowns, and exhausted usage", () => {
  const text = formatStatus({
    roles: new Map([["coding", ["a/x", "b/y", "c/z", "d/w"]]]),
    state: { targets: { "a/x": { nextRetryAt: 1000 + 240_000 }, "c/z": { nextRetryAt: 1000 + 3_900_000 }, "d/w": { nextRetryAt: 500 } }, usage: { b: { windows: [{ usedPercent: 97 }] } } },
    activeTarget: "b/y", settings: { switchAboveUsedPercent: 95 }, nowMs: 1000,
  });
  assert.equal(text, "model-alias: this session is on b/y\ncoding:\n    a/x (cooldown 4m)\n  * b/y (usage 97%)\n    c/z (cooldown 1h5m)\n    d/w");
});
