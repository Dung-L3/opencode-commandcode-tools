// lib/backup.mjs — lệnh con `backup`: xem, phục hồi và dọn bớt các bản sao lưu
// `opencode.json.bak-<mốc thời gian>` mà installer tạo mỗi lần ghi config.
//
// Ba việc: liệt kê (mặc định), `restore <số|tên>`, `prune [--keep N] [--dry-run]`.
// Module chỉ dùng shared.mjs và các module `node:` dựng sẵn.
//
// Mọi tên khai báo ở cấp cao nhất đều bắt đầu bằng `backup` vì bản build gộp
// phẳng tất cả module vào một phạm vi — tên không tiền tố sẽ đụng nhau.

import {
  C, askYes, bad, banner, info, listBackups, ok, probeEnvironment,
  readJsonFile, registerMessages, say, stamp, t, warn, writeAtomic,
} from "./shared.mjs";

import fs from "node:fs";
import path from "node:path";

registerMessages(
  {
    "backup.summary": "Manage config backups: list, restore, prune",
    "backup.title": "CONFIG BACKUPS",
    "backup.configLabel": "Config file: {p}",
    "backup.empty": "No backups yet. One is created each time the config is written.",
    "backup.hIndex": "#",
    "backup.hWhen": "When",
    "backup.hSize": "Size",
    "backup.hFile": "File",
    "backup.newest": "newest",
    "backup.count": "{n} backup(s).",
    "backup.hint": "backup restore <n|name>   ·   backup prune [--keep N] [--dry-run]",
    "backup.unknownAction": "Unknown action: {a}",
    "backup.usage": "Usage: backup [list] | backup restore <n|name> [--yes] | backup prune [--keep N] [--dry-run] [--yes]",

    "backup.restore.needTarget": "Say which backup to restore: backup restore <n|name>",
    "backup.restore.notFound": "No backup matches \"{s}\".",
    "backup.restore.ambiguous": "\"{s}\" matches several backups:",
    "backup.restore.unreadable": "Cannot read {f}: {e}",
    "backup.restore.invalidJson": "{f} is not valid JSON — stopped, nothing was restored.",
    "backup.restore.confirm": "Overwrite the current config with {f}? (y/N) ",
    "backup.restore.declined": "Cancelled — the config is untouched.",
    "backup.restore.savedCurrent": "Current config saved as {f}",
    "backup.restore.noCurrent": "No current config file to save.",
    "backup.restore.done": "Restored: {f}",
    "backup.restore.verify": "Verified: {p} provider(s), providers.cmd has {n} model(s).",
    "backup.restore.verifyFail": "The file was written but could not be read back: {e}",

    "backup.prune.keepBad": "Invalid --keep value, using {n}.",
    "backup.prune.nothing": "Nothing to prune — only {n} backup(s), keeping the newest {k}.",
    "backup.prune.dryRun": "Dry run — nothing will be deleted.",
    "backup.prune.willDelete": "Old backups to delete: {n}, keeping the newest {k}.",
    "backup.prune.confirm": "Delete these {n} backup(s)? (y/N) ",
    "backup.prune.declined": "Cancelled — nothing was deleted.",
    "backup.prune.deleted": "Deleted {f}",
    "backup.prune.deleteFail": "Could not delete {f}: {e}",
    "backup.prune.done": "Pruned {n} backup(s), kept the newest {k}.",
  },
  {
    "backup.summary": "Quản lý bản sao lưu cấu hình: liệt kê, phục hồi, dọn bớt",
    "backup.title": "BẢN SAO LƯU CẤU HÌNH",
    "backup.configLabel": "File cấu hình: {p}",
    "backup.empty": "Chưa có bản sao lưu nào. Mỗi lần ghi cấu hình sẽ tự tạo một bản.",
    "backup.hIndex": "#",
    "backup.hWhen": "Thời gian",
    "backup.hSize": "Dung lượng",
    "backup.hFile": "Tên file",
    "backup.newest": "mới nhất",
    "backup.count": "{n} bản sao lưu.",
    "backup.hint": "backup restore <số|tên>   ·   backup prune [--keep N] [--dry-run]",
    "backup.unknownAction": "Hành động không rõ: {a}",
    "backup.usage": "Cách dùng: backup [list] | backup restore <số|tên> [--yes] | backup prune [--keep N] [--dry-run] [--yes]",

    "backup.restore.needTarget": "Cần chỉ rõ bản muốn phục hồi: backup restore <số|tên>",
    "backup.restore.notFound": "Không có bản sao lưu nào khớp \"{s}\".",
    "backup.restore.ambiguous": "\"{s}\" khớp nhiều bản sao lưu:",
    "backup.restore.unreadable": "Không đọc được {f}: {e}",
    "backup.restore.invalidJson": "{f} không phải JSON hợp lệ — đã dừng, chưa phục hồi gì.",
    "backup.restore.confirm": "Ghi đè cấu hình hiện tại bằng {f}? (y/N) ",
    "backup.restore.declined": "Đã huỷ — cấu hình vẫn nguyên vẹn.",
    "backup.restore.savedCurrent": "Đã lưu cấu hình hiện tại thành {f}",
    "backup.restore.noCurrent": "Không có file cấu hình hiện tại để lưu.",
    "backup.restore.done": "Đã phục hồi: {f}",
    "backup.restore.verify": "Đã kiểm chứng: {p} provider, providers.cmd có {n} model.",
    "backup.restore.verifyFail": "Đã ghi file nhưng không đọc lại được: {e}",

    "backup.prune.keepBad": "Giá trị --keep không hợp lệ, dùng {n}.",
    "backup.prune.nothing": "Không có gì để dọn — chỉ có {n} bản, giữ {k} bản mới nhất.",
    "backup.prune.dryRun": "Chạy thử — sẽ không xoá gì cả.",
    "backup.prune.willDelete": "Bản cũ sẽ xoá: {n}, giữ lại {k} bản mới nhất.",
    "backup.prune.confirm": "Xoá {n} bản sao lưu này? (y/N) ",
    "backup.prune.declined": "Đã huỷ — không xoá gì.",
    "backup.prune.deleted": "Đã xoá {f}",
    "backup.prune.deleteFail": "Không xoá được {f}: {e}",
    "backup.prune.done": "Đã dọn {n} bản, giữ {k} bản mới nhất.",
  }
);

