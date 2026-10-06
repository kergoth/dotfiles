import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";
import { clampThinkingLevel, getSupportedThinkingLevels, isRetryableAssistantError, type AssistantMessage, type ModelThinkingLevel } from "@earendil-works/pi-ai";
import { getAgentDir, type ExtensionAPI, type ExtensionContext, type ModelRouteReason } from "@earendil-works/pi-coding-agent";
import { classifyFailure, parseConfig, parseModelRef, recordFailure, recordSuccess, selectTarget } from "./model-alias-core.js";
import { appendEvent, readState, resolveStatePaths, updateState } from "./model-alias-store.js";

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

  for (const warning of config.warnings) console.warn(`[model-alias] ${warning}`);

  function registerRole(role: string, metadata?: { contextWindow?: number; maxTokens?: number; input?: readonly ("text" | "image")[]; thinkingLevels?: readonly ModelThinkingLevel[] }) {
    pi.registerVirtualModel<SessionState>({
      provider: "alias", id: role, name: `Alias: ${role}`,
      contextWindow: metadata?.contextWindow ?? STARTUP_CONTEXT,
      maxTokens: metadata?.maxTokens ?? STARTUP_OUTPUT,
      input: metadata?.input ?? ["text", "image"],
      thinkingLevels: metadata?.thinkingLevels ?? ["off", "minimal", "low", "medium", "high", "xhigh"],
      async route(request, routeCtx) {
        const chain = config.roles.get(role) ?? [];
        const shared = await readState(statePaths.state);
        const previous = request.previous ? `${request.previous.model.provider}/${request.previous.model.id}` : undefined;
        const failed = request.failed ? `${request.failed.model.provider}/${request.failed.model.id}` : undefined;
        const selected = selectTarget({ routeReason: request.reason, chain, current: request.state?.current, previous, failed, contextTokens: routeCtx.getContextUsage()?.tokens ?? null, cooldowns: shared.targets, usage: shared.usage, settings: config.settings, nowMs: Date.now() });
        const ref = parseModelRef(selected.target);
        const model = routeCtx.modelRegistry.find(ref.provider, ref.modelId);
        if (!model) throw new Error(`model-alias: target not found: ${selected.target}`);
        activeTarget = selected.target;
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

  pi.on("message_end", async (event) => {
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

  pi.on("session_shutdown", () => { requiredRegistration?.dispose(); requiredRegistration = undefined; ctx = undefined; });
}
