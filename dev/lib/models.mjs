// lib/models.mjs — lệnh con `models`: xem và chọn model mặc định.
//
// Thuần đọc/ghi file config OpenCode, không gọi mạng.
// Mọi tên ở cấp cao nhất đều bắt đầu bằng `models` vì bundler gộp phẳng
// tất cả module vào một phạm vi.

import {
  C, bad, banner, info, ok, probeEnvironment, readConfigIfAny, readJsonFile,
  registerMessages, say, stamp, t, warn, writeAtomic,
} from "./shared.mjs";

import fs from "node:fs";
import path from "node:path";

registerMessages(
  {
    "models.summary": "Inspect or choose the default model",
    "models.title": "DEFAULT MODEL",
    "models.configLine": "Config: {p}",
    "models.currentLabel": "Default model: {m}",
    "models.notSet": "Default model: not set — OpenCode asks per session.",
    "models.notSetHint": "Pick one with:  cmd models set <n|id>",
    "models.noConfig": "No config yet at {f}.",
    "models.noConfigHint": "Run the installer first (run `cmd` with no arguments).",
    "models.configCorrupt": "{f} is not valid JSON.",
    "models.configCorruptHint": "Stopped so the file is not damaged. Fix it, then run again.",
    "models.noModels": "providers.{p} has no models in the config.",
    "models.noClaude": "providers.cmd-claude has no models in the config.",
    "models.noModelsHint": "Re-run the installer to fetch the model list.",
    "models.colIndex": "#",
    "models.colId": "model id",
    "models.colName": "name",
    "models.colCtx": "context",
    "models.alsoClaude": "(also in cmd-claude)",
    "models.claudeOnly": "(cmd-claude)",
    "models.count": "{n} models from providers.{p}.",
    "models.listSource": "This list comes from the config file. Re-run the installer to refresh it.",
    "models.alreadySet": "Default model is already {m}",
    "models.setDone": "Default model set to {m}",
    "models.setHint": "OpenCode now starts with this model. Override per session with /models.",
    "models.setUsage": "Usage:  cmd models set <number|model-id> [--claude]",
    "models.badIndex": "Index {n} is out of range (1–{max}).",
    "models.unknownModel": "Unknown model: {m}",
    "models.closeMatches": "Close matches: {list}",
    "models.noCloseMatches": "No close matches.",
    "models.backup": "Backup: {f}",
    "models.writeFailed": "Could not write the config: {e}",
    "models.confirmMismatch": "The config was written but reads back as {m}.",
    "models.unsetDone": "Default model removed — OpenCode asks per session again.",
    "models.unsetAlready": "No default model is set; nothing to do.",
    "models.unknownOption": "Unknown option: {o}",
    "models.unknownAction": "Unknown action: {a}",
    "models.usage": "Usage:  cmd models [--claude]  |  cmd models set <n|id> [--claude]  |  cmd models unset",
  },
  {
    "models.summary": "Xem hoặc chọn model mặc định",
    "models.title": "MODEL MẶC ĐỊNH",
    "models.configLine": "Config: {p}",
    "models.currentLabel": "Model mặc định: {m}",
    "models.notSet": "Model mặc định: chưa đặt — OpenCode sẽ hỏi mỗi phiên.",
    "models.notSetHint": "Chọn bằng:  cmd models set <số|id>",
    "models.noConfig": "Chưa có config tại {f}.",
    "models.noConfigHint": "Hãy chạy installer trước (chạy `cmd` không tham số).",
    "models.configCorrupt": "{f} không phải JSON hợp lệ.",
    "models.configCorruptHint": "Đã dừng để không làm hỏng file. Sửa file đó rồi chạy lại.",
    "models.noModels": "providers.{p} chưa có model nào trong config.",
    "models.noClaude": "providers.cmd-claude chưa có model nào trong config.",
    "models.noModelsHint": "Chạy lại installer để lấy danh sách model.",
    "models.colIndex": "#",
    "models.colId": "model id",
    "models.colName": "tên",
    "models.colCtx": "ngữ cảnh",
    "models.alsoClaude": "(cũng có trong cmd-claude)",
    "models.claudeOnly": "(cmd-claude)",
    "models.count": "{n} model từ providers.{p}.",
    "models.listSource": "Danh sách này lấy từ file config. Chạy lại installer để cập nhật.",
    "models.alreadySet": "Model mặc định đã là {m} rồi",
    "models.setDone": "Đã đặt model mặc định là {m}",
    "models.setHint": "OpenCode sẽ khởi động bằng model này. Vẫn đổi được từng phiên bằng /models.",
    "models.setUsage": "Cách dùng:  cmd models set <số|model-id> [--claude]",
    "models.badIndex": "Số {n} nằm ngoài khoảng (1–{max}).",
    "models.unknownModel": "Không có model: {m}",
    "models.closeMatches": "Gần giống: {list}",
    "models.noCloseMatches": "Không có model nào gần giống.",
    "models.backup": "Backup: {f}",
    "models.writeFailed": "Không ghi được config: {e}",
    "models.confirmMismatch": "Đã ghi config nhưng đọc lại thấy {m}.",
    "models.unsetDone": "Đã bỏ model mặc định — OpenCode lại hỏi mỗi phiên.",
    "models.unsetAlready": "Chưa đặt model mặc định; không có gì phải làm.",
    "models.unknownOption": "Tuỳ chọn lạ: {o}",
    "models.unknownAction": "Không có hành động: {a}",
    "models.usage": "Cách dùng:  cmd models [--claude]  |  cmd models set <số|id> [--claude]  |  cmd models unset",
  }
);

