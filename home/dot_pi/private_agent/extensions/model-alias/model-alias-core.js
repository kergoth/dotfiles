const SETTINGS = Object.freeze({
  confirmSwitchAboveTokens: 131072,
  confirmTimeoutMs: 60000,
  unattendedSwitch: "compact",
  compactionAlias: "light",
  switchAboveUsedPercent: 95,
  opencodeUsagePollMs: 300000,
});
const DEFAULTS = Object.freeze({
  timeouts: Object.freeze({ firstEventMs: 60000, stallMs: 90000 }),
  cooldown: Object.freeze({ baseMs: 300000, capMs: 3600000, resetSuccesses: 3 }),
});

export function parseModelRef(ref) {
  if (typeof ref !== "string" || !ref.includes("/") || ref.startsWith("/") || ref.endsWith("/")) throw new Error(`Invalid model reference ${JSON.stringify(ref)}; expected provider/model`);
  const slash = ref.indexOf("/");
  return { provider: ref.slice(0, slash), modelId: ref.slice(slash + 1) };
}

const positive = (name, value) => {
  if (!Number.isSafeInteger(value) || value <= 0) throw new Error(`${name} must be a positive integer`);
  return value;
};

export function parseConfig(raw) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("model-alias config must be an object");
  const warnings = [];
  const inputSettings = raw.$settings ?? {};
  const settings = { ...SETTINGS, ...inputSettings };
  delete settings.statusRefreshMs;
  if (inputSettings.statusRefreshMs !== undefined) warnings.push("$settings.statusRefreshMs is ignored");
  if (!["compact", "switch", "fail"].includes(settings.unattendedSwitch)) throw new Error("unattendedSwitch must be compact, switch, or fail");
  for (const key of ["confirmSwitchAboveTokens", "confirmTimeoutMs", "opencodeUsagePollMs"]) positive(key, settings[key]);
  if (typeof settings.switchAboveUsedPercent !== "number" || settings.switchAboveUsedPercent < 0 || settings.switchAboveUsedPercent > 100) throw new Error("switchAboveUsedPercent must be 0..100");
  if (typeof settings.compactionAlias !== "string" || !settings.compactionAlias) throw new Error("compactionAlias must name a role");

  const time = raw.$defaults?.timeouts ?? {};
  const cool = raw.$defaults?.cooldown ?? {};
  if (time.commitMs !== undefined) warnings.push("$defaults.timeouts.commitMs is ignored");
  const defaults = {
    timeouts: { firstEventMs: positive("firstEventMs", time.firstEventMs ?? DEFAULTS.timeouts.firstEventMs), stallMs: positive("stallMs", time.stallMs ?? DEFAULTS.timeouts.stallMs) },
    cooldown: { baseMs: positive("baseMs", cool.baseMs ?? DEFAULTS.cooldown.baseMs), capMs: positive("capMs", cool.capMs ?? DEFAULTS.cooldown.capMs), resetSuccesses: positive("resetSuccesses", cool.resetSuccesses ?? DEFAULTS.cooldown.resetSuccesses) },
  };
  if (defaults.cooldown.baseMs > defaults.cooldown.capMs) throw new Error("cooldown baseMs must not exceed capMs");
  const roles = new Map();
  for (const [name, targets] of Object.entries(raw)) {
    if (name.startsWith("$")) continue;
    if (!Array.isArray(targets) || targets.length === 0) throw new Error(`Role ${name} needs at least one usable target`);
    roles.set(name, targets.map((ref) => { parseModelRef(ref); return ref; }));
  }
  if (!roles.has(settings.compactionAlias)) throw new Error(`compactionAlias ${settings.compactionAlias} is not a configured role`);
  return { roles, settings, defaults, warnings };
}

