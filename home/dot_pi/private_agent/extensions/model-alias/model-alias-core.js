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
  const overrides = settings.providerSwitchAboveUsedPercent;
  if (overrides !== undefined) {
    if (!overrides || typeof overrides !== "object" || Array.isArray(overrides)) throw new Error("providerSwitchAboveUsedPercent must be an object");
    for (const [key, value] of Object.entries(overrides)) {
      if (typeof value !== "number" || value < 0 || value > 100) throw new Error(`providerSwitchAboveUsedPercent.${key} must be 0..100`);
    }
  }
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
  const providers = new Set([...roles.values()].flat().map((ref) => parseModelRef(ref).provider));
  for (const key of Object.keys(overrides ?? {})) {
    const provider = key.split(":", 1)[0];
    if (!providers.has(provider)) warnings.push(`$settings.providerSwitchAboveUsedPercent.${key} names a provider no role uses`);
  }
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
  if (/^aborted$|\b(?:operation|request) (?:was )?aborted\b/i.test(text)) return { kind: "aborted" };
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
    windows.push({ id, usedPercent, limited: Boolean(data.rate_limits.limit_reached || raw.limit_reached), capturedAt, ...(epochMs(raw.reset_at) ? { resetsAt: epochMs(raw.reset_at) } : {}) });
  }
  return windows.length ? { provider: "openai-codex", capturedAt, windows } : null;
}
const fractionToPercent = (fraction) => percent(Math.round(fraction * 10000) / 100);

export function parseClaudeRateLimit(data, capturedAt = Date.now()) {
  if (!data || !["allowed", "allowed_warning", "rejected"].includes(data.status)) return null;
  const rejected = data.status === "rejected";
  const headlineId = data.rateLimitType ?? "subscription";
  const windows = [];
  for (const [id, raw] of Object.entries(data.windows ?? {})) {
    const usedPercent = fractionToPercent(Number(raw?.utilization)); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: rejected && id === headlineId, capturedAt, ...(epochMs(raw.resetsAt) ? { resetsAt: epochMs(raw.resetsAt) } : {}) });
  }
  // A headline reading without a utilization is unknown, not zero; recording 0% would hide a nearly spent window.
  const headlineUsed = data.utilization === undefined ? (rejected ? 100 : undefined) : fractionToPercent(Number(data.utilization));
  if ((headlineUsed !== undefined || rejected) && !windows.some((window) => window.id === headlineId)) {
    windows.push({ id: headlineId, usedPercent: headlineUsed ?? 100, limited: rejected, capturedAt, ...(epochMs(data.resetsAt) ? { resetsAt: epochMs(data.resetsAt) } : {}) });
  }
  if (!windows.length) return null;
  return { provider: "claude-bridge", capturedAt, windows };
}
export function parseOpenCodeUsage(data, capturedAt = Date.now()) {
  const windows = [];
  for (const [id, raw] of Object.entries(data?.usage ?? {})) {
    const usedPercent = percent(raw?.percent); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: raw.status === "rate-limited", capturedAt, ...(epochMs(raw.resetsAt) ? { resetsAt: epochMs(raw.resetsAt) } : {}) });
  }
  if (!windows.length) throw new Error("OpenCode usage response has no valid windows");
  return { provider: "opencode-go", capturedAt, windows };
}

