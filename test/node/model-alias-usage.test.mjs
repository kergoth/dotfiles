import assert from "node:assert/strict";
import { createServer } from "node:http";
import test from "node:test";

import { codexAccountId, fetchClaudeUsage, fetchCodexUsage, fetchOpenCodeUsage } from "../../home/dot_pi/private_agent/extensions/model-alias/model-alias-usage.js";

async function server(handler) {
  const instance = createServer(handler);
  await new Promise((resolve) => instance.listen(0, "127.0.0.1", resolve));
  return { url: `http://127.0.0.1:${instance.address().port}`, close: () => new Promise((resolve) => instance.close(resolve)) };
}

test("OpenCode client sends auth and parses bounded usage", async () => {
  let auth;
  const endpoint = await server((request, response) => { auth = request.headers.authorization; response.end(JSON.stringify({ usage: { monthly: { status: "active", percent: 94.9 } } })); });
  try {
    const result = await fetchOpenCodeUsage(`${endpoint.url}/usage`, { Authorization: "Bearer secret" }, { timeoutMs: 1000 });
    assert.equal(auth, "Bearer secret");
    assert.equal(result.windows[0].usedPercent, 94.9);
  } finally { await endpoint.close(); }
});

test("OpenCode client rejects redirects, oversized and malformed responses", async () => {
  for (const body of [null, "x".repeat(65537), "not json"]) {
    const endpoint = await server((_request, response) => {
      if (body === null) { response.writeHead(302, { location: "/elsewhere" }); response.end(); }
      else response.end(body);
    });
    try { await assert.rejects(fetchOpenCodeUsage(`${endpoint.url}/usage`, {}, { timeoutMs: 1000 }), /redirect|large|JSON/i); }
    finally { await endpoint.close(); }
  }
});

test("OpenCode client times out", async () => {
  const endpoint = await server(() => {});
  try { await assert.rejects(fetchOpenCodeUsage(`${endpoint.url}/usage`, {}, { timeoutMs: 20 }), /abort|timeout/i); }
  finally { await endpoint.close(); }
});

const jwt = (claims) => `h.${Buffer.from(JSON.stringify(claims)).toString("base64url")}.s`;

test("Codex client sends the account header and parses windows", async () => {
  let seen;
  const endpoint = await server((request, response) => { seen = request.headers; response.end(JSON.stringify({ rate_limit: { primary_window: { used_percent: 33, reset_at: 2000 } } })); });
  try {
    const token = jwt({ "https://api.openai.com/auth": { chatgpt_account_id: "acct-1" } });
    assert.equal(codexAccountId(token), "acct-1");
    const result = await fetchCodexUsage(token, { url: `${endpoint.url}/usage`, timeoutMs: 1000 });
    assert.equal(seen.authorization, `Bearer ${token}`);
    assert.equal(seen["chatgpt-account-id"], "acct-1");
    assert.equal(result.windows[0].usedPercent, 33);
  } finally { await endpoint.close(); }
});

test("Codex client rejects tokens without an account id, redirects, and HTTP errors", async () => {
  await assert.rejects(fetchCodexUsage("not-a-jwt"), /account id/);
  const token = jwt({ "https://api.openai.com/auth": { chatgpt_account_id: "a" } });
  for (const status of [302, 401]) {
    const endpoint = await server((_request, response) => { response.writeHead(status, status === 302 ? { location: "/x" } : {}); response.end(); });
    try { await assert.rejects(fetchCodexUsage(token, { url: `${endpoint.url}/usage`, timeoutMs: 1000 }), /redirect|HTTP 401/); }
    finally { await endpoint.close(); }
  }
});

test("Claude usage runs on a throwaway session without the traffic-disabling variable and always closes it", async () => {
  process.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  process.env.CLAUDE_CODE_OAUTH_TOKEN = "setup-token";
  try {
    let options; let closed = 0;
    const loadSdk = async () => ({ query: (args) => { options = args.options; return {
      usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET: async () => ({ rate_limits: { five_hour: { utilization: 20, resets_at: "2026-10-07T20:00:00.000Z" } } }),
      close: () => { closed += 1; },
    }; } });
    const result = await fetchClaudeUsage(loadSdk);
    assert.equal(result.windows[0].usedPercent, 20);
    assert.equal(options.persistSession, false);
    assert.equal("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" in options.env, false);
    assert.equal("CLAUDE_CODE_OAUTH_TOKEN" in options.env, false);
    assert.equal(process.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC, "1");
    assert.equal(process.env.CLAUDE_CODE_OAUTH_TOKEN, "setup-token");
    assert.equal(closed, 1);
  } finally { delete process.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC; delete process.env.CLAUDE_CODE_OAUTH_TOKEN; }
});

test("Claude usage times out and still closes the session", async () => {
  let closed = 0;
  const loadSdk = async () => ({ query: () => ({ usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET: () => new Promise(() => {}), close: () => { closed += 1; } }) });
  await assert.rejects(fetchClaudeUsage(loadSdk, { timeoutMs: 20 }), /timeout/);
  assert.equal(closed, 1);
});