// ============================================================
// Đọc danh sách model
// ============================================================

/**
 * Gom model đang dùng thành từng dòng.
 * includeClaude = true thì thêm cả providers.cmd-claude (bỏ id đã hiện ở cmd).
 */
function modelsCollect(cfg, includeClaude) {
  const cmd = cfg?.providers?.cmd?.models || {};
  const claude = cfg?.providers?.["cmd-claude"]?.models || {};
  const rows = [];

  for (const [id, m] of Object.entries(cmd)) {
    rows.push({
      id,
      name: m?.name || id,
      context: Number(m?.limit?.context) || 0,
      provider: "cmd",
      alsoClaude: Object.hasOwn(claude, id),
    });
  }

  if (includeClaude) {
    for (const [id, m] of Object.entries(claude)) {
      if (Object.hasOwn(cmd, id)) continue;
      rows.push({
        id,
        name: m?.name || id,
        context: Number(m?.limit?.context) || 0,
        provider: "cmd-claude",
        alsoClaude: false,
      });
    }
  }

  return { rows, cmd, claude };
}

/** Đọc config mới từ đĩa. Trả {cfg} hoặc {fail: "nocfg"|"corrupt"}. */
function modelsLoad(env) {
  if (env.existing === null) return { fail: "corrupt" };
  if (!fs.existsSync(env.configFile)) return { fail: "nocfg" };
  const cfg = readConfigIfAny(env.configFile);
  if (cfg === null) return { fail: "corrupt" };
  return { cfg };
}

/** In lỗi nạp config rồi trả mã thoát. */
function modelsFail(kind, env) {
  if (kind === "corrupt") {
    bad(t("models.configCorrupt", { f: env.configFile }));
    warn(t("models.configCorruptHint"));
  } else {
    bad(t("models.noConfig", { f: env.configFile }));
    info(t("models.noConfigHint"));
  }
  return 1;
}

// ============================================================
// Phân giải tham số
// ============================================================

/**
 * Chuẩn hoá tham số thành một dòng.
 * Nhận số thứ tự (1-based) hoặc id, có/không tiền tố `cmd/` / `cmd-claude/`.
 */
function modelsResolve(arg, rows) {
  const raw = String(arg ?? "").trim();
  if (!raw) return { err: "empty" };

  if (/^\d+$/.test(raw)) {
    const n = Number(raw);
    if (n >= 1 && n <= rows.length) return { row: rows[n - 1] };
    return { err: "index", n, max: rows.length };
  }

  let id = raw;
  let forced = null;
  for (const p of ["cmd-claude", "cmd"]) {
    if (id.startsWith(`${p}/`)) { forced = p; id = id.slice(p.length + 1); break; }
  }

  let hits = rows.filter((r) => r.id === id);
  if (!hits.length) {
    const low = id.toLowerCase();
    hits = rows.filter((r) => r.id.toLowerCase() === low);
  }
  const hit = forced ? hits.find((r) => r.provider === forced) : hits[0];
  if (hit) return { row: hit };
  return { err: "unknown", id: raw };
}

