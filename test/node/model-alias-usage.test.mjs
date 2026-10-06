import assert from "node:assert/strict";
import { createServer } from "node:http";
import test from "node:test";

import { fetchOpenCodeUsage } from "../../home/dot_pi/private_agent/extensions/model-alias/model-alias-usage.js";

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