// Windows of the claude.ai usage response that routing may act on. The model-scoped weekly
// caps (opus, sonnet) are left out: one at 100% must not mark the whole provider unavailable.
const CLAUDE_USAGE_WINDOWS = ["five_hour", "seven_day"];
export function parseClaudeUsage(data, capturedAt = Date.now()) {
  const limits = data?.rate_limits;
  if (!limits) throw new Error("Claude plan rate limits are unavailable for this login");
  const windows = [];
  for (const id of CLAUDE_USAGE_WINDOWS) {
    const raw = limits[id];
    const usedPercent = percent(raw?.utilization); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: usedPercent >= 100, capturedAt, ...(epochMs(raw.resets_at) ? { resetsAt: epochMs(raw.resets_at) } : {}) });
  }
  // Enterprise logins bill by usage and report no five_hour/seven_day windows, only a monthly spend meter.
  // It gets its own id: the stream events' "overage" window measures something else and must not overwrite it.
  const spend = limits.extra_usage;
  const spendPercent = spend?.is_enabled ? percent(spend.utilization) : undefined;
  if (!windows.length && spendPercent !== undefined) {
    windows.push({ id: "spend", usedPercent: spendPercent, limited: Boolean(spend.spend_limit_reached) || spendPercent >= 100, capturedAt });
  }
  if (!windows.length) throw new Error("Claude usage response has no valid windows");
  return { provider: "claude-bridge", capturedAt, windows };
}
export function parseCodexUsage(data, capturedAt = Date.now()) {
  const limits = data?.rate_limit;
  const windows = [];
  for (const [id, key] of [["primary", "primary_window"], ["secondary", "secondary_window"]]) {
    const raw = limits?.[key];
    const usedPercent = percent(raw?.used_percent); if (usedPercent === undefined) continue;
    windows.push({ id, usedPercent, limited: Boolean(limits.limit_reached) || usedPercent >= 100, capturedAt, ...(epochMs(raw.reset_at) ? { resetsAt: epochMs(raw.reset_at) } : {}) });
  }
  if (!windows.length) throw new Error("Codex usage response has no valid windows");
  return { provider: "openai-codex", capturedAt, windows };
}

function providerOf(ref) { return parseModelRef(ref).provider; }
function providerUsedPercent(snapshot, nowMs) {
  const windows = (snapshot?.windows ?? []).filter((window) => !window.resetsAt || window.resetsAt > nowMs);
  return Math.max(0, ...windows.map((window) => Number(window.usedPercent) || 0));
}

// A "provider:window" key beats a "provider" key, which beats the global threshold.
function windowThreshold(settings, provider, windowId) {
  const overrides = settings.providerSwitchAboveUsedPercent ?? {};
  return overrides[`${provider}:${windowId}`] ?? overrides[provider] ?? settings.switchAboveUsedPercent;
}
function providerOverUsage(snapshot, provider, settings, nowMs) {
  return (snapshot?.windows ?? []).some((window) =>
    (!window.resetsAt || window.resetsAt > nowMs)
    && (window.limited || (Number(window.usedPercent) || 0) >= windowThreshold(settings, provider, window.id)));
}

export function mergeUsage(previous, incoming) {
  if (!previous || previous.provider !== incoming.provider) return incoming;
  const byId = new Map(previous.windows.map((window) => [window.id, window]));
  for (const window of incoming.windows) byId.set(window.id, window);
  return { ...incoming, windows: [...byId.values()] };
}

export function selectTarget(input) {
  const { chain, routeReason, current, previous, failed, contextTokens, cooldowns, usage, settings, nowMs } = input;
  if (!Array.isArray(chain) || !chain.length) throw new Error("selectTarget requires a non-empty chain");
  const cooled = (target) => (cooldowns[target]?.nextRetryAt ?? 0) > nowMs;
  const usedPercent = (target) => providerUsedPercent(usage[providerOf(target)], nowMs);
  const overUsage = (target) => routeReason === "user" && providerOverUsage(usage[providerOf(target)], providerOf(target), settings, nowMs);
  const available = (target) => !cooled(target) && !overUsage(target);
  const origin = routeReason === "retry" ? failed : (previous ?? current);
  const large = contextTokens !== null && contextTokens >= settings.confirmSwitchAboveTokens;
  const advance = routeReason === "retry" || ((routeReason === "continuation" || routeReason === "direct" || large) && origin && !available(origin));
  let ordered = chain;
  if (advance) {
    const index = chain.indexOf(origin);
    ordered = index < 0 ? chain : [...chain.slice(index + 1), ...chain.slice(0, index + 1)];
  }
  let target;
  if ((routeReason === "continuation" || routeReason === "direct") && origin && chain.includes(origin) && available(origin)) target = origin;
  else if (routeReason === "user" && large && current && chain.includes(current) && available(current)) target = current;
  else target = ordered.find(available);
  if (!target) {
    const notCooled = ordered.filter((candidate) => !cooled(candidate));
    target = notCooled.length
      ? [...notCooled].sort((a, b) => usedPercent(a) - usedPercent(b))[0]
      : [...ordered].sort((a, b) => cooldowns[a].nextRetryAt - cooldowns[b].nextRetryAt)[0];
  }
  const crossesProvider = Boolean(origin && providerOf(origin) !== providerOf(target));
  return { target, crossesProvider, needsConfirmation: crossesProvider && large, reason: available(target) ? "available" : "least-unavailable" };
}