// ============================================================
// Hàm phụ trợ
// ============================================================

/** Tách argv thành hành động + cờ. Cờ có thể đứng ở bất kỳ đâu. */
function backupParseArgs(argv) {
  const out = { action: "list", target: null, keep: 5, keepSet: false, yes: false, dryRun: false };
  const pos = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--yes" || a === "-y") { out.yes = true; continue; }
    if (a === "--dry-run") { out.dryRun = true; continue; }
    if (a === "--keep") { out.keep = Number(argv[++i]); out.keepSet = true; continue; }
    if (a.startsWith("--keep=")) { out.keep = Number(a.slice("--keep=".length)); out.keepSet = true; continue; }
    pos.push(a);
  }
  if (pos.length) out.action = pos[0];
  out.target = pos[1] ?? null;
  return out;
}

/** Giờ địa phương, dạng đọc được: YYYY-MM-DD HH:mm:ss. */
function backupFmtTime(d) {
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ` +
    `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

/** Cỡ file theo KB, một chữ số thập phân. */
function backupFmtKb(bytes) {
  return `${(bytes / 1024).toFixed(1)} KB`;
}

/**
 * Tìm bản sao lưu theo số thứ tự (1-based như đã in) hoặc theo tên
 * (khớp tuyệt đối trước, rồi khớp một phần). Trả về {item} hoặc {error, matches}.
 */
function backupResolve(list, spec) {
  const s = String(spec ?? "").trim();
  if (!s) return { error: t("backup.restore.notFound", { s }) };

  if (/^\d+$/.test(s)) {
    const n = Number(s);
    if (n >= 1 && n <= list.length) return { item: list[n - 1] };
    return { error: t("backup.restore.notFound", { s }) };
  }

  const exact = list.filter((b) => b.name === s);
  if (exact.length === 1) return { item: exact[0] };

  const partial = list.filter((b) => b.name.includes(s));
  if (partial.length === 1) return { item: partial[0] };
  if (partial.length > 1) return { error: t("backup.restore.ambiguous", { s }), matches: partial };
  return { error: t("backup.restore.notFound", { s }) };
}

/** In bảng danh sách, bản mới nhất được đánh dấu. */
function backupDoList(list, configFile) {
  banner(t("backup.title"));
  say();
  say(`  ${t("backup.configLabel", { p: configFile })}`);
  say();

  if (list.length === 0) {
    info(t("backup.empty"));
    return 0;
  }

  say(`  ${C.bold}${t("backup.hIndex").padEnd(4)}${t("backup.hWhen").padEnd(22)}` +
    `${t("backup.hSize").padStart(10)}  ${t("backup.hFile")}${C.reset}`);

  list.forEach((b, i) => {
    const mark = i === 0 ? `  ${C.green}← ${t("backup.newest")}${C.reset}` : "";
    say(`  ${String(i + 1).padStart(2)}. ` +
      `${backupFmtTime(b.mtime)}   ` +
      `${backupFmtKb(b.size).padStart(9)}  ` +
      `${b.name}${mark}`);
  });

  say();
  info(t("backup.count", { n: list.length }));
  info(t("backup.hint"));
  return 0;
}

/** Phục hồi một bản sao lưu đè lên config. Trả về mã thoát. */
async function backupDoRestore(list, configFile, target, yes) {
  const r = backupResolve(list, target);
  if (r.error) {
    bad(r.error);
    if (r.matches) for (const b of r.matches) info(b.name);
    return 1;
  }
  const item = r.item;

  // Đọc trước để chắc chắn bản sao lưu dùng được TRƯỚC khi động vào config.
  let text;
  try {
    text = fs.readFileSync(item.path, "utf8");
  } catch (e) {
    bad(t("backup.restore.unreadable", { f: item.name, e: e.message }));
    return 1;
  }
  try {
    readJsonFile(item.path);
  } catch {
    bad(t("backup.restore.invalidJson", { f: item.name }));
    return 1;
  }

  if (!yes && !(await askYes("      " + t("backup.restore.confirm", { f: item.name }), false))) {
    warn(t("backup.restore.declined"));
    return 0; // người dùng từ chối vẫn là "thành công" (không làm gì).
  }

  // Lưu config HIỆN TẠI thành một bản mới, để chính lần restore này hoàn tác được.
  try {
    if (fs.existsSync(configFile)) {
      let dest = `${configFile}.bak-${stamp()}`;
      for (let i = 1; fs.existsSync(dest); i++) dest = `${configFile}.bak-${stamp()}-${i}`;
      writeAtomic(dest, fs.readFileSync(configFile, "utf8"));
      ok(t("backup.restore.savedCurrent", { f: path.basename(dest) }));
    } else {
      info(t("backup.restore.noCurrent"));
    }
  } catch (e) {
    bad(t("backup.restore.unreadable", { f: configFile, e: e.message }));
    return 1;
  }

  try {
    writeAtomic(configFile, text);
  } catch (e) {
    bad(t("backup.restore.unreadable", { f: configFile, e: e.message }));
    return 1;
  }
  ok(t("backup.restore.done", { f: item.name }));

  // Kiểm chứng: đọc lại và đếm provider / model của providers.cmd.
  try {
    const cfg = readJsonFile(configFile);
    const p = Object.keys(cfg.providers || {}).length;
    const n = Object.keys(cfg.providers?.cmd?.models || {}).length;
    ok(t("backup.restore.verify", { p, n }));
  } catch (e) {
    warn(t("backup.restore.verifyFail", { e: e.message }));
  }
  return 0;
}

/** Dọn bớt bản cũ, luôn giữ ít nhất bản mới nhất. Trả về mã thoát. */
async function backupDoPrune(list, keep, yes, dryRun) {
  const candidates = list.slice(keep); // keep >= 1 nên bản mới nhất (index 0) không bao giờ bị đụng.

  if (candidates.length === 0) {
    info(t("backup.prune.nothing", { n: list.length, k: Math.min(keep, list.length) }));
    return 0;
  }

  say(`      ${t("backup.prune.willDelete", { n: candidates.length, k: keep })}`);
  for (const b of candidates) say(`        ${C.yellow}${b.name}${C.reset}`);

  if (dryRun) {
    say();
    info(t("backup.prune.dryRun"));
    return 0;
  }

  if (!yes && !(await askYes("      " + t("backup.prune.confirm", { n: candidates.length }), false))) {
    warn(t("backup.prune.declined"));
    return 0;
  }

  let gone = 0;
  for (const b of candidates) {
    try {
      fs.unlinkSync(b.path);
      gone++;
      ok(t("backup.prune.deleted", { f: b.name }));
    } catch (e) {
      bad(t("backup.prune.deleteFail", { f: b.name, e: e.message }));
    }
  }

  if (gone !== candidates.length) return 1;
  ok(t("backup.prune.done", { n: gone, k: keep }));
  return 0;
}

// ============================================================
// Lệnh con
// ============================================================

export const backupCmd = {
  name: "backup",
  summary: () => t("backup.summary"),

  async run(argv) {
    const { action, target, keep, keepSet, yes, dryRun } = backupParseArgs(argv);
    const configFile = probeEnvironment().configFile;

    if (action === "list" || action === "ls") {
      return backupDoList(listBackups(configFile), configFile);
    }

    if (action === "restore") {
      if (!target) {
        bad(t("backup.restore.needTarget"));
        return 1;
      }
      banner(t("backup.title"));
      say();
      say(`  ${t("backup.configLabel", { p: configFile })}`);
      say();
      return backupDoRestore(listBackups(configFile), configFile, target, yes);
    }

    if (action === "prune") {
      let n = keep;
      if (!Number.isInteger(n) || n < 1) {
        if (keepSet) warn(t("backup.prune.keepBad", { n: 1 }));
        n = 1; // không bao giờ cho phép xoá bản mới nhất.
      }
      banner(t("backup.title"));
      say();
      say(`  ${t("backup.configLabel", { p: configFile })}`);
      say();
      return backupDoPrune(listBackups(configFile), n, yes, dryRun);
    }

    bad(t("backup.unknownAction", { a: action }));
    say("  " + t("backup.usage"));
    return 1;
  },
};