/** Gợi ý vài id gần giống khi người dùng gõ sai. */
function modelsCloseMatches(id, rows) {
  const q = String(id).toLowerCase();
  const toks = q.split(/[/\-._:]/).filter(Boolean);
  const scored = [];

  for (const r of rows) {
    const rid = r.id.toLowerCase();
    const rname = String(r.name).toLowerCase();
    const rt = rid.split(/[/\-._:]/).filter(Boolean);
    let s = 0;
    if (rid === q) s = 100;
    else if (rid.startsWith(q) || q.startsWith(rid)) s = 70;
    else if (rid.includes(q) || q.includes(rid)) s = 55;
    else if (rname.includes(q)) s = 45;
    else {
      const shared = toks.filter((x) => rt.includes(x)).length;
      if (shared) s = 20 + shared * 8;
    }
    if (s > 0) scored.push({ id: r.id, s });
  }

  scored.sort((a, b) => b.s - a.s || a.id.localeCompare(b.id));
  return scored.slice(0, 5).map((x) => x.id);
}

// ============================================================
// In bảng
// ============================================================

function modelsPrintTable(rows) {
  const idxW = Math.max(3, String(rows.length).length);
  const idW = Math.max(t("models.colId").length, ...rows.map((r) => r.id.length));
  const nameW = Math.max(t("models.colName").length, ...rows.map((r) => String(r.name).length));

  say(
    `      ${C.dim}${t("models.colIndex").padStart(idxW)}  ${t("models.colId").padEnd(idW)}  ` +
    `${t("models.colName").padEnd(nameW)}  ${t("models.colCtx")}${C.reset}`
  );

  rows.forEach((r, i) => {
    const tag = r.provider === "cmd-claude"
      ? `  ${C.dim}${t("models.claudeOnly")}${C.reset}`
      : r.alsoClaude
        ? `  ${C.dim}${t("models.alsoClaude")}${C.reset}`
        : "";
    say(
      `      ${C.cyan}${String(i + 1).padStart(idxW)}${C.reset}  ` +
      `${r.id.padEnd(idW)}  ${String(r.name).padEnd(nameW)}  ` +
      `${C.dim}${r.context}${C.reset}${tag}`
    );
  });
}

// ============================================================
// Hành động
// ============================================================

function modelsList(env, includeClaude) {
  const loaded = modelsLoad(env);
  if (loaded.fail) return modelsFail(loaded.fail, env);

  const { rows, claude } = modelsCollect(loaded.cfg, includeClaude);
  if (!rows.length) {
    bad(t("models.noModels", { p: "cmd" }));
    info(t("models.noModelsHint"));
    return 1;
  }

  if (loaded.cfg.model) {
    ok(t("models.currentLabel", { m: `${C.cyan}${loaded.cfg.model}${C.reset}` }));
  } else {
    info(t("models.notSet"));
    info(t("models.notSetHint"));
  }

  say();
  modelsPrintTable(rows);
  say();

  const providers = includeClaude ? "cmd, cmd-claude" : "cmd";
  info(t("models.count", { n: rows.length, p: providers }));
  if (includeClaude && !Object.keys(claude).length) info(t("models.noClaude"));
  info(t("models.listSource"));
  return 0;
}

