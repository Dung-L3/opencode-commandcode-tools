// Test cho setup-commandcode.mjs — chạy: node --test
// Chỉ test phần logic thuần (không I/O, không mạng).

import { test } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";

import {
  parseDebugPaths,
  resolveConfigDir,
  splitModels,
  buildProviderBlock,
  mergeProviders,
  isProviderPresent,
  assessConnection,
  readJsonFile,
} from "./setup-commandcode.mjs";

// ---------- parseDebugPaths ----------
test("parseDebugPaths: đọc đúng output thật của `opencode debug paths`", () => {
  const out = [
    "home       C:\\Users\\Admin",
    "data       C:\\Users\\Admin\\.local\\share\\opencode",
    "cache      C:\\Users\\Admin\\.cache\\opencode",
    "config     C:\\Users\\Admin\\.config\\opencode",
    "state      C:\\Users\\Admin\\.local\\state\\opencode",
    "db         C:\\Users\\Admin\\.local\\share\\opencode\\opencode.db",
  ].join("\n");

  const p = parseDebugPaths(out);
  assert.equal(p.home, "C:\\Users\\Admin");
  assert.equal(p.config, "C:\\Users\\Admin\\.config\\opencode");
  assert.equal(p.data, "C:\\Users\\Admin\\.local\\share\\opencode");
});

test("parseDebugPaths: đọc được output kiểu unix", () => {
  const out = ["home       /home/linh", "config     /home/linh/.config/opencode"].join("\n");
  const p = parseDebugPaths(out);
  assert.equal(p.config, "/home/linh/.config/opencode");
});

test("parseDebugPaths: bỏ qua rác và dòng trống", () => {
  const out = ["", "  ", "rác không có khoảng trắng kép", "config     /x/y"].join("\n");
  const p = parseDebugPaths(out);
  assert.equal(p.config, "/x/y");
});

// ---------- resolveConfigDir ----------
test("resolveConfigDir: ưu tiên đường dẫn OpenCode tự khai báo", () => {
  const r = resolveConfigDir({
    debugPaths: { config: "/custom/oc" },
    env: { XDG_CONFIG_HOME: "/xdg" },
    homedir: "/home/u",
  });
  assert.equal(r, "/custom/oc");
});

test("resolveConfigDir: không có debugPaths thì dùng XDG_CONFIG_HOME", () => {
  const r = resolveConfigDir({
    debugPaths: null,
    env: { XDG_CONFIG_HOME: "/xdg" },
    homedir: "/home/u",
  });
  assert.equal(r, path.join("/xdg", "opencode"));
});

test("resolveConfigDir: không có gì thì dùng homedir/.config/opencode", () => {
  const r = resolveConfigDir({ debugPaths: null, env: {}, homedir: "/home/u" });
  assert.equal(r, path.join("/home/u", ".config", "opencode"));
});

