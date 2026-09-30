// lib/probe.mjs — lệnh con `probe`: dò xem GÓI hiện tại thực sự dùng được model nào.
//
// /models trả về đủ bộ model bất kể gói, nhiều model bị chặn. Lệnh này gọi thử
// từng model bằng một request chat ngắn rồi phân loại: dùng được / cần gói cao
// hơn / tạm bị giới hạn / lỗi. Mặc định chỉ BÁO CÁO, không sửa gì; thêm --write
// mới lọc providers.cmd.models còn đúng các model dùng được (có backup trước).
//
// Bài học cũ: max_tokens phải >= 16. Bản probe trước dùng max_tokens = 1 nên
// API trả HTTP 400 `Invalid 'max_output_tokens'` và báo hỏng oan.

import fs from "node:fs";
import path from "node:path";

import {
  API_BASE, C, bad, banner, fetchModels, info, ok, probeEnvironment,
  readConfigIfAny, registerMessages, say, stamp, t, warn, writeAtomic,
} from "./shared.mjs";

registerMessages(
  {
    "probe.summary": "Show which Command Code models your plan can actually use",
    "probe.title": "PROBE  —  WHICH MODELS ACTUALLY WORK",
    "probe.configBad": "{f} is not valid JSON.",
    "probe.noKey": "No API key in providers.cmd.settings.apiKey.",
    "probe.noKeyHint": "Run `install` first to wire Command Code into OpenCode.",
    "probe.fetching": "Asking Command Code for the model list...",
    "probe.fetchOk": "Got {n} models.",
    "probe.fetchFailed": "Could not fetch the model list ({e}).",
    "probe.only": "Only models whose id contains \"{q}\": {n}.",
    "probe.onlyNone": "No model id contains \"{q}\".",
    "probe.onlyNeedsArg": "--only needs a substring.",
    "probe.argUnknown": "Ignoring unknown option: {a}",
    "probe.probing": "Probing {n} models ({k} at a time)...",
    "probe.lineOk": "{id}",
    "probe.linePlan": "{id} — needs a higher plan",
    "probe.lineRate": "{id} — rate-limited",
    "probe.lineErr": "{id} — {reason}",
    "probe.report": "RESULT",
    "probe.labelOk": "usable",
    "probe.labelPlan": "needs a higher plan",
    "probe.labelRate": "rate-limited",
    "probe.labelErr": "errors",
    "probe.listPlan": "Needs a higher plan ({n})",
    "probe.listRate": "Rate-limited ({n})",
    "probe.listErr": "Errors ({n})",
    "probe.done": "Done: {ok} usable, {plan} gated, {rate} rate-limited, {err} errors.",
    "probe.writeRefused": "--write cannot be combined with --only (it would remove models that were never probed).",
    "probe.writeNoOk": "No model came back usable — writing nothing.",
    "probe.writeHeader": "Writing config",
    "probe.writeConfig": "Config: {p}",
    "probe.writeBackup": "Backup: {f}",
    "probe.writeKept": "Kept {kept} models, removed {removed}.",
    "probe.writeJsonNote": "Config written: kept {kept}, removed {removed}.",
    "probe.writeFailed": "Could not write the config ({e}).",
  },
  {
    "probe.summary": "Xem gói hiện tại THỰC SỰ dùng được những model nào",
    "probe.title": "DÒ MODEL  —  MODEL NÀO DÙNG ĐƯỢC THẬT",
    "probe.configBad": "{f} không phải JSON hợp lệ.",
    "probe.noKey": "Không thấy API key trong providers.cmd.settings.apiKey.",
    "probe.noKeyHint": "Chạy `install` trước để nối Command Code vào OpenCode.",
    "probe.fetching": "Đang hỏi máy chủ Command Code danh sách model...",
    "probe.fetchOk": "Nhận được {n} model.",
    "probe.fetchFailed": "Không lấy được danh sách model ({e}).",
    "probe.only": "Chỉ probe model có id chứa \"{q}\": {n}.",
    "probe.onlyNone": "Không có model nào có id chứa \"{q}\".",
    "probe.onlyNeedsArg": "--only cần một chuỗi con.",
    "probe.argUnknown": "Bỏ qua tuỳ chọn lạ: {a}",
    "probe.probing": "Đang probe {n} model (mỗi lượt {k} cái)...",
    "probe.lineOk": "{id}",
    "probe.linePlan": "{id} — cần gói cao hơn",
    "probe.lineRate": "{id} — tạm bị giới hạn",
    "probe.lineErr": "{id} — {reason}",
    "probe.report": "KẾT QUẢ",
    "probe.labelOk": "dùng được",
    "probe.labelPlan": "cần gói cao hơn",
    "probe.labelRate": "tạm bị giới hạn",
    "probe.labelErr": "lỗi",
    "probe.listPlan": "Cần gói cao hơn ({n})",
    "probe.listRate": "Tạm bị giới hạn ({n})",
    "probe.listErr": "Lỗi ({n})",
    "probe.done": "Xong: {ok} dùng được, {plan} bị chặn, {rate} tạm giới hạn, {err} lỗi.",
    "probe.writeRefused": "Không thể dùng --write cùng --only (sẽ xoá cả model chưa probe).",
    "probe.writeNoOk": "Không có model nào dùng được — không ghi gì cả.",
    "probe.writeHeader": "Ghi cấu hình",
    "probe.writeConfig": "Config: {p}",
    "probe.writeBackup": "Backup: {f}",
    "probe.writeKept": "Giữ {kept} model, xoá {removed}.",
    "probe.writeJsonNote": "Đã ghi config: giữ {kept}, xoá {removed}.",
    "probe.writeFailed": "Không ghi được config ({e}).",
  }
);

