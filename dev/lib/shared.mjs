// lib/shared.mjs — lớp nền dùng chung cho mọi lệnh con.
//
// KHÔNG có shebang, không import nội bộ trong bản đã gộp: bundler tự chèn
// phần import của Node ở đầu. Ở đây vẫn để import để chạy/test trực tiếp được;
// bundler sẽ bỏ chúng khi gộp.
//
// Mỗi module tự đăng ký chuỗi của mình bằng registerMessages(), nên các module
// không giẫm lên nhau khi làm song song.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execSync } from "node:child_process";
import { pathToFileURL } from "node:url";

// ============================================================
// Hằng số
// ============================================================

export const API_BASE = "https://api.commandcode.ai/provider/v1";
export const PKG_OPENAI = "@opencode/ai/providers/openai-compatible";
export const PKG_ANTHROPIC = "@opencode/ai/providers/anthropic";
export const CMD_OPENCODE = "npm i -g @opencode/cli";
export const CMD_CMDC = "npm i -g command-code";
export const DEFAULT_CONTEXT = 200000;
export const DEFAULT_OUTPUT = 32000;
export const KEY_PAGE = "https://commandcode.ai/settings/keys";
export const E2E_PREFERRED = "deepseek/deepseek-v4-flash";
export const VERSION = "1.1.0";

// ============================================================
// Đa ngữ
// ============================================================

const MESSAGES = { en: {}, vi: {} };
let LANG = "en";

/** Mỗi module gọi hàm này một lần ở cấp cao nhất để nạp chuỗi của mình. */
export function registerMessages(en, vi) {
  Object.assign(MESSAGES.en, en);
  Object.assign(MESSAGES.vi, vi);
}

export function setLang(l) {
  LANG = l === "vi" ? "vi" : "en";
  return LANG;
}

export function getLang() {
  return LANG;
}

/** Dịch một khoá, thay {placeholder}. Thiếu khoá thì trả về chính khoá đó. */
export function t(key, vars) {
  let s = MESSAGES[LANG]?.[key] ?? MESSAGES.en[key] ?? key;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(String(v));
  }
  return s;
}

export function detectLang(env = process.env, locale) {
  const e = String(env.CMDCODE_LANG || "").toLowerCase();
  if (e.startsWith("vi")) return "vi";
  if (e.startsWith("en")) return "en";
  const loc = String(locale || "").toLowerCase();
  return loc.startsWith("vi") ? "vi" : "en";
}

// ============================================================
// Màu và in ấn
// ============================================================

export const C = {
  reset: "\x1b[0m", bold: "\x1b[1m", dim: "\x1b[2m",
  red: "\x1b[31m", green: "\x1b[32m", yellow: "\x1b[33m", cyan: "\x1b[36m",
};

export const say = (s = "") => console.log(s);
export const ok = (s) => say(`      ${C.green}✓${C.reset} ${s}`);
export const bad = (s) => say(`      ${C.red}✗${C.reset} ${s}`);
export const warn = (s) => say(`      ${C.yellow}!${C.reset} ${s}`);
export const info = (s) => say(`      ${C.dim}${s}${C.reset}`);
export const step = (n, s) => say(`${C.cyan}[${n}] ${s}${C.reset}`);

