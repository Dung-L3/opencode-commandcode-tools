// lib/doctor.mjs — lệnh con `doctor`: kiểm tra sức khoẻ toàn bộ hệ thống.
//
// CHỈ ĐỌC. Không ghi, không sửa, không cài gì cả.
//
// Kiểm lần lượt: Node, OpenCode, Command Code CLI, vị trí config, tính hợp lệ
// của config, provider đã nối chưa, API key còn sống không, (tuỳ chọn) model
// nào thật sự chạy được, MCP server, skills, backup.
//
// Trả mã thoát 0 nếu mọi thứ ổn, 1 nếu có mục hỏng.

import fs from "node:fs";
import path from "node:path";

import {
  API_BASE,
  C,
  assessConnection,
  bad,
  banner,
  fetchModels,
  findTool,
  info,
  isProviderPresent,
  listBackups,
  ok,
  probeEnvironment,
  registerMessages,
  say,
  step,
  t,
  warn,
} from "./shared.mjs";

registerMessages(
  {
    "doctor.summary": "Read-only health check of the whole stack",
    "doctor.title": "DOCTOR — HEALTH CHECK",
    "doctor.check1": "Node runtime",
    "doctor.check2": "OpenCode",
    "doctor.check3": "Command Code CLI",
    "doctor.check4": "Config location",
    "doctor.check5": "Config validity",
    "doctor.check6": "Provider wiring",
    "doctor.check7": "API key",
    "doctor.check8": "Model availability",
    "doctor.check9": "MCP servers",
    "doctor.check10": "Skills",
    "doctor.check11": "Backups",

    "doctor.nodeOk": "Node {v} (18+ required).",
    "doctor.nodeOld": "Node {v} is too old — fetch is missing, so this tool cannot work (18+ required).",
    "doctor.ocPresent": "OpenCode {v}",
    "doctor.ocMissing": "OpenCode was not found on PATH.",
    "doctor.cmdcPresent": "Command Code {v} (command: {n})",
    "doctor.cmdcMissing": "Command Code CLI was not found (optional — OpenCode still works).",

    "doctor.cfgDir": "Config directory: {p} (source: {src})",
    "doctor.cfgOk": "Config file parses fine ({s} bytes).",
    "doctor.cfgMissingFile": "No config file yet at {p}.",
    "doctor.cfgCorrupt": "{f} is not valid JSON.",
    "doctor.cfgCorruptHint": "Fix the JSON, then run doctor again.",
    "doctor.skipped": "Remaining checks were skipped because the config could not be read.",

    "doctor.providerPresent": "providers.{id}: {n} models",
    "doctor.providerAbsent": "providers.{id} is missing.",
    "doctor.providerOptional": "providers.cmd-claude is missing (optional — needed for Claude models).",

    "doctor.status": "Connection: {s}",
    "doctor.statusReady": "connected and ready",
    "doctor.statusNotConfigured": "not configured",
    "doctor.statusKeyInvalid": "configured, but the key is invalid",
    "doctor.statusUnverified": "configured, could not verify (offline)",

    "doctor.noKey": "No API key stored at providers.cmd.settings.apiKey.",
    "doctor.keyValid": "Key is valid — {n} models available.",
    "doctor.keyInvalid": "Key was rejected ({e}).",
    "doctor.keyUnreachable": "Could not reach Command Code ({e}) — network problem, not a failure.",

    "doctor.modelsHint": "Model testing skipped. Pass --models to test every model (slow: one request per model).",
    "doctor.modelsHeader": "Testing {n} models with a tiny request each...",
    "doctor.modelOk": "{id} — OK",
    "doctor.modelNotInPlan": "{id} — MODEL_NOT_IN_PLAN",
    "doctor.modelErr": "{id} — error: {e}",
    "doctor.modelsSummary": "Models tested: {n}, OK: {okCount}, not in plan: {na}, errors: {err}",

    "doctor.mcpPresent": "MCP servers ({n}): {list}",
    "doctor.mcpNone": "No MCP servers configured.",
    "doctor.skillsPresent": "Skills: {n} at {p}",
    "doctor.skillsNone": "No skills directory at {p}.",
    "doctor.backupsPresent": "Config backups: {n} (newest: {name})",
    "doctor.backupsNone": "No config backups yet.",

    "doctor.summaryCounts": "Checks: {passed} passed, {warned} warned, {failed} failed.",
    "doctor.healthy": "Everything looks good.",
    "doctor.unhealthy": "Some checks failed — see the ✗ lines above.",
  },
  {
    "doctor.summary": "Kiểm tra sức khoẻ toàn bộ hệ thống (chỉ đọc)",
    "doctor.title": "DOCTOR — KIỂM TRA SỨC KHOẺ",
    "doctor.check1": "Node runtime",
    "doctor.check2": "OpenCode",
    "doctor.check3": "Command Code CLI",
    "doctor.check4": "Vị trí config",
    "doctor.check5": "Tính hợp lệ của config",
    "doctor.check6": "Kết nối provider",
    "doctor.check7": "API key",
    "doctor.check8": "Model khả dụng",
    "doctor.check9": "MCP server",
    "doctor.check10": "Skills",
    "doctor.check11": "Bản sao lưu",

    "doctor.nodeOk": "Node {v} (cần >= 18).",
    "doctor.nodeOld": "Node {v} quá cũ — thiếu fetch nên công cụ không chạy được (cần >= 18).",
    "doctor.ocPresent": "OpenCode {v}",
    "doctor.ocMissing": "Không tìm thấy OpenCode trong PATH.",
    "doctor.cmdcPresent": "Command Code {v} (lệnh: {n})",
    "doctor.cmdcMissing": "Không tìm thấy Command Code CLI (không bắt buộc — OpenCode vẫn chạy).",

    "doctor.cfgDir": "Thư mục config: {p} (nguồn: {src})",
    "doctor.cfgOk": "File config đọc được ({s} byte).",
    "doctor.cfgMissingFile": "Chưa có file config tại {p}.",
    "doctor.cfgCorrupt": "{f} không phải JSON hợp lệ.",
    "doctor.cfgCorruptHint": "Sửa JSON rồi chạy lại doctor.",
    "doctor.skipped": "Bỏ qua các mục còn lại vì không đọc được config.",

    "doctor.providerPresent": "providers.{id}: {n} model",
    "doctor.providerAbsent": "Thiếu providers.{id}.",
    "doctor.providerOptional": "Thiếu providers.cmd-claude (không bắt buộc — dùng cho model Claude).",

    "doctor.status": "Kết nối: {s}",
    "doctor.statusReady": "đã nối sẵn sàng",
    "doctor.statusNotConfigured": "chưa cấu hình",
    "doctor.statusKeyInvalid": "có cấu hình nhưng key không hợp lệ",
    "doctor.statusUnverified": "có cấu hình, chưa kiểm tra được (offline)",

    "doctor.noKey": "Chưa lưu API key ở providers.cmd.settings.apiKey.",
    "doctor.keyValid": "Key hợp lệ — có {n} model.",
    "doctor.keyInvalid": "Key bị từ chối ({e}).",
    "doctor.keyUnreachable": "Không kết nối được Command Code ({e}) — lỗi mạng, không tính là hỏng.",

    "doctor.modelsHint": "Bỏ qua kiểm tra model. Thêm --models để thử từng model (chậm: mỗi model một request).",
    "doctor.modelsHeader": "Đang thử {n} model bằng một request nhỏ mỗi model...",
    "doctor.modelOk": "{id} — OK",
    "doctor.modelNotInPlan": "{id} — MODEL_NOT_IN_PLAN",
    "doctor.modelErr": "{id} — lỗi: {e}",
    "doctor.modelsSummary": "Đã thử: {n} model, OK: {okCount}, ngoài gói: {na}, lỗi: {err}",

    "doctor.mcpPresent": "MCP server ({n}): {list}",
    "doctor.mcpNone": "Chưa cấu hình MCP server nào.",
    "doctor.skillsPresent": "Skills: {n} tại {p}",
    "doctor.skillsNone": "Không có thư mục skills tại {p}.",
    "doctor.backupsPresent": "Bản sao lưu config: {n} (mới nhất: {name})",
    "doctor.backupsNone": "Chưa có bản sao lưu config.",

    "doctor.summaryCounts": "Kết quả: {passed} đạt, {warned} cảnh báo, {failed} hỏng.",
    "doctor.healthy": "Mọi thứ đều ổn.",
    "doctor.unhealthy": "Có mục bị hỏng — xem các dòng ✗ ở trên.",
  }
);

