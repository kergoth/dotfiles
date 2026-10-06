import { appendFile, mkdir, open, readFile, rename, rmdir, stat, unlink, writeFile } from "node:fs/promises";
import { join } from "node:path";

const EMPTY = () => ({ version: 1, targets: {}, usage: {} });
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export function resolveStatePaths(env = process.env, agentDir) {
  const dir = env.PI_MODEL_ALIAS_STATE_DIR || join(agentDir, "state", "model-alias");
  return { dir, state: join(dir, "state.json"), lock: join(dir, "state.lock"), reaper: join(dir, "state.lock.reaper"), log: join(dir, "events.jsonl"), rotatedLog: join(dir, "events.previous.jsonl") };
}

export async function readState(path) {
  try {
    const value = JSON.parse(await readFile(path, "utf8"));
    if (!value || value.version !== 1 || typeof value.targets !== "object" || typeof value.usage !== "object") return EMPTY();
    return value;
  } catch { return EMPTY(); }
}

function processAlive(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; } catch (error) { return error?.code === "EPERM"; }
}

async function reapStaleLock(paths, staleMs) {
  try { await mkdir(paths.reaper); } catch (error) { if (error?.code === "EEXIST") return false; throw error; }
  try {
    let owner;
    try { owner = JSON.parse(await readFile(paths.lock, "utf8")); } catch { return false; }
    if (processAlive(owner.pid)) return false;
    if (Date.now() - (await stat(paths.lock)).mtimeMs <= staleMs) return false;
    await unlink(paths.lock).catch((error) => { if (error?.code !== "ENOENT") throw error; });
    return true;
  } finally { await rmdir(paths.reaper).catch(() => {}); }
}

async function acquire(paths, options = {}) {
  await mkdir(paths.dir, { recursive: true });
  const deadline = Date.now() + (options.timeoutMs ?? 5000);
  const token = crypto.randomUUID();
  for (;;) {
    try {
      const handle = await open(paths.lock, "wx", 0o600);
      await handle.writeFile(JSON.stringify({ pid: process.pid, token, createdAt: Date.now() }));
      await handle.close();
      return token;
    } catch (error) {
      if (error?.code !== "EEXIST") throw error;
      if (await reapStaleLock(paths, options.staleMs ?? 10000)) continue;
      if (Date.now() >= deadline) throw new Error("Timed out acquiring model-alias state lock");
      await sleep(10 + Math.floor(Math.random() * 20));
    }
  }
}

async function release(paths, token) {
  let owner;
  try { owner = JSON.parse(await readFile(paths.lock, "utf8")); } catch { return; }
  if (owner.token === token) await unlink(paths.lock).catch(() => {});
}

async function locked(paths, fn, options) {
  const token = await acquire(paths, options);
  try { return await fn(); }
  finally { await release(paths, token); }
}

export async function updateState(paths, mutate, options = {}) {
  return locked(paths, async () => {
    const state = await readState(paths.state);
    await mutate(state);
    const tmp = `${paths.state}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await writeFile(tmp, `${JSON.stringify(state)}\n`, { mode: 0o600 });
    await rename(tmp, paths.state);
    return state;
  }, options);
}

function clean(value) {
  if (typeof value === "string") return value.replace(/[\r\n]+/g, " ");
  if (Array.isArray(value)) return value.map(clean);
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, clean(item)]));
  return value;
}

export async function appendEvent(paths, event, options = {}) {
  return locked(paths, async () => {
    const line = `${JSON.stringify(clean(event))}\n`;
    let size = 0;
    try { size = (await stat(paths.log)).size; } catch {}
    if (size + Buffer.byteLength(line) > (options.maxBytes ?? 1024 * 1024) && size > 0) {
      await unlink(paths.rotatedLog).catch(() => {});
      await rename(paths.log, paths.rotatedLog);
    }
    await appendFile(paths.log, line, { mode: 0o600 });
  }, options);
}