// max_tokens >= 16 là bắt buộc; 32 cho an toàn. Concurrency ~6 để không quá chậm.
const probeMaxTokens = 32;
const probeConcurrency = 6;
const probeTimeoutMs = 60000;

// ------------------------------------------------------------
// Tham số dòng lệnh
// ------------------------------------------------------------

function probeParseArgs(argv) {
  const opts = { json: false, write: false, only: null, onlyMissing: false, unknown: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--json") opts.json = true;
    else if (a === "--write") opts.write = true;
    else if (a === "--only") {
      if (i + 1 < argv.length) opts.only = argv[++i];
      else opts.onlyMissing = true;
    } else if (a.startsWith("--only=")) {
      opts.only = a.slice("--only=".length);
    } else opts.unknown.push(a);
  }
  return opts;
}

// ------------------------------------------------------------
// Gọi thử một model
// ------------------------------------------------------------

/** Lấy message lỗi gọn (tối đa ~80 ký tự) từ body trả về. */
function probeReason(body) {
  const raw = String(body ?? "").trim();
  let msg = "";
  try {
    const j = JSON.parse(raw);
    msg = j?.error?.message || j?.error?.code
      || (typeof j?.error === "string" ? j.error : "")
      || j?.message || "";
  } catch {
    msg = raw;
  }
  return String(msg).replace(/\s+/g, " ").trim().slice(0, 80);
}

