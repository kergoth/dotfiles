import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import { join } from "node:path";
import { clampThinkingLevel, getSupportedThinkingLevels, isRetryableAssistantError, type AssistantMessage, type ModelThinkingLevel } from "@earendil-works/pi-ai";
import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { advanceResume, classifyFailure, clearCooldowns, configuredTargets, formatStatus, formatUsage, filterResolvedTargets, mergeUsage, parseClaudeRateLimit, parseCodexRateLimits, parseConfig, parseModelRef, ownsSessionState, pendingRecoveryTarget, recordFailure, recordSuccess, recoveryAction, selectTarget, watchdogStillCurrent } from "./model-alias-core.js";
import { appendEvent, readState, resolveStatePaths, updateState } from "./model-alias-store.js";
import { fetchClaudeUsage, fetchCodexUsage, fetchOpenCodeUsage } from "./model-alias-usage.js";

const agentDir = getAgentDir();
const mapPath = process.env.PI_MODEL_ALIAS_MAP || join(agentDir, "model-alias.json");
const statePaths = resolveStatePaths(process.env, agentDir);
const raw = JSON.parse(readFileSync(mapPath, "utf8"));
const config = parseConfig(raw);

type SessionState = { current?: string };
const STARTUP_CONTEXT = 1_000_000;
const STARTUP_OUTPUT = 128_000;