// ---------- splitModels ----------
const MODELS = [
  { id: "deepseek/x", name: "DeepSeek X", context_length: 1000000, supported_endpoints: ["/chat/completions", "/responses"] },
  { id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5", context_length: 1000000, supported_endpoints: ["/messages"] },
  { id: "gpt-6-sol", name: "GPT-6 Sol", context_length: 1050000, supported_endpoints: ["/chat/completions", "/responses"] },
];

test("splitModels: tách đúng nhóm OpenAI và nhóm Claude", () => {
  const { openaiCapable, anthropicOnly } = splitModels(MODELS);
  assert.equal(openaiCapable.length, 2);
  assert.equal(anthropicOnly.length, 1);
  assert.equal(anthropicOnly[0].id, "claude-sonnet-5-5");
});

test("splitModels: chịu được mảng rỗng và thiếu trường", () => {
  assert.deepEqual(splitModels([]), { openaiCapable: [], anthropicOnly: [] });
  const r = splitModels([{ id: "a", name: "A" }]);
  assert.equal(r.anthropicOnly.length, 1, "thiếu supported_endpoints => coi như anthropic-only");
});

// ---------- buildProviderBlock ----------
test("buildProviderBlock: tạo đúng cấu trúc V2 (capabilities đủ 3 trường)", () => {
  const b = buildProviderBlock({
    models: [MODELS[0]],
    apiKey: "user_test",
    packageName: "@opencode/ai/providers/openai-compatible",
    displayName: "Command Code",
  });

  assert.equal(b.name, "Command Code");
  assert.equal(b.package, "@opencode/ai/providers/openai-compatible");
  assert.equal(b.settings.baseURL, "https://api.commandcode.ai/provider/v1");
  assert.equal(b.settings.apiKey, "user_test");

  const m = b.models["deepseek/x"];
  assert.equal(m.name, "DeepSeek X");
  assert.deepEqual(m.capabilities, { tools: true, input: ["text", "image"], output: ["text"] });
  assert.deepEqual(m.limit, { context: 1000000, output: 32000 });
});

test("buildProviderBlock: KHÔNG có trường env (V2 không hỗ trợ cho custom provider)", () => {
  const b = buildProviderBlock({ models: [MODELS[0]], apiKey: "k", packageName: "p", displayName: "n" });
  assert.equal(Object.hasOwn(b, "env"), false);
});

test("buildProviderBlock: model thiếu context_length thì dùng mặc định", () => {
  const b = buildProviderBlock({ models: [{ id: "z", name: "Z" }], apiKey: "k", packageName: "p", displayName: "n" });
  assert.equal(b.models.z.limit.context, 200000);
});

// ---------- mergeProviders ----------
test("mergeProviders: GIỮ NGUYÊN mọi thứ khác (plugins, mcp, agents)", () => {
  const existing = {
    $schema: "https://opencode.ai/config.json",
    plugins: ["superpowers@git+https://github.com/obra/superpowers.git"],
    mcp: { "vpg-graph": { type: "local", command: ["x"] } },
    agents: { reviewer: { mode: "subagent" } },
    providers: { openai: { settings: { baseURL: "https://api.openai.com/v1" } } },
  };

  const merged = mergeProviders(existing, { cmd: { name: "Command Code" } });

  assert.deepEqual(merged.plugins, existing.plugins);
  assert.deepEqual(merged.mcp, existing.mcp);
  assert.deepEqual(merged.agents, existing.agents);
  assert.deepEqual(merged.providers.openai, existing.providers.openai, "provider khác phải còn nguyên");
  assert.equal(merged.providers.cmd.name, "Command Code");
});

test("mergeProviders: không sửa object gốc", () => {
  const existing = { providers: { a: { name: "A" } } };
  const snapshot = JSON.stringify(existing);
  mergeProviders(existing, { b: { name: "B" } });
  assert.equal(JSON.stringify(existing), snapshot);
});

test("mergeProviders: config rỗng vẫn tạo được", () => {
  const merged = mergeProviders({}, { cmd: { name: "C" } });
  assert.equal(merged.providers.cmd.name, "C");
});

// ---------- isProviderPresent ----------
test("isProviderPresent: nhận diện provider đã tồn tại", () => {
  const cfg = { providers: { cmd: { name: "Command Code" } } };
  assert.equal(isProviderPresent(cfg, "cmd"), true);
  assert.equal(isProviderPresent(cfg, "cmd-claude"), false);
  assert.equal(isProviderPresent({}, "cmd"), false);
});

// ---------- assessConnection ----------
test("assessConnection: chưa có provider => not-configured", () => {
  assert.equal(assessConnection({}, null), "not-configured");
  assert.equal(assessConnection({ providers: {} }, null), "not-configured");
});

test("assessConnection: có provider nhưng thiếu key => not-configured", () => {
  const cfg = { providers: { cmd: { name: "X", settings: {} } } };
  assert.equal(assessConnection(cfg, null), "not-configured");
});

test("assessConnection: có provider + key + key hợp lệ => ready", () => {
  const cfg = { providers: { cmd: { settings: { apiKey: "user_x" } } } };
  assert.equal(assessConnection(cfg, true), "ready");
});

test("assessConnection: có provider + key nhưng key hỏng => key-invalid", () => {
  const cfg = { providers: { cmd: { settings: { apiKey: "user_x" } } } };
  assert.equal(assessConnection(cfg, false), "key-invalid");
});

test("assessConnection: chưa kiểm tra được (offline) => configured-unverified", () => {
  const cfg = { providers: { cmd: { settings: { apiKey: "user_x" } } } };
  assert.equal(assessConnection(cfg, null), "configured-unverified");
});

// ---------- readJsonFile ----------
test("readJsonFile: đọc được JSON có BOM (PowerShell Set-Content hay thêm)", () => {
  const f = path.join(os.tmpdir(), `bom-${process.pid}.json`);
  fs.writeFileSync(f, "\uFEFF" + JSON.stringify({ a: 1, tiếng: "Việt" }), "utf8");
  try {
    const j = readJsonFile(f);
    assert.equal(j.a, 1);
    assert.equal(j["tiếng"], "Việt");
  } finally {
    fs.rmSync(f, { force: true });
  }
});

test("readJsonFile: JSON hỏng thì ném lỗi (để caller dừng an toàn)", () => {
  const f = path.join(os.tmpdir(), `bad-${process.pid}.json`);
  fs.writeFileSync(f, "{ khong phai json", "utf8");
  try {
    assert.throws(() => readJsonFile(f));
  } finally {
    fs.rmSync(f, { force: true });
  }
});