// ============================================================
// Bộ đếm — mọi định danh cấp cao nhất đều phải bắt đầu bằng `doctor`
// ============================================================

let doctorPass = 0;
let doctorWarn = 0;
let doctorFail = 0;

/** In một dòng kết quả và cập nhật bộ đếm. */
function doctorHit(level, msg) {
  if (level === "ok") { ok(msg); doctorPass++; }
  else if (level === "warn") { warn(msg); doctorWarn++; }
  else { bad(msg); doctorFail++; }
}

/** In trạng thái kết nối (kèm biểu tượng) nhưng KHÔNG đếm lại. */
function doctorStatusLine(doctorStatus) {
  const doctorMap = {
    ready: ["ok", t("doctor.statusReady")],
    "not-configured": ["bad", t("doctor.statusNotConfigured")],
    "key-invalid": ["bad", t("doctor.statusKeyInvalid")],
    "configured-unverified": ["warn", t("doctor.statusUnverified")],
  };
  const [doctorLevel, doctorText] = doctorMap[doctorStatus] || ["warn", String(doctorStatus)];
  const doctorText2 = t("doctor.status", { s: doctorText });
  if (doctorLevel === "ok") ok(doctorText2);
  else if (doctorLevel === "bad") bad(doctorText2);
  else warn(doctorText2);
}