export default function modelAlias(pi: ExtensionAPI): void {
  let ctx: ExtensionContext | undefined;
  let requiredRegistration: { dispose(): void } | undefined;
  let disposeClaudeEvents: (() => void) | undefined;
  let activeTarget: string | undefined;
  let activeTimer: ReturnType<typeof setTimeout> | undefined;
  let firstEvent = true;
  let pendingTarget: string | undefined;
  let pendingCompaction = false;
  let compactionInProgress = false;
  let pendingResume = false;
  let resuming = false;
  let routeId = 0;
  let resumeState = { routeId: 0, count: 0 };
  let openCodePollAt = 0;
  let watchdogGeneration = 0;

  const clearWatchdog = () => { watchdogGeneration += 1; if (activeTimer) clearTimeout(activeTimer); activeTimer = undefined; };
  const queueResume = () => {
    const next = advanceResume(resumeState, routeId, 2);
    resumeState = next.state;
    if (!next.allowed) { ctx?.ui.notify("model-alias: automatic recovery stopped after two resumes", "error"); pendingResume = false; pendingTarget = undefined; return; }
    pendingResume = true;
  };
  const sendResume = () => {
    if (!pendingResume) return;
    pendingResume = false;
    resuming = true;
    pi.sendMessage({ customType: "model-alias-resume", content: "Continue after model alias recovery.", display: false }, { triggerTurn: true, deliverAs: "followUp" });
  };
  const expireWatchdog = async (generation: number, target: string, phase: string) => {
    activeTimer = undefined;
    let expired = false;
    await updateState(statePaths, (state) => {
      expired = watchdogStillCurrent(generation, watchdogGeneration, Boolean(ctx));
      if (expired) state.targets[target] = recordFailure(state.targets[target], { kind: "transient" }, config.defaults.cooldown, Date.now());
    });
    if (!expired || !watchdogStillCurrent(generation, watchdogGeneration, Boolean(ctx))) return;
    await appendEvent(statePaths, { type: "stall", target, phase, timestamp: Date.now() });
    if (!watchdogStillCurrent(generation, watchdogGeneration, Boolean(ctx))) return;
    queueResume();
    ctx!.abort();
  };
  const armWatchdog = (ms: number) => {
    clearWatchdog();
    if (!activeTarget) return;
    const generation = watchdogGeneration;
    const target = activeTarget;
    const phase = firstEvent ? "first-event" : "event-gap";
    activeTimer = setTimeout(() => { void expireWatchdog(generation, target, phase); }, ms);
  };

  for (const warning of config.warnings) console.warn(`[model-alias] ${warning}`);

  async function persistUsage(snapshot: ReturnType<typeof parseClaudeRateLimit> | ReturnType<typeof parseCodexRateLimits>) {
    if (!snapshot) return;
    await updateState(statePaths, (state) => {
      state.usage[snapshot.provider] = mergeUsage(state.usage[snapshot.provider], snapshot);
      const reset = snapshot.windows.filter((window) => window.limited && window.resetsAt).map((window) => window.resetsAt!);
      if (reset.length) for (const targets of config.roles.values()) for (const target of targets) if (parseModelRef(target).provider === snapshot.provider) {
        const previous = state.targets[target];
        state.targets[target] = { failCount: Math.max(1, previous?.failCount ?? 0), successCount: 0, nextRetryAt: Math.max(previous?.nextRetryAt ?? 0, ...reset) };
      }
    });
  }

  async function pollOpenCode(registry: ExtensionContext["modelRegistry"], ref: ReturnType<typeof parseModelRef>) {
    const model = registry.find(ref.provider, ref.modelId);
    if (!model) throw new Error(`${ref.provider}/${ref.modelId} is not registered`);
    const auth = await registry.getApiKeyAndHeaders(model);
    if (!auth.ok) throw new Error(auth.error);
    return fetchOpenCodeUsage("https://opencode.ai/zen/go/v1/usage", auth.headers ?? (auth.apiKey ? { Authorization: `Bearer ${auth.apiKey}` } : {}));
  }

  const loadClaudeSdk = async () => {
    const require = createRequire(join(agentDir, "npm", "package.json"));
    return import(pathToFileURL(require.resolve("@anthropic-ai/claude-agent-sdk")).href);
  };

  // Fetches live utilization for every provider an alias chain uses, so `/alias usage` never reports a snapshot left over from the last time that provider streamed.
  async function refreshUsage(registry: ExtensionContext["modelRegistry"]) {
    const refs = [...new Set([...config.roles.values()].flat())].map(parseModelRef);
    const firstOf = (provider: string) => refs.find((ref) => ref.provider === provider);
    const fetchers: Record<string, (ref: ReturnType<typeof parseModelRef>) => Promise<NonNullable<ReturnType<typeof parseClaudeRateLimit>>>> = {
      "claude-bridge": () => fetchClaudeUsage(loadClaudeSdk),
      "openai-codex": async (ref) => {
        const model = registry.find(ref.provider, ref.modelId);
        if (!model) throw new Error(`${ref.provider}/${ref.modelId} is not registered`);
        const auth = await registry.getApiKeyAndHeaders(model);
        if (!auth.ok || !auth.apiKey) throw new Error(auth.ok ? "no Codex token" : auth.error);
        return fetchCodexUsage(auth.apiKey);
      },
      "opencode-go": (ref) => pollOpenCode(registry, ref),
    };
    const providers = Object.keys(fetchers).filter((provider) => firstOf(provider));
    const refresh: Record<string, { ok: boolean; error?: string }> = {};
    await Promise.all(providers.map(async (provider) => {
      try {
        await persistUsage(await fetchers[provider](firstOf(provider)!));
        refresh[provider] = { ok: true };
      } catch (error) {
        refresh[provider] = { ok: false, error: error instanceof Error ? error.message : String(error) };
        await appendEvent(statePaths, { type: "usage-error", provider, reason: refresh[provider].error, timestamp: Date.now() });
      }
    }));
    return { providers, refresh };
  }

  function registerRole(role: string, metadata?: { contextWindow?: number; maxTokens?: number; input?: readonly ("text" | "image")[]; thinkingLevels?: readonly ModelThinkingLevel[] }) {
    pi.registerVirtualModel<SessionState>({
      provider: "alias", id: role, name: `Alias: ${role}`,
      contextWindow: metadata?.contextWindow ?? STARTUP_CONTEXT,
      maxTokens: metadata?.maxTokens ?? STARTUP_OUTPUT,
      input: metadata?.input ?? ["text", "image"],
      thinkingLevels: metadata?.thinkingLevels ?? ["off", "minimal", "low", "medium", "high", "xhigh"],
      async route(request, routeCtx) {
        if (request.reason === "user" && !resuming) { routeId += 1; resumeState = { routeId, count: 0 }; }
        if (ownsSessionState(request.reason)) resuming = false;
        const routeRole = request.reason === "direct" && compactionInProgress ? config.settings.compactionAlias : role;
        const configuredChain = config.roles.get(routeRole) ?? [];
        const chain = filterResolvedTargets(configuredChain, (target) => { const ref = parseModelRef(target); return Boolean(routeCtx.modelRegistry.find(ref.provider, ref.modelId)); });
        let shared = await readState(statePaths.state);
        const openCodeTarget = chain.map(parseModelRef).find((ref) => ref.provider === "opencode-go");
        if (openCodeTarget && Date.now() >= openCodePollAt) {
          openCodePollAt = Date.now() + config.settings.opencodeUsagePollMs;
          try {
            await persistUsage(await pollOpenCode(routeCtx.modelRegistry, openCodeTarget));
            shared = await readState(statePaths.state);
          } catch (error) {
            await appendEvent(statePaths, { type: "usage-error", provider: "opencode-go", reason: error instanceof Error ? error.message : String(error), timestamp: Date.now() });
          }
        }
        const previous = request.previous ? `${request.previous.model.provider}/${request.previous.model.id}` : undefined;
        const failed = request.failed ? `${request.failed.model.provider}/${request.failed.model.id}` : undefined;
        const recoveryTarget = pendingRecoveryTarget(request.reason, pendingTarget, chain);
        const selected = recoveryTarget
          ? { target: recoveryTarget, crossesProvider: true, needsConfirmation: false, reason: "pending-recovery" }
          : selectTarget({ routeReason: request.reason, chain, current: request.state?.current, previous, failed, contextTokens: routeCtx.getContextUsage()?.tokens ?? null, cooldowns: shared.targets, usage: shared.usage, settings: config.settings, nowMs: Date.now() });
        if (selected.needsConfirmation && !pendingTarget) {
          const fallback = recoveryAction(config.settings.unattendedSwitch, routeCtx.mode === "tui" ? "interactive" : routeCtx.mode, false);
          let action = fallback;
          if (routeCtx.hasUI) {
            const options = ["Switch provider", "Compact then switch", "Stop"];
            const answer = await routeCtx.ui.select(`Switch a ${routeCtx.getContextUsage()?.tokens ?? "large"}-token session to ${selected.target}?`, options, { timeout: config.settings.confirmTimeoutMs });
            action = answer === options[0] ? "switch" : answer === options[1] ? "compact" : answer === options[2] ? "stop" : fallback;
          }
          if (action === "stop") throw new Error("model-alias: cross-provider switch declined");
          if (action === "compact") { pendingTarget = selected.target; pendingCompaction = true; throw new Error("model-alias: compacting before cross-provider switch"); }
        }
        const ref = parseModelRef(selected.target);
        const model = routeCtx.modelRegistry.find(ref.provider, ref.modelId);
        if (!model) throw new Error(`model-alias: target not found: ${selected.target}`);
        if (ownsSessionState(request.reason)) activeTarget = selected.target;
        if (request.reason !== "direct") { firstEvent = true; armWatchdog(config.defaults.timeouts.firstEventMs); }
        if (request.reason !== "direct" && pendingTarget === selected.target) pendingTarget = undefined;
        return { model, thinkingLevel: clampThinkingLevel(model, request.thinkingLevel), state: request.state?.current === selected.target ? request.state : { current: selected.target } };
      },
    });
  }

  for (const role of config.roles.keys()) registerRole(role);

  async function registerForChildren(sessionId: string) {
    try {
      const require = createRequire(join(agentDir, "npm", "package.json"));
      const { registerRequiredChildExtensions } = await import(require.resolve("pi-subagents/required-child-extensions"));
      requiredRegistration = registerRequiredChildExtensions({ sessionId, extensions: [{ id: "model-alias", path: fileURLToPath(import.meta.url) }] });
    } catch (error) {
      await appendEvent(statePaths, { type: "subagent-registration-unavailable", reason: error instanceof Error ? error.message : String(error), timestamp: Date.now() });
    }
  }

  pi.on("session_start", async (_event, sessionCtx) => {
    ctx = sessionCtx;
    for (const [role, chain] of config.roles) {
      const models = chain.map(parseModelRef).map((ref) => sessionCtx.modelRegistry.find(ref.provider, ref.modelId)).filter((model) => model !== undefined);
      const first = models[0];
      if (!first) { sessionCtx.ui.notify(`model-alias: ${role} has no resolvable targets`, "warning"); continue; }
      if (models.length !== chain.length) sessionCtx.ui.notify(`model-alias: ${role} is skipping ${chain.length - models.length} unresolved target(s)`, "warning");
      const thinkingLevels = [...new Set(models.flatMap((model) => getSupportedThinkingLevels(model)))];
      registerRole(role, { contextWindow: first.contextWindow, maxTokens: first.maxTokens, input: first.input, thinkingLevels });
    }
    disposeClaudeEvents = pi.events.on("claude-bridge/rate-limit/v1", (data) => {
      const snapshot = parseClaudeRateLimit(data, Date.now());
      if (snapshot) void persistUsage(snapshot);
      else if (!["allowed", "allowed_warning", "rejected"].includes(data?.status)) void appendEvent(statePaths, { type: "usage-error", provider: "claude-bridge", reason: "invalid rate-limit event", timestamp: Date.now() });
    });
    await registerForChildren(sessionCtx.sessionManager.getSessionId());
  });

  pi.on("provider_stream_event", async (event) => {
    const snapshot = parseCodexRateLimits(event.data, Date.now());
    if (!snapshot) return;
    await persistUsage(snapshot);
  });

  const observeStreamEvent = () => {
    if (!activeTimer) return;
    firstEvent = false;
    armWatchdog(config.defaults.timeouts.stallMs);
  };
  pi.on("provider_stream_event", observeStreamEvent);
  pi.on("message_update", observeStreamEvent);

  pi.on("message_end", async (event) => {
    clearWatchdog();
    if (event.message.role !== "assistant") return;
    const message = event.message as AssistantMessage;
    const target = `${message.provider}/${message.model}`;
    const chain = [...config.roles.values()].find((targets) => targets.includes(target));
    if (!chain) return;
    if (message.stopReason === "stop" || message.stopReason === "toolUse") {
      await updateState(statePaths, (state) => { const next = recordSuccess(state.targets[target], config.defaults.cooldown.resetSuccesses); if (next) state.targets[target] = next; else delete state.targets[target]; });
      return;
    }
    if (message.stopReason !== "error") return;
    const failure = classifyFailure(message.errorMessage, message.provider, Date.now());
    if (failure.kind === "aborted") return;
    let anotherAvailable = false;
    await updateState(statePaths, (state) => {
      state.targets[target] = recordFailure(state.targets[target], failure, config.defaults.cooldown, Date.now());
      anotherAvailable = chain.some((candidate) => candidate !== target && (state.targets[candidate]?.nextRetryAt ?? 0) <= Date.now());
    });
    await appendEvent(statePaths, { type: "failure", target, kind: failure.kind, reason: message.errorMessage ?? "unknown", timestamp: Date.now() });
    if (failure.kind === "quota" && anotherAvailable && !isRetryableAssistantError(message)) return { message: { ...message, errorMessage: `rate limit: ${message.provider} quota exhausted [model-alias]` } };
  });

  pi.on("agent_settled", async () => {
    if (pendingCompaction && ctx) {
      pendingCompaction = false;
      compactionInProgress = true;
      ctx.compact({ onComplete: () => { compactionInProgress = false; queueResume(); sendResume(); }, onError: (error) => { compactionInProgress = false; ctx?.ui.notify(`model-alias: compaction failed, switching without it: ${error.message}`, "warning"); queueResume(); sendResume(); } });
      return;
    }
    sendResume();
  });

  pi.registerCommand("alias", {
    description: "Show alias routing and cooldowns, `usage` for live provider limits, or `reset [target]` to clear cooldowns",
    getArgumentCompletions: (prefix) => {
      const words = ["usage", "reset", ...configuredTargets(config.roles).map((target) => `reset ${target}`)];
      return words.filter((word) => word.startsWith(prefix)).map((word) => ({ value: word, label: word }));
    },
    handler: async (args, commandCtx) => {
      const [action, target, ...extra] = args.trim().split(/\s+/).filter(Boolean);
      if (!action) {
        const state = await readState(statePaths.state);
        commandCtx.ui.notify(formatStatus({ roles: config.roles, state, activeTarget, settings: config.settings, nowMs: Date.now() }), "info");
        return;
      }
      if (action === "usage" && !target) {
        commandCtx.ui.notify("model-alias: fetching live usage...", "info");
        const { providers, refresh } = await refreshUsage(commandCtx.modelRegistry);
        const state = await readState(statePaths.state);
        commandCtx.ui.notify(commandCtx.ui.theme.fg("text", formatUsage({ providers, state, settings: config.settings, refresh, nowMs: Date.now() })), "info");
        return;
      }
      if (action !== "reset" || extra.length) { commandCtx.ui.notify("usage: /alias [usage | reset [provider/model]]", "error"); return; }
      if (target && !configuredTargets(config.roles).includes(target)) { commandCtx.ui.notify(`model-alias: ${target} is not in any alias chain`, "error"); return; }
      let cleared: string[] = [];
      await updateState(statePaths, (state) => { cleared = clearCooldowns(state, target); });
      await appendEvent(statePaths, { type: "reset", target: target ?? "all", cleared, timestamp: Date.now() });
      commandCtx.ui.notify(cleared.length ? `model-alias: cleared cooldowns for ${cleared.join(", ")}` : "model-alias: no cooldowns to clear", "info");
    },
  });

  pi.on("session_shutdown", () => { clearWatchdog(); disposeClaudeEvents?.(); disposeClaudeEvents = undefined; requiredRegistration?.dispose(); requiredRegistration = undefined; ctx = undefined; });
}
