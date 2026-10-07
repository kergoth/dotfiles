import { parseClaudeUsage, parseCodexUsage, parseOpenCodeUsage } from "./model-alias-core.js";

export async function fetchOpenCodeUsage(url, headers, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(new Error("OpenCode usage timeout")), options.timeoutMs ?? 15000);
  try {
    const response = await fetch(url, { method: "GET", headers, redirect: "manual", signal: controller.signal });
    if (response.status >= 300 && response.status < 400) throw new Error("OpenCode usage redirect rejected");
    if (!response.ok) throw new Error(`OpenCode usage HTTP ${response.status}`);
    const reader = response.body?.getReader();
    if (!reader) throw new Error("OpenCode usage response has no body");
    const chunks = []; let size = 0;
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > (options.maxBytes ?? 65536)) { await reader.cancel(); throw new Error("OpenCode usage response too large"); }
      chunks.push(value);
    }
    const body = Buffer.concat(chunks.map((chunk) => Buffer.from(chunk))).toString("utf8");
    let data;
    try { data = JSON.parse(body); } catch { throw new Error("OpenCode usage response is invalid JSON"); }
    return parseOpenCodeUsage(data, Date.now());
  } finally { clearTimeout(timeout); }
}

// Undocumented ChatGPT backend endpoint, the one the Codex CLI itself calls; it may change without notice.
const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";

export function codexAccountId(token) {
  try {
    return JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString())["https://api.openai.com/auth"]?.chatgpt_account_id;
  } catch { return undefined; }
}

export async function fetchCodexUsage(token, options = {}) {
  const accountId = codexAccountId(token);
  if (!accountId) throw new Error("Codex token carries no ChatGPT account id");
  const response = await fetch(options.url ?? CODEX_USAGE_URL, {
    method: "GET", redirect: "manual", signal: AbortSignal.timeout(options.timeoutMs ?? 15000),
    headers: { Authorization: `Bearer ${token}`, "ChatGPT-Account-Id": accountId },
  });
  if (response.status >= 300 && response.status < 400) throw new Error("Codex usage redirect rejected");
  if (!response.ok) throw new Error(`Codex usage HTTP ${response.status}`);
  let data;
  try { data = await response.json(); } catch { throw new Error("Codex usage response is invalid JSON"); }
  return parseCodexUsage(data, Date.now());
}

// Reads plan utilization through the Agent SDK's experimental usage call on a throwaway session, so no
// Claude credential passes through this code. pi-claude-bridge disables nonessential traffic in pi's own
// environment, which makes the CLI skip the usage fetch, so that variable is removed for this child only.
// pi also exports CLAUDE_CODE_OAUTH_TOKEN, a setup-token limited to the user:inference scope; the usage
// endpoint needs user:profile, so the child must fall back to the interactive Claude Code login instead.
export async function fetchClaudeUsage(loadSdk, options = {}) {
  const { query } = await loadSdk();
  const env = { ...process.env };
  delete env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC;
  delete env.CLAUDE_CODE_OAUTH_TOKEN;
  const session = query({
    prompt: (async function* () { await new Promise(() => {}); })(),
    options: { persistSession: false, settingSources: [], strictMcpConfig: true, env },
  });
  let timer;
  try {
    const data = await Promise.race([
      session.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET({ skipBehaviors: true }),
      new Promise((_resolve, reject) => { timer = setTimeout(() => reject(new Error("Claude usage timeout")), options.timeoutMs ?? 30000); }),
    ]);
    return parseClaudeUsage(data, Date.now());
  } finally { clearTimeout(timer); session.close(); }
}