async function probeOne(key, id) {
  const signal = typeof AbortSignal !== "undefined" && AbortSignal.timeout
    ? AbortSignal.timeout(probeTimeoutMs)
    : undefined;
  try {
    const res = await fetch(`${API_BASE}/chat/completions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: id,
        max_tokens: probeMaxTokens,
        messages: [{ role: "user", content: "hi" }],
      }),
      signal,
    });
    const body = await res.text();
    if (res.ok) return { id, class: "ok", reason: "" };
    if (res.status === 403 && body.includes("MODEL_NOT_IN_PLAN")) {
      return { id, class: "plan", reason: "" };
    }
    if (res.status === 429) return { id, class: "rate", reason: "" };
    return { id, class: "err", reason: probeReason(body) || `HTTP ${res.status}` };
  } catch (e) {
    return { id, class: "err", reason: probeReason(e?.message || String(e)) || "network error" };
  }
}

/**
 * Chạy worker với concurrency giới hạn, nhưng vẫn IN THEO ĐÚNG THỨ TỰ:
 * kết quả nào xong trước cũng được xếp vào mảng, chỉ in khi các index trước
 * đã có đủ. Nhanh như pool, gọn như chạy tuần tự.
 */
async function probeRunPool(items, limit, worker, onResult) {
  const results = new Array(items.length);
  let next = 0;
  let flushTo = 0;

  const flush = () => {
    while (flushTo < items.length && results[flushTo] !== undefined) {
      if (onResult) onResult(results[flushTo]);
      flushTo++;
    }
  };

  const runOne = async () => {
    for (;;) {
      const i = next++;
      if (i >= items.length) return;
      results[i] = await worker(items[i], i);
      flush();
    }
  };

  const n = Math.min(limit, items.length);
  await Promise.all(Array.from({ length: n }, runOne));
  return results;
}

// ------------------------------------------------------------
// In báo cáo
// ------------------------------------------------------------

function probeLine(r) {
  if (r.class === "ok") ok(t("probe.lineOk", { id: r.id }));
  else if (r.class === "plan") warn(t("probe.linePlan", { id: r.id }));
  else if (r.class === "rate") warn(t("probe.lineRate", { id: r.id }));
  else bad(t("probe.lineErr", { id: r.id, reason: r.reason }));
}

function probeClassifyAll(results) {
  const rep = { ok: [], plan: [], rate: [], err: [] };
  for (const r of results) {
    if (r.class === "ok") rep.ok.push(r.id);
    else if (r.class === "plan") rep.plan.push({ id: r.id, reason: t("probe.labelPlan") });
    else if (r.class === "rate") rep.rate.push({ id: r.id, reason: t("probe.labelRate") });
    else rep.err.push({ id: r.id, reason: r.reason });
  }
  return rep;
}

function probePrintList(title, entries) {
  if (!entries.length) return;
  say();
  say(`      ${C.bold}${title}${C.reset}`);
  for (const e of entries) {
    say(`        ${C.yellow}-${C.reset} ${e.id}  ${C.dim}${e.reason}${C.reset}`);
  }
}

function probePrintReport(rep) {
  say();
  say(`${C.cyan}${t("probe.report")}${C.reset}`);
  const rows = [
    [t("probe.labelOk"), rep.ok.length],
    [t("probe.labelPlan"), rep.plan.length],
    [t("probe.labelRate"), rep.rate.length],
    [t("probe.labelErr"), rep.err.length],
  ];
  for (const [label, n] of rows) say(`      ${label.padEnd(24)}${n}`);

  probePrintList(t("probe.listPlan", { n: rep.plan.length }), rep.plan);
  probePrintList(t("probe.listRate", { n: rep.rate.length }), rep.rate);
  probePrintList(t("probe.listErr", { n: rep.err.length }), rep.err);
}

// ------------------------------------------------------------
// --write: lọc providers.cmd.models còn đúng các model dùng được
// ------------------------------------------------------------

function probeWriteConfig(configFile, okIds, opts) {
  const fresh = readConfigIfAny(configFile);
  if (fresh === null) {
    bad(t("probe.configBad", { f: configFile }));
    return 1;
  }

  let kept = 0;
  let removed = 0;
  const cfg = structuredClone(fresh);
  const models = cfg?.providers?.cmd?.models || {};
  const keptModels = {};
  for (const [id, def] of Object.entries(models)) {
    if (okIds.has(id)) { keptModels[id] = def; kept++; }
    else removed++;
  }
  cfg.providers.cmd.models = keptModels;

  const st = stamp();
  const backup = `${configFile}.bak-${st}`;
  try {
    fs.copyFileSync(configFile, backup);
    writeAtomic(configFile, JSON.stringify(cfg, null, 2) + "\n");
  } catch (e) {
    if (opts.json) console.error(t("probe.writeFailed", { e: e.message }));
    else bad(t("probe.writeFailed", { e: e.message }));
    return 1;
  }

  if (opts.json) {
    console.error(t("probe.writeBackup", { f: backup }));
    console.error(t("probe.writeJsonNote", { kept, removed }));
    return 0;
  }

  say();
  say(`${C.cyan}${t("probe.writeHeader")}${C.reset}`);
  info(t("probe.writeConfig", { p: configFile }));
  ok(t("probe.writeBackup", { f: path.basename(backup) }));
  ok(t("probe.writeKept", { kept, removed }));
  return 0;
}

// ------------------------------------------------------------
// Lệnh con
// ------------------------------------------------------------

export const probeCmd = {
  name: "probe",
  summary: () => t("probe.summary"),

  async run(argv) {
    const opts = probeParseArgs(argv);

    if (opts.onlyMissing) {
      bad(t("probe.onlyNeedsArg"));
      return 1;
    }
    if (opts.write && opts.only) {
      bad(t("probe.writeRefused"));
      return 1;
    }

    if (!opts.json) banner(t("probe.title"));
    for (const a of opts.unknown) warn(t("probe.argUnknown", { a }));

    const env = probeEnvironment();
    if (env.existing === null) {
      bad(t("probe.configBad", { f: env.configFile }));
      return 1;
    }

    const key = env.existing?.providers?.cmd?.settings?.apiKey;
    if (!key) {
      say();
      bad(t("probe.noKey"));
      info(t("probe.noKeyHint"));
      return 1;
    }

    if (!opts.json) {
      say();
      say("      " + t("probe.fetching"));
    }

    let models;
    try {
      models = await fetchModels(key);
    } catch (e) {
      bad(t("probe.fetchFailed", { e: e.message }));
      return 1;
    }

    let ids = models.map((m) => (typeof m === "string" ? m : m?.id)).filter(Boolean);

    if (opts.only) {
      const q = opts.only.toLowerCase();
      ids = ids.filter((id) => id.toLowerCase().includes(q));
      if (!opts.json) info(t("probe.only", { q: opts.only, n: ids.length }));
      if (ids.length === 0) {
        warn(t("probe.onlyNone", { q: opts.only }));
        return 0;
      }
    } else if (!opts.json) {
      ok(t("probe.fetchOk", { n: ids.length }));
    }

    if (!opts.json) {
      say("      " + t("probe.probing", { n: ids.length, k: Math.min(probeConcurrency, ids.length) }));
      say();
    }

    const results = await probeRunPool(
      ids,
      probeConcurrency,
      (id) => probeOne(key, id),
      opts.json ? null : probeLine
    );

    const rep = probeClassifyAll(results);

    if (opts.json) say(JSON.stringify(rep, null, 2));
    else probePrintReport(rep);

    if (opts.write) {
      if (rep.ok.length === 0) {
        if (opts.json) console.error(t("probe.writeNoOk"));
        else warn(t("probe.writeNoOk"));
      } else {
        const code = probeWriteConfig(env.configFile, new Set(rep.ok), opts);
        if (code !== 0) return code;
      }
    }

    if (!opts.json) {
      say();
      say("  " + t("probe.done", {
        ok: rep.ok.length, plan: rep.plan.length, rate: rep.rate.length, err: rep.err.length,
      }));
    }
    return 0;
  },
};
