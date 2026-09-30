// lib/uninstall.mjs — lệnh con `uninstall`: gỡ Command Code khỏi OpenCode.
// Đảo ngược đúng những gì install.mjs đã ghi: 2 provider trong opencode.json
// và key trong ~/.commandcode/auth.json. Phần còn lại của config giữ nguyên.

import { C, askYes, bad, banner, info, ok, probeEnvironment, readConfigIfAny, readJsonFile, registerMessages, say, stamp, t, warn, writeAtomic } from "./shared.mjs";
import fs from "node:fs";
import path from "node:path";

registerMessages(
  {
    "uninstall.summary": "Remove Command Code from OpenCode (undo install)",
    "uninstall.title": "COMMAND CODE  →  OPENCODE   (uninstall)",
    "uninstall.configLine": "Config: {p}",
    "uninstall.configBadJson": "{f} is not valid JSON.",
    "uninstall.configBadJsonHint": "Stopped so the file is not damaged. Fix it, then run again.",
    "uninstall.planHeader": "This will change",
    "uninstall.removeProviders": "Remove from providers: {list}",
    "uninstall.removeCli": "Remove the API key from the CLI file: {p}",
    "uninstall.keepCli": "Leave the CLI file untouched ({p}).",
    "uninstall.backupNote": "Back up the config first: {f}",
    "uninstall.cleanProviders": "Remove the empty providers object if it becomes empty.",
    "uninstall.otherKeysKept": "Other providers and all other top-level keys stay untouched.",
    "uninstall.proceed": "Proceed? (y/N) ",
    "uninstall.dryRun": "Dry run — nothing was changed.",
    "uninstall.cancelled": "Cancelled. Nothing was changed.",
    "uninstall.nothingToDo": "No Command Code providers found — nothing to uninstall.",
    "uninstall.cliStillThere": "The CLI key in {p} was left as is.",
    "uninstall.backup": "Backup: {f}",
    "uninstall.removed": "Removed: {list}.",
    "uninstall.providersEmpty": "providers is now empty — removed the empty object.",
    "uninstall.providersKept": "Kept {n} other provider(s): {list}.",
    "uninstall.cliRemoved": "Removed the API key from {p}.",
    "uninstall.cliMissing": "No API key in {p} — nothing to remove.",
    "uninstall.cliFailed": "Could not update the CLI file ({e}) — the config is still cleaned.",
    "uninstall.verifyHeader": "Verifying",
    "uninstall.verifyGone": "The Command Code providers are gone.",
    "uninstall.verifyKept": "Other top-level keys survived: {list}.",
    "uninstall.verifyNoKept": "No other top-level keys to preserve.",
    "uninstall.verifyFailed": "Verification failed: {e}",
    "uninstall.writeFailed": "Could not write the config ({e}).",
    "uninstall.done": "DONE — UNINSTALLED",
    "uninstall.configLabel": "Config : {p}",
    "uninstall.backupLabel": "Backup : {p}",
    "uninstall.noBackup": "(none, new file)",
    "uninstall.restartHint": "Reopen OpenCode to pick up the change.",
  },
  {
    "uninstall.summary": "Gỡ Command Code khỏi OpenCode (hoàn tác cài đặt)",
    "uninstall.title": "COMMAND CODE  →  OPENCODE   (gỡ cài đặt)",
    "uninstall.configLine": "Config: {p}",
    "uninstall.configBadJson": "{f} không phải JSON hợp lệ.",
    "uninstall.configBadJsonHint": "Đã dừng để không làm hỏng file. Sửa file đó rồi chạy lại.",
    "uninstall.planHeader": "Thao tác này sẽ thay đổi",
    "uninstall.removeProviders": "Xoá khỏi providers: {list}",
    "uninstall.removeCli": "Xoá API key trong file CLI: {p}",
    "uninstall.keepCli": "Giữ nguyên file CLI ({p}).",
    "uninstall.backupNote": "Sao lưu config trước: {f}",
    "uninstall.cleanProviders": "Nếu providers trở nên rỗng thì xoá luôn object providers rỗng.",
    "uninstall.otherKeysKept": "Các provider khác và mọi khoá cấp cao nhất khác giữ nguyên.",
    "uninstall.proceed": "Tiến hành? (y/N) ",
    "uninstall.dryRun": "Chạy thử — không thay đổi gì cả.",
    "uninstall.cancelled": "Đã huỷ. Không thay đổi gì cả.",
    "uninstall.nothingToDo": "Không thấy provider Command Code nào — không có gì để gỡ.",
    "uninstall.cliStillThere": "Key CLI trong {p} vẫn được giữ nguyên.",
    "uninstall.backup": "Backup: {f}",
    "uninstall.removed": "Đã xoá: {list}.",
    "uninstall.providersEmpty": "providers giờ rỗng — đã xoá object rỗng.",
    "uninstall.providersKept": "Giữ lại {n} provider khác: {list}.",
    "uninstall.cliRemoved": "Đã xoá API key trong {p}.",
    "uninstall.cliMissing": "Không có API key trong {p} — không có gì để xoá.",
    "uninstall.cliFailed": "Không cập nhật được file CLI ({e}) — config vẫn đã được dọn.",
    "uninstall.verifyHeader": "Kiểm chứng",
    "uninstall.verifyGone": "Các provider Command Code đã biến mất.",
    "uninstall.verifyKept": "Các khoá cấp cao nhất khác vẫn còn: {list}.",
    "uninstall.verifyNoKept": "Không có khoá cấp cao nhất nào khác để giữ.",
    "uninstall.verifyFailed": "Kiểm chứng thất bại: {e}",
    "uninstall.writeFailed": "Không ghi được config ({e}).",
    "uninstall.done": "XONG — ĐÃ GỠ",
    "uninstall.configLabel": "Config : {p}",
    "uninstall.backupLabel": "Backup : {p}",
    "uninstall.noBackup": "(chưa có, file mới)",
    "uninstall.restartHint": "Mở lại OpenCode để áp dụng thay đổi.",
  }
);