export function banner(title) {
  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   ${title}${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
}

// ============================================================
// Chạy lệnh ngoài
// ============================================================

export const stripAnsi = (s) => String(s).replace(/\x1b\[[0-9;]*m/g, "");

export function tryRun(cmd, opts = {}) {
  try {
    const out = execSync(cmd, { stdio: ["ignore", "pipe", "pipe"], encoding: "utf8", ...opts });
    return { ok: true, out: stripAnsi(String(out)).trim() };
  } catch (e) {
    const out = stripAnsi(String(e.stdout || "") + String(e.stderr || "")).trim();
    return { ok: false, out };
  }
}

export function findTool(names) {
  for (const n of names) {
    const r = tryRun(`${n} --version`);
    if (r.ok && r.out) return { name: n, version: r.out.split(/\r?\n/)[0].trim() };
  }
  return null;
}

// ============================================================
// Nhập liệu
// ============================================================
// Không dùng nhiều readline interface trên stdin đã pipe: khi gặp EOF,
// callback của readline không bao giờ chạy và tiến trình thoát "sạch"
// (exit 0) mà không làm gì — kiểu hỏng âm thầm.

let pipedLines = null;

function pipedAsk(question) {
  if (pipedLines === null) {
    let data = "";
    try { data = fs.readFileSync(0, "utf8"); } catch { data = ""; }
    pipedLines = data.split(/\r?\n/);
  }
  process.stdout.write(question);
  const a = (pipedLines.shift() ?? "").trim();
  process.stdout.write("<input>\n");
  return Promise.resolve(a);
}

let rlTTY = null;
let muteEcho = false;

function ttyInterface() {
  if (!rlTTY) {
    rlTTY = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    const orig = rlTTY._writeToOutput.bind(rlTTY);
    rlTTY._writeToOutput = (s) => { if (!muteEcho) orig(s); };
  }
  return rlTTY;
}

function ttyAsk(question, hidden) {
  process.stdout.write(question);
  muteEcho = Boolean(hidden);
  return new Promise((res) => {
    ttyInterface().question("", (a) => {
      muteEcho = false;
      process.stdout.write("\n");
      res(a.trim());
    });
  });
}

/** Đóng readline để tiến trình thoát được. Gọi trước khi kết thúc. */
export function closeInput() {
  if (rlTTY) { try { rlTTY.close(); } catch { /* đã đóng */ } rlTTY = null; }
}

export const isTTY = () => Boolean(process.stdin.isTTY && process.stdout.isTTY);
export const ask = (q) => (isTTY() ? ttyAsk(q, false) : pipedAsk(q));
export const askHidden = (q) => (isTTY() ? ttyAsk(q, true) : pipedAsk(q));
export const askYes = async (q, def = false) => {
  const a = await ask(q);
  if (!a) return def;
  return /^(y|yes|có|co|v)$/i.test(a);
};

// ============================================================
// Đọc/ghi file
// ============================================================

export function writeAtomic(file, text) {
  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, text, "utf8");
  fs.renameSync(tmp, file);
}

/** Đọc JSON, chịu được BOM (PowerShell/Notepad trên Windows hay thêm vào). */
export function readJsonFile(file) {
  let raw = fs.readFileSync(file, "utf8");
  if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);
  return JSON.parse(raw);
}

/** Trả về {} nếu chưa có file, null nếu file hỏng. */
export function readConfigIfAny(file) {
  if (!fs.existsSync(file)) return {};
  try { return readJsonFile(file); } catch { return null; }
}

export const stamp = () => new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);

// ============================================================
// Logic thuần (được test)
// ============================================================

/** Đọc output của `opencode debug paths` thành object. */
export function parseDebugPaths(stdout) {
  const out = {};
  for (const raw of String(stdout).split(/\r?\n/)) {
    const line = stripAnsi(raw).trim();
    if (!line) continue;
    const m = line.match(/^(\S+)\s+(.+)$/);
    if (!m) continue;
    out[m[1]] = m[2].trim();
  }
  return out;
}

/** Tìm thư mục config OpenCode: ưu tiên điều OpenCode tự khai báo. */
export function resolveConfigDir({ debugPaths, env = {}, homedir = os.homedir() } = {}) {
  if (debugPaths && debugPaths.config) return debugPaths.config;
  if (env.XDG_CONFIG_HOME) return path.join(env.XDG_CONFIG_HOME, "opencode");
  return path.join(homedir, ".config", "opencode");
}

/** Chia model theo route mà nó phục vụ. */
export function splitModels(models) {
  const openaiCapable = [];
  const anthropicOnly = [];
  for (const m of models || []) {
    const eps = m.supported_endpoints || [];
    const isOpenai = eps.some((e) => e.includes("chat/completions") || e.includes("responses"));
    (isOpenai ? openaiCapable : anthropicOnly).push(m);
  }
  return { openaiCapable, anthropicOnly };
}