function modelsSet(env, includeClaude, arg) {
  if (arg === undefined || arg === null || String(arg).trim() === "") {
    warn(t("models.setUsage"));
    return 1;
  }

  const loaded = modelsLoad(env);
  if (loaded.fail) return modelsFail(loaded.fail, env);
  const cfg = loaded.cfg;

  const { rows } = modelsCollect(cfg, includeClaude);
  if (!rows.length) {
    bad(t("models.noModels", { p: "cmd" }));
    info(t("models.noModelsHint"));
    return 1;
  }

  const res = modelsResolve(arg, rows);
  if (res.err === "empty") { warn(t("models.setUsage")); return 1; }
  if (res.err === "index") { bad(t("models.badIndex", { n: res.n, max: res.max })); return 1; }
  if (res.err === "unknown") {
    bad(t("models.unknownModel", { m: res.id }));
    const close = modelsCloseMatches(res.id, rows);
    close.length
      ? info(t("models.closeMatches", { list: close.join(", ") }))
      : info(t("models.noCloseMatches"));
    return 1;
  }

  const { row } = res;
  const ref = `${row.provider}/${row.id}`;

  if (cfg.model === ref) {
    ok(t("models.alreadySet", { m: `${C.cyan}${ref}${C.reset}` }));
    return 0;
  }

  const bak = `${env.configFile}.bak-${stamp()}`;
  try {
    fs.copyFileSync(env.configFile, bak);
  } catch (e) {
    bad(t("models.writeFailed", { e: e.message }));
    return 1;
  }

  // Chỉ đổi `model`; mọi khoá khác (plugins, mcp, agents, providers...) giữ nguyên.
  cfg.model = ref;
  try {
    writeAtomic(env.configFile, JSON.stringify(cfg, null, 2) + "\n");
  } catch (e) {
    bad(t("models.writeFailed", { e: e.message }));
    return 1;
  }
  ok(t("models.backup", { f: path.basename(bak) }));

  let after = null;
  try { after = readJsonFile(env.configFile); } catch { after = null; }
  if (!after || after.model !== ref) {
    bad(t("models.confirmMismatch", { m: after?.model ?? "?" }));
    return 1;
  }

  ok(t("models.setDone", { m: `${C.cyan}${ref}${C.reset}` }));
  info(t("models.setHint"));
  return 0;
}

function modelsUnset(env) {
  const loaded = modelsLoad(env);
  if (loaded.fail) return modelsFail(loaded.fail, env);
  const cfg = loaded.cfg;

  if (!Object.hasOwn(cfg, "model")) {
    info(t("models.unsetAlready"));
    return 0;
  }

  const bak = `${env.configFile}.bak-${stamp()}`;
  try {
    fs.copyFileSync(env.configFile, bak);
  } catch (e) {
    bad(t("models.writeFailed", { e: e.message }));
    return 1;
  }

  delete cfg.model;
  try {
    writeAtomic(env.configFile, JSON.stringify(cfg, null, 2) + "\n");
  } catch (e) {
    bad(t("models.writeFailed", { e: e.message }));
    return 1;
  }
  ok(t("models.backup", { f: path.basename(bak) }));

  let after = null;
  try { after = readJsonFile(env.configFile); } catch { after = null; }
  if (!after || Object.hasOwn(after, "model")) {
    bad(t("models.confirmMismatch", { m: after?.model ?? "?" }));
    return 1;
  }

  ok(t("models.unsetDone"));
  return 0;
}

// ============================================================
// Lệnh
// ============================================================

export const modelsCmd = {
  name: "models",
  summary: () => t("models.summary"),

  async run(argv) {
    const args = Array.isArray(argv) ? argv.slice() : [];
    const includeClaude = args.includes("--claude");
    const positional = args.filter((a) => a !== "--claude");

    banner(t("models.title"));

    if (positional.includes("-h") || positional.includes("--help")) {
      say("  " + t("models.usage"));
      return 0;
    }

    const opt = positional.find((a) => a.startsWith("-"));
    if (opt) {
      warn(t("models.unknownOption", { o: opt }));
      say("  " + t("models.usage"));
      return 1;
    }

    const env = probeEnvironment();
    info(t("models.configLine", { p: env.configFile }));
    say();

    const action = positional[0];
    if (!action || action === "list") return modelsList(env, includeClaude);
    if (action === "set") return modelsSet(env, includeClaude, positional[1]);
    if (action === "unset") return modelsUnset(env);

    warn(t("models.unknownAction", { a: action }));
    say("  " + t("models.usage"));
    return 1;
  },
};