function resetFromText(message, nowMs) {
  const match = message.match(/resets?\s+(?:at\s+)?(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?/i);
  if (!match) return undefined;
  let hour = Number(match[1]);
  if (match[3]?.toUpperCase() === "PM" && hour < 12) hour += 12;
  if (match[3]?.toUpperCase() === "AM" && hour === 12) hour = 0;
  const date = new Date(nowMs); date.setHours(hour, Number(match[2]), 0, 0);
  if (date.getTime() <= nowMs) date.setDate(date.getDate() + 1);
  return date.getTime();
}

export function classifyFailure(errorMessage, provider, nowMs = Date.now()) {
  const text = String(errorMessage ?? "");
  const quota = /rate limit \((?:five_hour|seven_day)|usage limit has been reached|GoUsageLimitError|Monthly usage limit reached|Insufficient account funds|insufficient_quota|out of budget|billing/i;
  if (quota.test(text)) return { kind: "quota", ...(resetFromText(text, nowMs) ? { resetsAt: resetFromText(text, nowMs) } : {}) };
  if (/rate.?limit|429|50[0234]|server.?error|overloaded|timed? out|timeout|connection/i.test(text)) return { kind: "transient" };
  return { kind: "other" };
}

const epochMs = (value) => {
  if (typeof value === "number" && Number.isFinite(value)) return value < 10_000_000_000 ? value * 1000 : value;
  if (typeof value === "string") { const parsed = Date.parse(value); if (Number.isFinite(parsed)) return parsed; }
  return undefined;
};
const percent = (value) => typeof value === "number" && Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : undefined;

export function parseCodexRateLimits(data, capturedAt = Date.now()) {
  if (data?.type !== "codex.rate_limits" || !data.rate_limits) return null;
  const windows = [];
  for (const [id, raw] of Object.entries(data.rate_limits)) {
    if (!raw || typeof raw !== "object") continue;
    const usedPercent = percent(raw.used_percent); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: Boolean(data.rate_limits.limit_reached || raw.limit_reached), ...(epochMs(raw.reset_at) ? { resetsAt: epochMs(raw.reset_at) } : {}) });
  }
  return windows.length ? { provider: "openai-codex", capturedAt, windows } : null;
}
export function parseClaudeRateLimit(data, capturedAt = Date.now()) {
  if (!data || !["allowed", "allowed_warning", "rejected"].includes(data.status)) return null;
  const usedPercent = percent(Number(data.utilization ?? (data.status === "rejected" ? 1 : 0)) * 100);
  return { provider: "claude-bridge", capturedAt, windows: [{ id: data.rateLimitType ?? "subscription", usedPercent, limited: data.status === "rejected", ...(epochMs(data.resetsAt) ? { resetsAt: epochMs(data.resetsAt) } : {}) }] };
}
export function parseOpenCodeUsage(data, capturedAt = Date.now()) {
  const windows = [];
  for (const [id, raw] of Object.entries(data?.usage ?? {})) {
    const usedPercent = percent(raw?.percent); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: raw.status === "rate-limited", ...(epochMs(raw.resetsAt) ? { resetsAt: epochMs(raw.resetsAt) } : {}) });
  }
  if (!windows.length) throw new Error("OpenCode usage response has no valid windows");
  return { provider: "opencode-go", capturedAt, windows };
}

function providerOf(ref) { return parseModelRef(ref).provider; }
function providerUsedPercent(snapshot) {
  return Math.max(0, ...(snapshot?.windows ?? []).map((window) => Number(window.usedPercent) || 0));
}

export function selectTarget(input) {
  const { chain, routeReason, current, previous, failed, contextTokens, cooldowns, usage, settings, nowMs } = input;
  if (!Array.isArray(chain) || !chain.length) throw new Error("selectTarget requires a non-empty chain");
  const cooled = (target) => (cooldowns[target]?.nextRetryAt ?? 0) > nowMs;
  const overUsage = (target) => routeReason === "user" && providerUsedPercent(usage[providerOf(target)]) >= settings.switchAboveUsedPercent;
  const available = (target) => !cooled(target) && !overUsage(target);
  let ordered = chain;
  if (routeReason === "retry" || (routeReason === "continuation" && previous && !available(previous))) {
    const from = failed ?? previous;
    const index = chain.indexOf(from);
    ordered = index < 0 ? chain : [...chain.slice(index + 1), ...chain.slice(0, index + 1)];
  }
  let target;
  if (routeReason === "continuation" && previous && available(previous)) target = previous;
  else if (routeReason === "user" && contextTokens !== null && contextTokens >= settings.confirmSwitchAboveTokens && current && available(current)) target = current;
  else target = ordered.find(available);
  if (!target) {
    const allCooled = chain.every(cooled);
    target = allCooled
      ? [...chain].sort((a, b) => cooldowns[a].nextRetryAt - cooldowns[b].nextRetryAt)[0]
      : [...chain].sort((a, b) => providerUsedPercent(usage[providerOf(a)]) - providerUsedPercent(usage[providerOf(b)]))[0];
  }
  const origin = routeReason === "retry" ? failed : (previous ?? current);
  const crossesProvider = Boolean(origin && providerOf(origin) !== providerOf(target));
  const large = contextTokens !== null && contextTokens >= settings.confirmSwitchAboveTokens;
  return { target, crossesProvider, needsConfirmation: crossesProvider && large, reason: available(target) ? "available" : "least-unavailable" };
}

export function recoveryAction(policy, mode, compactFailed) {
  if (policy === "fail") return "stop";
  if (policy === "compact" && !compactFailed && (mode === "interactive" || mode === "rpc")) return "compact";
  return "switch";
}

export function advanceResume(state, routeId, cap = 2) {
  const count = state.routeId === routeId ? state.count : 0;
  if (count >= cap) return { allowed: false, state: { routeId, count } };
  return { allowed: true, state: { routeId, count: count + 1 } };
}

export function recordFailure(entry, failure, policy, nowMs = Date.now()) {
  const failCount = (entry?.failCount ?? 0) + 1;
  const backoff = Math.min(policy.capMs, policy.baseMs * 2 ** (failCount - 1));
  const reset = Number.isFinite(failure?.resetsAt) && failure.resetsAt > nowMs ? failure.resetsAt : undefined;
  return { failCount, successCount: 0, nextRetryAt: reset ?? nowMs + backoff };
}
export function recordSuccess(entry, resetSuccesses) {
  if (!entry) return undefined;
  const successCount = (entry.successCount ?? 0) + 1;
  return successCount >= resetSuccesses ? undefined : { ...entry, successCount };
}