/** Dựng block provider theo schema V2. */
export function buildProviderBlock({ models, apiKey, packageName, displayName }) {
  const map = {};
  for (const m of models || []) {
    map[m.id] = {
      name: m.name || m.id,
      capabilities: { tools: true, input: ["text", "image"], output: ["text"] },
      limit: {
        context: Number(m.context_length) || DEFAULT_CONTEXT,
        output: DEFAULT_OUTPUT,
      },
    };
  }
  return {
    name: displayName,
    package: packageName,
    settings: { baseURL: API_BASE, apiKey },
    models: map,
  };
}

/** Ghép provider mới vào config, giữ nguyên mọi thứ khác. Không sửa object gốc. */
export function mergeProviders(existing, newProviders) {
  const clone = structuredClone(existing || {});
  clone.providers = clone.providers || {};
  for (const [id, block] of Object.entries(newProviders || {})) {
    clone.providers[id] = block;
  }
  return clone;
}

export function isProviderPresent(config, id) {
  return Boolean(config && config.providers && Object.hasOwn(config.providers, id));
}

/**
 * ready | not-configured | key-invalid | configured-unverified
 */
export function assessConnection(config, keyValid) {
  const key = config?.providers?.cmd?.settings?.apiKey;
  if (!isProviderPresent(config, "cmd") || !key) return "not-configured";
  if (keyValid === true) return "ready";
  if (keyValid === false) return "key-invalid";
  return "configured-unverified";
}

// ============================================================
// Phần dùng chung cho các lệnh con
// ============================================================

export async function fetchModels(apiKey) {
  const res = await fetch(`${API_BASE}/models`, { headers: { Authorization: `Bearer ${apiKey}` } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const j = await res.json();
  return Array.isArray(j) ? j : j.data || [];
}

export const fingerprint = (k) =>
  !k || k.length < 20 ? t("invalidFp") : `${k.slice(0, 10)}…${k.slice(-6)}  (${k.length})`;

/** Tìm thư mục config: hỏi chính OpenCode, không hardcode. */
export function discoverConfigDir(opencode) {
  if (opencode) {
    const r = tryRun("opencode debug paths");
    if (r.ok) {
      const p = parseDebugPaths(r.out);
      if (p.config) return { dir: p.config, src: t("srcDeclared") };
    }
  }
  return { dir: resolveConfigDir({ env: process.env, homedir: os.homedir() }), src: t("srcConvention") };
}

/**
 * Dò toàn bộ môi trường. Mọi lệnh con đều dùng hàm này.
 * Trả về cả đường dẫn lẫn trạng thái, không tự in gì.
 */
export function probeEnvironment() {
  const opencode = findTool(["opencode"]);
  const cmdc = findTool(["cmdc", "command-code", "cmd"]);
  const cfg = discoverConfigDir(opencode);
  const configFile = path.join(cfg.dir, "opencode.json");
  return {
    opencode,
    cmdc,
    configDir: cfg.dir,
    configSrc: cfg.src,
    configFile,
    cliAuthFile: path.join(os.homedir(), ".commandcode", "auth.json"),
    existing: readConfigIfAny(configFile),
  };
}

/** Danh sách backup của một file, mới nhất trước. */
export function listBackups(configFile) {
  const dir = path.dirname(configFile);
  const base = path.basename(configFile);
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter((f) => f.startsWith(`${base}.bak-`))
    .map((f) => {
      const full = path.join(dir, f);
      const st = fs.statSync(full);
      return { name: f, path: full, size: st.size, mtime: st.mtime };
    })
    .sort((a, b) => b.mtime - a.mtime);
}

/** Khoá đã đăng ký, để test đối chiếu hai bảng ngôn ngữ. */
export function messageKeys() {
  return { en: Object.keys(MESSAGES.en).sort(), vi: Object.keys(MESSAGES.vi).sort() };
}

// Chuỗi dùng chung cho lớp nền. Phải đăng ký ở đây vì `fingerprint()` và
// `discoverConfigDir()` gọi t() tới chúng, mà không module lệnh nào sở hữu.
registerMessages(
  {
    invalidFp: "<invalid>",
    srcDeclared: "reported by opencode",
    srcConvention: "by convention",
  },
  {
    invalidFp: "<không hợp lệ>",
    srcDeclared: "opencode tự khai báo",
    srcConvention: "theo quy ước",
  }
);