// Hai provider mà install tạo ra. Chỉ đụng đúng hai cái này.
const uninstallProviderIds = ["cmd", "cmd-claude"];

/** In kế hoạch thay đổi ra màn hình. Không sửa gì cả. */
function uninstallPrintPlan(env, keepCli) {
  const providers = env.existing?.providers && typeof env.existing.providers === "object"
    ? env.existing.providers
    : {};
  const present = uninstallProviderIds.filter((id) => Object.hasOwn(providers, id));

  say();
  say(`${C.cyan}${t("uninstall.planHeader")}${C.reset}`);
  info(t("uninstall.removeProviders", { list: present.map((id) => `providers.${id}`).join(", ") }));
  if (keepCli) info(t("uninstall.keepCli", { p: env.cliAuthFile }));
  else info(t("uninstall.removeCli", { p: env.cliAuthFile }));
  info(t("uninstall.backupNote", { f: `${path.basename(env.configFile)}.bak-<timestamp>` }));
  info(t("uninstall.cleanProviders"));
  info(t("uninstall.otherKeysKept"));
}

export const uninstallCmd = {
  name: "uninstall",
  summary: () => t("uninstall.summary"),

  async run(argv = []) {
    const dryRun = argv.includes("--dry-run");
    const keepCli = argv.includes("--keep-cli");

    banner(t("uninstall.title"));
    const env = probeEnvironment();
    say(`${C.dim}      ${t("uninstall.configLine", { p: env.configFile })}${C.reset}`);

    // Config hỏng: dừng tay, không đụng gì.
    if (env.existing === null) {
      say();
      bad(t("uninstall.configBadJson", { f: env.configFile }));
      warn(t("uninstall.configBadJsonHint"));
      return 1;
    }

    // Chưa cài thì gỡ cũng không phải lỗi.
    const current = env.existing.providers && typeof env.existing.providers === "object"
      ? env.existing.providers
      : {};
    if (!uninstallProviderIds.some((id) => Object.hasOwn(current, id))) {
      say();
      ok(t("uninstall.nothingToDo"));
      if (!keepCli && fs.existsSync(env.cliAuthFile)) info(t("uninstall.cliStillThere", { p: env.cliAuthFile }));
      return 0;
    }

    // Mặc định: cho xem đúng những gì sắp đổi, rồi mới hỏi.
    uninstallPrintPlan(env, keepCli);

    if (dryRun) {
      say();
      say(`${C.yellow}${t("uninstall.dryRun")}${C.reset}`);
      return 0;
    }

    if (!(await askYes("      " + t("uninstall.proceed"), false))) {
      say();
      warn(t("uninstall.cancelled"));
      return 0;
    }

    // ---------- Sao lưu config (để chính thao tác gỡ cũng đảo ngược được) ----------
    const st = stamp();
    const backupFile = `${env.configFile}.bak-${st}`;
    say();
    try {
      if (fs.existsSync(env.configFile)) {
        fs.copyFileSync(env.configFile, backupFile);
        ok(t("uninstall.backup", { f: path.basename(backupFile) }));
      }
    } catch (e) {
      bad(t("uninstall.writeFailed", { e: e.message }));
      return 1;
    }

    // Đọc lại ngay trước khi sửa để chắc chắn không ghi đè bản cũ.
    const fresh = readConfigIfAny(env.configFile);
    if (fresh === null) {
      bad(t("uninstall.configBadJson", { f: env.configFile }));
      return 1;
    }

    const before = structuredClone(fresh);
    const beforeProviders = Object.keys(before.providers || {});
    const beforeTop = Object.keys(before).filter((k) => k !== "providers");

    const next = structuredClone(fresh);
    const presentIds = uninstallProviderIds.filter((id) => Object.hasOwn(next.providers || {}, id));
    for (const id of presentIds) delete next.providers[id];
    const providersEmpty = Object.keys(next.providers || {}).length === 0;
    if (providersEmpty) delete next.providers;

    try {
      writeAtomic(env.configFile, JSON.stringify(next, null, 2) + "\n");
    } catch (e) {
      bad(t("uninstall.writeFailed", { e: e.message }));
      return 1;
    }

    ok(t("uninstall.removed", { list: presentIds.map((id) => `providers.${id}`).join(", ") }));
    if (providersEmpty) ok(t("uninstall.providersEmpty"));
    const keptProviders = Object.keys(next.providers || {});
    if (keptProviders.length) {
      ok(t("uninstall.providersKept", { n: keptProviders.length, list: keptProviders.join(", ") }));
    }

    // ---------- Key trong auth.json của CLI ----------
    // Mặc định xoá; --keep-cli thì để yên (xoá sẽ làm hỏng luôn CLI Command Code).
    if (keepCli) {
      info(t("uninstall.keepCli", { p: env.cliAuthFile }));
    } else {
      try {
        if (fs.existsSync(env.cliAuthFile)) {
          const auth = readJsonFile(env.cliAuthFile);
          if (Object.hasOwn(auth, "apiKey")) {
            fs.copyFileSync(env.cliAuthFile, `${env.cliAuthFile}.bak-${st}`);
            delete auth.apiKey;
            writeAtomic(env.cliAuthFile, JSON.stringify(auth, null, 2) + "\n");
            ok(t("uninstall.cliRemoved", { p: env.cliAuthFile }));
          } else {
            info(t("uninstall.cliMissing", { p: env.cliAuthFile }));
          }
        } else {
          info(t("uninstall.cliMissing", { p: env.cliAuthFile }));
        }
      } catch (e) {
        warn(t("uninstall.cliFailed", { e: e.message }));
      }
    }

    // ---------- Kiểm chứng ----------
    say();
    say(`${C.cyan}${t("uninstall.verifyHeader")}${C.reset}`);

    let after;
    try {
      after = readJsonFile(env.configFile);
    } catch (e) {
      bad(t("uninstall.verifyFailed", { e: e.message }));
      return 1;
    }

    const stillThere = uninstallProviderIds.filter((id) => Object.hasOwn(after.providers || {}, id));
    const goneOk = stillThere.length === 0;
    goneOk
      ? ok(t("uninstall.verifyGone"))
      : bad(t("uninstall.verifyFailed", { e: stillThere.map((id) => `providers.${id}`).join(", ") }));

    const survived = beforeTop.filter(
      (k) => Object.hasOwn(after, k) && JSON.stringify(after[k]) === JSON.stringify(before[k])
    );
    const survivorsOk = survived.length === beforeTop.length;
    if (beforeTop.length === 0) {
      info(t("uninstall.verifyNoKept"));
    } else if (survivorsOk) {
      ok(t("uninstall.verifyKept", { list: survived.join(", ") }));
    } else {
      const lost = beforeTop.filter((k) => !survived.includes(k));
      bad(t("uninstall.verifyFailed", { e: lost.join(", ") }));
    }

    const otherProviders = beforeProviders.filter((id) => !presentIds.includes(id));
    const providersOk = otherProviders.every((id) => Object.hasOwn(after.providers || {}, id));
    if (otherProviders.length && !providersOk) {
      const lost = otherProviders.filter((id) => !Object.hasOwn(after.providers || {}, id));
      bad(t("uninstall.verifyFailed", { e: lost.map((id) => `providers.${id}`).join(", ") }));
    }

    if (!goneOk || !survivorsOk || !providersOk) return 1;

    say();
    say(`${C.green}${C.bold}==================================================${C.reset}`);
    say(`${C.green}${C.bold}   ${t("uninstall.done")}${C.reset}`);
    say(`${C.green}${C.bold}==================================================${C.reset}`);
    say("  " + t("uninstall.configLabel", { p: env.configFile }));
    say("  " + t("uninstall.backupLabel", { p: fs.existsSync(backupFile) ? backupFile : t("uninstall.noBackup") }));
    say();
    say(`  ${C.yellow}${t("uninstall.restartHint")}${C.reset}`);
    say();
    return 0;
  },
};
