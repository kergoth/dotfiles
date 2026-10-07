export const DEFAULT_PACING_SETTINGS = Object.freeze({
  monthlyTimeZones: Object.freeze({}),
  warningMinPercent: Object.freeze({ fiveHour: 30, sevenDay: 20, monthly: 20 }),
  staleAfterMs: 30 * 60_000,
});

export function parsePacingConfig(raw = {}) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("usagePacing must be an object");
  const settings = { ...DEFAULT_PACING_SETTINGS, ...raw };
  for (const key of ["monthlyTimeZones", "warningMinPercent"]) {
    if (!settings[key] || typeof settings[key] !== "object" || Array.isArray(settings[key])) throw new Error(`usagePacing.${key} must be an object`);
  }
  settings.warningMinPercent = { ...DEFAULT_PACING_SETTINGS.warningMinPercent, ...settings.warningMinPercent };
  for (const [gauge, value] of Object.entries(settings.warningMinPercent)) {
    if (!Object.hasOwn(DEFAULT_PACING_SETTINGS.warningMinPercent, gauge) || !Number.isFinite(value) || value < 0 || value > 100) throw new Error(`usagePacing.warningMinPercent.${gauge} must be a known gauge with a percentage from 0 to 100`);
  }
  for (const [provider, zone] of Object.entries(settings.monthlyTimeZones)) {
    if (typeof zone !== "string" || !zone) throw new Error(`usagePacing.monthlyTimeZones.${provider} must be a timezone`);
    try { new Intl.DateTimeFormat("en-US", { timeZone: zone }); }
    catch { throw new Error(`usagePacing.monthlyTimeZones.${provider} must be a valid timezone`); }
  }
  if (!Number.isFinite(settings.staleAfterMs) || settings.staleAfterMs <= 0) throw new Error("usagePacing.staleAfterMs must be positive");
  return settings;
}

const GAUGES = {
  five_hour: "fiveHour", primary: "fiveHour", rolling: "fiveHour",
  seven_day: "sevenDay", secondary: "sevenDay", weekly: "sevenDay",
  spend: "monthly", monthly: "monthly",
};
const DURATIONS = { fiveHour: 5 * 3600_000, sevenDay: 7 * 86400_000 };

function calendarMonth(zone, referenceMs) {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: zone, hourCycle: "h23", year: "numeric", month: "numeric", day: "numeric",
    hour: "numeric", minute: "numeric", second: "numeric",
  });
  const partsAt = (ms) => Object.fromEntries(formatter.formatToParts(ms).map((part) => [part.type, Number(part.value)]));
  const local = partsAt(referenceMs);
  const midnight = (year, month) => {
    const wall = Date.UTC(year, month - 1, 1);
    let guess = wall;
    // Month boundaries can have a different UTC offset from the reference date.
    for (let pass = 0; pass < 3; pass++) {
      const at = partsAt(guess);
      const offset = wall - Date.UTC(at.year, at.month - 1, at.day, at.hour, at.minute, at.second);
      if (!offset) return guess;
      guess += offset;
    }
    return undefined;
  };
  const next = new Date(Date.UTC(local.year, local.month, 1));
  return { startsAt: midnight(local.year, local.month), resetsAt: midnight(next.getUTCFullYear(), next.getUTCMonth() + 1) };
}

export function usagePace(window, snapshot, nowMs, limitPercent = 95, settings = DEFAULT_PACING_SETTINGS) {
  const gauge = GAUGES[window.id];
  const capturedAt = window.capturedAt ?? snapshot?.capturedAt;
  const stale = !Number.isFinite(capturedAt) || capturedAt > nowMs || nowMs - capturedAt > settings.staleAfterMs;
  let startsAt = window.startsAt;
  let resetsAt = window.resetsAt;
  let assumption;
  if (!Number.isFinite(startsAt)) {
    const duration = window.durationMs ?? DURATIONS[gauge];
    if (Number.isFinite(resetsAt) && Number.isFinite(duration) && duration > 0) startsAt = resetsAt - duration;
    else if (gauge === "monthly" && settings.monthlyTimeZones[snapshot?.provider]) {
      const zone = settings.monthlyTimeZones[snapshot.provider];
      const month = calendarMonth(zone, Number.isFinite(resetsAt) ? resetsAt - 1 : nowMs);
      startsAt = month.startsAt;
      if (!Number.isFinite(resetsAt)) resetsAt = month.resetsAt;
      assumption = `assumes monthly reset on 1st, ${zone}`;
    }
  }
  const expired = (Number.isFinite(resetsAt) && resetsAt <= nowMs)
    || (Number.isFinite(startsAt) && Number.isFinite(capturedAt) && capturedAt < startsAt);
  const result = { stale, expired, startsAt, resetsAt, assumption, warningMinPercent: settings.warningMinPercent[gauge] };
  const used = window.usedPercent;
  if (stale || expired || !Number.isFinite(startsAt) || !Number.isFinite(resetsAt)
      || capturedAt <= startsAt || capturedAt >= resetsAt || resetsAt <= startsAt
      || !Number.isFinite(used) || used < 0 || !Number.isFinite(limitPercent) || limitPercent <= 0) return result;
  // Use the reading's timestamp: idle time must not make unchanged, older usage look sustainable.
  const elapsed = capturedAt - startsAt;
  const projectedPercent = used * (resetsAt - startsAt) / elapsed;
  const overPace = projectedPercent > limitPercent;
  const timeToLimitMs = used > 0 ? Math.max(0, startsAt + elapsed * limitPercent / used - nowMs) : undefined;
  return { ...result, projectedPercent, overPace, timeToLimitMs };
}

export function paceDuration(ms) {
  const minutes = Math.max(0, Math.ceil(ms / 60_000));
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  return hours < 48 ? `${hours}h${minutes % 60}m` : `${Math.floor(hours / 24)}d${hours % 24}h`;
}
