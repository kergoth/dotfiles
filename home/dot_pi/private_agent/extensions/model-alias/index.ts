import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";
import { clampThinkingLevel, getSupportedThinkingLevels, isRetryableAssistantError, type AssistantMessage, type ModelThinkingLevel } from "@earendil-works/pi-ai";
import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { advanceResume, classifyFailure, parseCodexRateLimits, parseConfig, parseModelRef, recordFailure, recordSuccess, recoveryAction, selectTarget } from "./model-alias-core.js";
import { appendEvent, readState, resolveStatePaths, updateState } from "./model-alias-store.js";
import { fetchOpenCodeUsage } from "./model-alias-usage.js";

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

  const clearWatchdog = () => { if (activeTimer) clearTimeout(activeTimer); activeTimer = undefined; };
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
  const expireWatchdog = async () => {
    activeTimer = undefined;
    if (!activeTarget || !ctx) return;
    const target = activeTarget;
    await updateState(statePaths, (state) => { state.targets[target] = recordFailure(state.targets[target], { kind: "transient" }, config.defaults.cooldown, Date.now()); });
    await appendEvent(statePaths, { type: "stall", target, phase: firstEvent ? "first-event" : "event-gap", timestamp: Date.now() });
    queueResume();
    ctx.abort();
  };
  const armWatchdog = (ms: number) => { clearWatchdog(); activeTimer = setTimeout(() => { void expireWatchdog(); }, ms); };

  for (const warning of config.warnings) console.warn(`[model-alias] ${warning}`);

  function registerRole(role: string, metadata?: { contextWindow?: number; maxTokens?: number; input?: readonly ("text" | "image")[]; thinkingLevels?: readonly ModelThinkingLevel[] }) {
    pi.registerVirtualModel<SessionState>({
      provider: "alias", id: role, name: `Alias: ${role}`,
      contextWindow: metadata?.contextWindow ?? STARTUP_CONTEXT,
      maxTokens: metadata?.maxTokens ?? STARTUP_OUTPUT,
      input: metadata?.input ?? ["text", "image"],
      thinkingLevels: metadata?.thinkingLevels ?? ["off", "minimal", "low", "medium", "high", "xhigh"],
      async route(request, routeCtx) {
        if (request.reason === "user" && !resuming) { routeId += 1; resumeState = { routeId, count: 0 }; }
        resuming = false;
        const routeRole = request.reason === "direct" && compactionInProgress ? config.settings.compactionAlias : role;
        const chain = config.roles.get(routeRole) ?? [];
        let shared = await readState(statePaths.state);
        const openCodeTarget = chain.map(parseModelRef).find((ref) => ref.provider === "opencode-go");
        if (openCodeTarget && Date.now() >= openCodePollAt) {
          openCodePollAt = Date.now() + config.settings.opencodeUsagePollMs;
          const model = routeCtx.modelRegistry.find(openCodeTarget.provider, openCodeTarget.modelId);
          if (model) try {
            const auth = await routeCtx.modelRegistry.getApiKeyAndHeaders(model);
            if (!auth.ok) throw new Error(auth.error);
            const snapshot = await fetchOpenCodeUsage("https://opencode.ai/zen/go/v1/usage", auth.headers ?? (auth.apiKey ? { Authorization: `Bearer ${auth.apiKey}` } : {}));
            await updateState(statePaths, (state) => { state.usage[snapshot.provider] = snapshot; });
            shared = await readState(statePaths.state);
          } catch (error) {
            await appendEvent(statePaths, { type: "usage-error", provider: "opencode-go", reason: error instanceof Error ? error.message : String(error), timestamp: Date.now() });
          }
        }
        const previous = request.previous ? `${request.previous.model.provider}/${request.previous.model.id}` : undefined;
        const failed = request.failed ? `${request.failed.model.provider}/${request.failed.model.id}` : undefined;
        const selected = pendingTarget && chain.includes(pendingTarget)
          ? { target: pendingTarget, crossesProvider: true, needsConfirmation: false, reason: "pending-recovery" }
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
        activeTarget = selected.target;
        if (request.reason !== "direct") { firstEvent = true; armWatchdog(config.defaults.timeouts.firstEventMs); }
        if (pendingTarget === selected.target) pendingTarget = undefined;
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
      const first = chain.map(parseModelRef).map((ref) => sessionCtx.modelRegistry.find(ref.provider, ref.modelId)).find(Boolean);
      if (!first) { sessionCtx.ui.notify(`model-alias: ${role} has no resolvable targets`, "warning"); continue; }
      registerRole(role, { contextWindow: first.contextWindow, maxTokens: first.maxTokens, input: first.input, thinkingLevels: getSupportedThinkingLevels(first) });
    }
    await registerForChildren(sessionCtx.sessionManager.getSessionId());
  });

  pi.on("provider_stream_event", async (event) => {
    const snapshot = parseCodexRateLimits(event.data, Date.now());
    if (!snapshot) return;
    await updateState(statePaths, (state) => {
      state.usage[snapshot.provider] = snapshot;
      const reset = snapshot.windows.filter((window) => window.limited && window.resetsAt).map((window) => window.resetsAt!);
      if (reset.length) for (const targets of config.roles.values()) for (const target of targets) if (parseModelRef(target).provider === snapshot.provider) state.targets[target] = { failCount: 1, successCount: 0, nextRetryAt: Math.max(...reset) };
    });
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

  pi.on("session_shutdown", () => { clearWatchdog(); requiredRegistration?.dispose(); requiredRegistration = undefined; ctx = undefined; });
}
