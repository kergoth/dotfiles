import assert from "node:assert/strict";
import { mkdtemp, readFile, readdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import test from "node:test";

import { appendEvent, readState, resolveStatePaths, updateState } from "../../home/dot_pi/private_agent/extensions/model-alias/model-alias-store.js";

const temp = () => mkdtemp(join(tmpdir(), "model-alias-store-"));

test("resolveStatePaths honors override", () => {
  assert.equal(resolveStatePaths({ PI_MODEL_ALIAS_STATE_DIR: "/tmp/custom" }, "/agent").state, "/tmp/custom/state.json");
  assert.equal(resolveStatePaths({}, "/agent").state, "/agent/state/model-alias/state.json");
});

test("readState recovers from missing and malformed state", async () => {
  const dir = await temp(); const paths = resolveStatePaths({ PI_MODEL_ALIAS_STATE_DIR: dir }, "/agent");
  assert.deepEqual(await readState(paths.state), { version: 1, targets: {}, usage: {} });
  await writeFile(paths.state, "bad");
  assert.deepEqual(await readState(paths.state), { version: 1, targets: {}, usage: {} });
});

test("updateState merges sequential changes and leaves no lock", async () => {
  const dir = await temp(); const paths = resolveStatePaths({ PI_MODEL_ALIAS_STATE_DIR: dir }, "/agent");
  await updateState(paths, (state) => { state.targets.a = { nextRetryAt: 1 }; });
  await updateState(paths, (state) => { state.usage.b = { capturedAt: 2, windows: [] }; });
  assert.deepEqual(await readState(paths.state), { version: 1, targets: { a: { nextRetryAt: 1 } }, usage: { b: { capturedAt: 2, windows: [] } } });
  assert.equal((await readdir(dir)).some((name) => name.includes("lock") || name.includes("tmp")), false);
});

test("concurrent writers preserve unrelated updates", async () => {
  const dir = await temp();
  const modulePath = new URL("../../home/dot_pi/private_agent/extensions/model-alias/model-alias-store.js", import.meta.url).pathname;
  const child = (key) => new Promise((resolve, reject) => {
    const source = `import {resolveStatePaths,updateState} from ${JSON.stringify(modulePath)}; const p=resolveStatePaths({PI_MODEL_ALIAS_STATE_DIR:${JSON.stringify(dir)}},\"/agent\"); await updateState(p, async s=>{await new Promise(r=>setTimeout(r,50));s.targets[${JSON.stringify(key)}]={nextRetryAt:1}});`;
    const proc = spawn(process.execPath, ["--input-type=module", "-e", source]);
    proc.on("exit", (code) => code === 0 ? resolve() : reject(new Error(`child exited ${code}`)));
  });
  await Promise.all([child("a"), child("b")]);
  assert.deepEqual(Object.keys((await readState(join(dir, "state.json"))).targets).sort(), ["a", "b"]);
});

test("stale lock takeover preserves exclusion between contenders", async () => {
  const dir = await temp(); const paths = resolveStatePaths({ PI_MODEL_ALIAS_STATE_DIR: dir }, "/agent");
  await writeFile(paths.lock, JSON.stringify({ pid: 999999, token: "stale", createdAt: 0 }));
  const modulePath = new URL("../../home/dot_pi/private_agent/extensions/model-alias/model-alias-store.js", import.meta.url).pathname;
  const child = (key) => new Promise((resolve, reject) => {
    const source = `import {resolveStatePaths,updateState} from ${JSON.stringify(modulePath)};const p=resolveStatePaths({PI_MODEL_ALIAS_STATE_DIR:${JSON.stringify(dir)}},\"/agent\");await updateState(p,async s=>{const n=Object.keys(s.targets).length;await new Promise(r=>setTimeout(r,40));s.targets[${JSON.stringify(key)}]={nextRetryAt:n}},{staleMs:0,timeoutMs:2000});`;
    const proc = spawn(process.execPath, ["--input-type=module", "-e", source]);
    proc.on("exit", (code) => code === 0 ? resolve() : reject(new Error(`child exited ${code}`)));
  });
  await Promise.all([child("a"), child("b")]);
  assert.deepEqual(Object.values((await readState(paths.state)).targets).map((entry) => entry.nextRetryAt).sort(), [0, 1]);
});

test("appendEvent writes one JSON object per line and rotates", async () => {
  const dir = await temp(); const paths = resolveStatePaths({ PI_MODEL_ALIAS_STATE_DIR: dir }, "/agent");
  await appendEvent(paths, { type: "failure", reason: "one\ntwo" }, { maxBytes: 80 });
  await appendEvent(paths, { type: "failure", reason: "x".repeat(100) }, { maxBytes: 80 });
  const lines = (await readFile(paths.log, "utf8")).trim().split("\n");
  assert.doesNotThrow(() => JSON.parse(lines.at(-1)));
  assert.equal((await readdir(dir)).includes("events.previous.jsonl"), true);
});