// Direct requests (compaction, side calls such as session titling) run outside the agent turn and must not touch its recovery state.
export function ownsSessionState(routeReason) {
  return routeReason !== "direct";
}

export function pendingRecoveryTarget(routeReason, pendingTarget, chain) {
  return routeReason !== "direct" && pendingTarget && chain.includes(pendingTarget) ? pendingTarget : undefined;
}

export function filterResolvedTargets(chain, resolves) {
  const filtered = chain.filter(resolves);
  if (!filtered.length) throw new Error("model-alias role has no resolvable targets");
  return filtered;
}

export function watchdogStillCurrent(generation, currentGeneration, active) {
  return active && generation === currentGeneration;
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
  return { failCount, successCount: 0, nextRetryAt: Math.max(entry?.nextRetryAt ?? 0, reset ?? nowMs + backoff) };
}
export function recordSuccess(entry, resetSuccesses) {
  if (!entry) return undefined;
  const successCount = (entry.successCount ?? 0) + 1;
  return successCount >= resetSuccesses ? undefined : { ...entry, successCount };
}

export function configuredTargets(roles) {
  return [...new Set([...roles.values()].flat())];
}

export function clearCooldowns(state, target) {
  const cleared = Object.keys(state.targets).filter((candidate) => !target || candidate === target);
  for (const candidate of cleared) delete state.targets[candidate];
  return cleared;
}

const remaining = (ms) => {
  if (ms < 60_000) return `${Math.ceil(ms / 1000)}s`;
  const minutes = Math.ceil(ms / 60_000);
  return minutes < 60 ? `${minutes}m` : `${Math.floor(minutes / 60)}h${minutes % 60}m`;
};

export function formatStatus({ roles, state, activeTarget, settings, nowMs }) {
  const lines = [`model-alias: this session is on ${activeTarget ?? "no routed target yet"}`];
  for (const [role, chain] of roles) {
    lines.push(`${role}:`);
    for (const target of chain) {
      const notes = [];
      const retryAt = state.targets[target]?.nextRetryAt ?? 0;
      if (retryAt > nowMs) notes.push(`cooldown ${remaining(retryAt - nowMs)}`);
      const snapshot = state.usage[providerOf(target)];
      if (providerOverUsage(snapshot, providerOf(target), settings, nowMs)) notes.push(`usage ${providerUsedPercent(snapshot, nowMs)}%`);
      lines.push(`  ${target === activeTarget ? "*" : " "} ${target}${notes.length ? ` (${notes.join(", ")})` : ""}`);
    }
  }
  return lines.join("\n");
}

const duration = (ms) => {
  const minutes = Math.max(1, Math.ceil(ms / 60_000));
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  return hours < 48 ? `${hours}h${minutes % 60}m` : `${Math.floor(hours / 24)}d${hours % 24}h`;
};

// refresh maps provider -> { ok } or { ok: false, error }; a provider without an entry shows stored data.
export function formatUsage({ providers, state, settings, refresh = {}, nowMs }) {
  const lines = ["model-alias usage:"];
  for (const provider of providers) {
    const snapshot = state.usage[provider];
    const result = refresh[provider];
    lines.push(`${provider} (${result?.ok ? "refreshed" : result ? `not refreshed: ${result.error}` : "stored"}):`);
    if (!snapshot?.windows?.length) { lines.push("  no usage data yet"); continue; }
    for (const window of snapshot.windows) {
      const used = Math.round(Number(window.usedPercent) || 0);
      const parts = [];
      if (window.resetsAt && window.resetsAt <= nowMs) parts.push(`reset (last read ${used}%)`);
      else {
        const threshold = windowThreshold(settings, provider, window.id);
        parts.push(`${used}%`);
        if (window.resetsAt) parts.push(`resets in ${duration(window.resetsAt - nowMs)}`);
        parts.push(`limit ${threshold}%`);
        if (window.limited || used >= threshold) parts.push("OVER");
      }
      const age = nowMs - (window.capturedAt ?? snapshot.capturedAt ?? nowMs);
      if (age >= 60_000) parts.push(`as of ${duration(age)} ago`);
      lines.push(`  ${String(window.id).padEnd(10)} ${parts.join(", ")}`);
    }
  }
  return lines.join("\n");
}