/**
 * Thử một model bằng một request chat-completions thật, rất nhỏ.
 * max_tokens: 32 — API trả HTTP 400 nếu dưới 16 (đã từng dính lỗi này).
 */
async function doctorTestModel(doctorKey, doctorModel) {
  try {
    const res = await fetch(`${API_BASE}/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${doctorKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: doctorModel,
        messages: [{ role: "user", content: "ping" }],
        max_tokens: 32,
      }),
    });
    if (res.ok) return { kind: "ok" };
    const name = await res.text().catch(() => "");
    if (/MODEL_NOT_IN_PLAN/i.test(name)) return { kind: "plan" };
    return { kind: "err", e: `HTTP ${res.status}` };
  } catch (e) {
    return { kind: "err", e: String((e && e.message) || e) };
  }
}

/** In tổng kết và trả mã thoát. */
function doctorFinish() {
  say();
  say(`${C.cyan}${t("doctor.summaryCounts", { passed: doctorPass, warned: doctorWarn, failed: doctorFail })}${C.reset}`);
  if (doctorFail > 0) {
    say(`${C.red}${C.bold}${t("doctor.unhealthy")}${C.reset}`);
    return 1;
  }
  say(`${C.green}${C.bold}${t("doctor.healthy")}${C.reset}`);
  return 0;
}

export const doctorCmd = {
  name: "doctor",
  summary: () => t("doctor.summary"),

  async run(argv) {
    doctorPass = 0;
    doctorWarn = 0;
    doctorFail = 0;

    const args = argv || [];
    const testModels = args.includes("--models");

    banner(t("doctor.title"));

    // ---------- 1. Node ----------
    say();
    step("1/11", t("doctor.check1"));
    const doctorMajor = Number(String(process.version).replace(/^v/, "").split(".")[0]);
    if (doctorMajor >= 18) doctorHit("ok", t("doctor.nodeOk", { v: process.version }));
    else doctorHit("bad", t("doctor.nodeOld", { v: process.version }));

    const doctorEnv = probeEnvironment();
    const doctorOc = doctorEnv.opencode || findTool(["opencode"]);
    const doctorCmdc = doctorEnv.cmdc || findTool(["cmdc", "command-code", "cmd"]);

    // ---------- 2. OpenCode ----------
    say();
    step("2/11", t("doctor.check2"));
    if (doctorOc) doctorHit("ok", t("doctor.ocPresent", { v: doctorOc.version }));
    else doctorHit("bad", t("doctor.ocMissing"));

    // ---------- 3. Command Code CLI ----------
    say();
    step("3/11", t("doctor.check3"));
    if (doctorCmdc) doctorHit("ok", t("doctor.cmdcPresent", { v: doctorCmdc.version, n: doctorCmdc.name }));
    else doctorHit("warn", t("doctor.cmdcMissing"));

    // ---------- 4. Vị trí config ----------
    say();
    step("4/11", t("doctor.check4"));
    doctorHit("ok", t("doctor.cfgDir", { p: doctorEnv.configDir, src: doctorEnv.configSrc }));

    // ---------- 5. Tính hợp lệ của config ----------
    say();
    step("5/11", t("doctor.check5"));
    if (doctorEnv.existing === null) {
      doctorHit("bad", t("doctor.cfgCorrupt", { f: doctorEnv.configFile }));
      info(t("doctor.cfgCorruptHint"));
      info(t("doctor.skipped"));
      return doctorFinish();
    }
    if (fs.existsSync(doctorEnv.configFile)) {
      doctorHit("ok", t("doctor.cfgOk", { s: fs.statSync(doctorEnv.configFile).size }));
    } else {
      doctorHit("warn", t("doctor.cfgMissingFile", { p: doctorEnv.configFile }));
    }

    const doctorCfg = doctorEnv.existing || {};

    // ---------- 6. Provider ----------
    say();
    step("6/11", t("doctor.check6"));
    if (isProviderPresent(doctorCfg, "cmd")) {
      const doctorCmdModels = Object.keys(doctorCfg.providers.cmd?.models || {});
      doctorHit("ok", t("doctor.providerPresent", { id: "cmd", n: doctorCmdModels.length }));
    } else {
      doctorHit("bad", t("doctor.providerAbsent", { id: "cmd" }));
    }
    if (isProviderPresent(doctorCfg, "cmd-claude")) {
      const doctorClaudeModels = Object.keys(doctorCfg.providers["cmd-claude"]?.models || {});
      doctorHit("ok", t("doctor.providerPresent", { id: "cmd-claude", n: doctorClaudeModels.length }));
    } else {
      doctorHit("warn", t("doctor.providerOptional"));
    }

    // ---------- 7. API key ----------
    say();
    step("7/11", t("doctor.check7"));
    const doctorKey = doctorCfg?.providers?.cmd?.settings?.apiKey;
    let doctorKeyValid = null;
    if (!doctorKey) {
      doctorHit("bad", t("doctor.noKey"));
    } else {
      try {
        const doctorLiveModels = await fetchModels(doctorKey);
        doctorKeyValid = true;
        doctorHit("ok", t("doctor.keyValid", { n: doctorLiveModels.length }));
      } catch (e) {
        const doctorMsg = String((e && e.message) || e);
        if (/^HTTP /.test(doctorMsg)) {
          doctorKeyValid = false;
          doctorHit("bad", t("doctor.keyInvalid", { e: doctorMsg }));
        } else {
          doctorKeyValid = null;
          doctorHit("warn", t("doctor.keyUnreachable", { e: doctorMsg }));
        }
      }
    }
    doctorStatusLine(assessConnection(doctorCfg, doctorKeyValid));

    // ---------- 8. Model khả dụng (chỉ khi --models) ----------
    say();
    step("8/11", t("doctor.check8"));
    if (!testModels) {
      info(t("doctor.modelsHint"));
    } else if (!doctorKey) {
      warn(t("doctor.noKey"));
    } else {
      const doctorIds = Object.keys(doctorCfg?.providers?.cmd?.models || {});
      say("      " + t("doctor.modelsHeader", { n: doctorIds.length }));
      let doctorOk = 0;
      let doctorPlan = 0;
      let doctorErr = 0;
      for (const doctorId of doctorIds) {
        const doctorR = await doctorTestModel(doctorKey, doctorId);
        if (doctorR.kind === "ok") { doctorOk++; ok(t("doctor.modelOk", { id: doctorId })); }
        else if (doctorR.kind === "plan") { doctorPlan++; warn(t("doctor.modelNotInPlan", { id: doctorId })); }
        else { doctorErr++; bad(t("doctor.modelErr", { id: doctorId, e: doctorR.e })); }
      }
      const doctorSummary = t("doctor.modelsSummary", {
        n: doctorIds.length, okCount: doctorOk, na: doctorPlan, err: doctorErr,
      });
      if (doctorErr === 0) doctorHit("ok", doctorSummary);
      else if (doctorOk + doctorPlan === 0) doctorHit("bad", doctorSummary);
      else doctorHit("warn", doctorSummary);
    }

    // ---------- 9. MCP server ----------
    say();
    step("9/11", t("doctor.check9"));
    const doctorMcp = doctorCfg?.mcp;
    const doctorMcpNames = [];
    if (doctorMcp && typeof doctorMcp === "object") {
      for (const doctorN of Object.keys(doctorMcp)) {
        if (doctorN !== "servers") doctorMcpNames.push(doctorN);
      }
      const doctorSrv = doctorMcp.servers;
      if (doctorSrv && typeof doctorSrv === "object") {
        for (const doctorN of Object.keys(doctorSrv)) {
          if (!doctorMcpNames.includes(doctorN)) doctorMcpNames.push(doctorN);
        }
      }
    }
    if (doctorMcpNames.length) {
      doctorHit("ok", t("doctor.mcpPresent", { n: doctorMcpNames.length, list: doctorMcpNames.join(", ") }));
    } else {
      info(t("doctor.mcpNone"));
    }

    // ---------- 10. Skills ----------
    say();
    step("10/11", t("doctor.check10"));
    const doctorSkillsDir = path.join(doctorEnv.configDir, "skills");
    let doctorSkillCount = 0;
    let doctorHasSkills = false;
    try {
      if (fs.existsSync(doctorSkillsDir) && fs.statSync(doctorSkillsDir).isDirectory()) {
        doctorHasSkills = true;
        doctorSkillCount = fs.readdirSync(doctorSkillsDir, { withFileTypes: true })
          .filter((doctorD) => doctorD.isDirectory()).length;
      }
    } catch { /* thư mục không đọc được — coi như không có */ }
    if (doctorHasSkills) doctorHit("ok", t("doctor.skillsPresent", { n: doctorSkillCount, p: doctorSkillsDir }));
    else info(t("doctor.skillsNone", { p: doctorSkillsDir }));

    // ---------- 11. Backup ----------
    say();
    step("11/11", t("doctor.check11"));
    const doctorBackups = listBackups(doctorEnv.configFile);
    if (doctorBackups.length) {
      doctorHit("ok", t("doctor.backupsPresent", { n: doctorBackups.length, name: doctorBackups[0].name }));
    } else {
      doctorHit("warn", t("doctor.backupsNone"));
    }

    return doctorFinish();
  },
};
