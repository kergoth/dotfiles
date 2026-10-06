import { parseOpenCodeUsage } from "./model-alias-core.js";

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
