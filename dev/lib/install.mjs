// lib/install.mjs — lệnh con `install` (mặc định): nối Command Code vào OpenCode.
// Đây là luồng cũ, chỉ đổi chỗ ở và tự đăng ký chuỗi của mình.

import {
  CMD_CMDC, CMD_OPENCODE, E2E_PREFERRED, KEY_PAGE,
  PKG_ANTHROPIC, PKG_OPENAI,
  C, askHidden, askYes, assessConnection, bad, banner, buildProviderBlock,
  fetchModels, findTool, fingerprint, isProviderPresent, isTTY, mergeProviders,
  ok, probeEnvironment, readConfigIfAny, readJsonFile, registerMessages, say,
  splitModels, stamp, step, t, tryRun, warn, writeAtomic,
} from "./shared.mjs";

import path from "node:path";
import fs from "node:fs";

registerMessages(
  {
    "install.summary": "Wire Command Code into OpenCode (default)",
    "install.title": "COMMAND CODE  →  OPENCODE",
    "install.step1": "Detecting environment",
    "install.step2": "Checking whether OpenCode is wired to Command Code",
    "install.step3": "Deciding what to do",
    "install.step4": "Checking installations",
    "install.step5": "Entering API key",
    "install.step6": "Configuring",
    "install.nodePresent": "Node {v} is available.",
    "install.opencodePresent": "OpenCode {v}",
    "install.opencodeMissing": "OpenCode is not installed.",
    "install.cmdcPresent": "Command Code {v} (command: {n})",
    "install.cmdcMissing": "Command Code CLI is not installed.",
    "install.configBadJson": "{f} is not valid JSON.",
    "install.configBadJsonHint": "Stopped so the file is not damaged. Fix it, then run again.",
    "install.providerPresent": "config has providers.cmd ({n} models).",
    "install.providerAbsent": "config has no providers.cmd yet.",
    "install.statusLabel": "Status: {s}",
    "install.statusReady": "connected and ready",
    "install.statusNotConfigured": "not configured",
    "install.statusKeyInvalid": "configured, but the key is invalid",
    "install.statusUnverified": "configured, could not verify (offline)",
    "install.alreadyConnected": "OpenCode and Command Code are already wired together — nothing to reconfigure.",
    "install.askRotate": "Change the API key? (y/N) ",
    "install.nothingToDo": "Nothing to do. You are already set up.",
    "install.needKeyInvalid": "The stored key does not work — enter a new one.",
    "install.needKeyUnverified": "The key will be checked again when there is a network.",
    "install.needConfig": "OpenCode needs the provider configured.",
    "install.notInstalled": "{what} is not installed.",
    "install.willRun": "Command to run:  {cmd}",
    "install.installNow": "Install now? (Y/n) ",
    "install.installing": "Running (this can take a few minutes)...",
    "install.skipInstall": "Skipping {what}.",
    "install.opencodeMissingFatal": "OpenCode is missing, cannot continue.",
    "install.installedButNotFound": "Installed, but `opencode` still not found on PATH.",
    "install.alreadyInstalled": "{what} is already installed — skipping.",
    "install.cmdcInstalledNotInPath": "Installed, but not yet on PATH (you may need to reopen the terminal).",
    "install.skipCli": "Skipping the CLI — OpenCode still works.",
    "install.keyPage": "Get one at: {url}",
    "install.keyPrompt": "Paste the key and press Enter: ",
    "install.keyGot": "Key received: {fp}",
    "install.confirmKey": "Correct? (Y/n) ",
    "install.keyBlank": "Nothing entered.",
    "install.checking": "Checking the key with Command Code...",
    "install.keyValid": "Key is valid — {n} models.",
    "install.keyInvalid": "Key is NOT valid, or the server is unreachable ({e}).",
    "install.nothingWritten": "Stopped. Nothing was written — your current setup is untouched.",
    "install.cancelled": "Cancelled.",
    "install.retry": "Try again.",
    "install.keepKey": "Keeping the existing key.",
    "install.configLine": "Config: {p} ({src})",
    "install.cliWritten": "CLI: key written.",
    "install.cliFailed": "Could not write the CLI part ({e}) — OpenCode continues anyway.",
    "install.backup": "Backup: {f}",
    "install.providerCreated": "providers.cmd created → {n} models.",
    "install.providerKeyOnly": "providers.cmd already existed → key updated only, model list untouched.",
    "install.claudeCreated": "providers.cmd-claude → {n} models.",
    "install.verifyHeader": "Verifying",
    "install.keyMatch": "Key matches in both providers.",
    "install.keyMismatch": "The written key does not match!",
    "install.modelsCount": "providers.cmd: {n} models.",
    "install.preserved": "Preserved: {list}.",
    "install.e2eRunning": "Running a real request through OpenCode...",
    "install.e2eOk": "Live request succeeded ({m}).",
    "install.e2eWarn": "Could not verify end-to-end (you may need to reopen OpenCode). {e}",
    "install.done": "DONE — WIRED UP",
    "install.configLabel": "Config : {p}",
    "install.backupLabel": "Backup : {p}",
    "install.noBackup": "(none, new file)",
    "install.restartHint": "Reopen OpenCode, then type /models to pick a cmd/... model.",
  },
  {
    "install.summary": "Nối Command Code vào OpenCode (mặc định)",
    "install.title": "COMMAND CODE  →  OPENCODE",
    "install.step1": "Dò môi trường",
    "install.step2": "Kiểm tra OpenCode đã nối với Command Code chưa",
    "install.step3": "Xác định việc cần làm",
    "install.step4": "Kiểm tra cài đặt",
    "install.step5": "Nhập API key",
    "install.step6": "Cấu hình",
    "install.nodePresent": "Node {v} đã có.",
    "install.opencodePresent": "OpenCode {v}",
    "install.opencodeMissing": "Chưa cài OpenCode.",
    "install.cmdcPresent": "Command Code {v} (lệnh: {n})",
    "install.cmdcMissing": "Chưa cài Command Code CLI.",
    "install.configBadJson": "{f} không phải JSON hợp lệ.",
    "install.configBadJsonHint": "Đã dừng để không làm hỏng file. Sửa file đó rồi chạy lại.",
    "install.providerPresent": "config có providers.cmd ({n} model).",
    "install.providerAbsent": "config chưa có providers.cmd.",
    "install.statusLabel": "Trạng thái: {s}",
    "install.statusReady": "đã nối sẵn sàng",
    "install.statusNotConfigured": "chưa cấu hình",
    "install.statusKeyInvalid": "có cấu hình nhưng key không hợp lệ",
    "install.statusUnverified": "có cấu hình, chưa kiểm tra được (offline)",
    "install.alreadyConnected": "OpenCode và Command Code đã nối với nhau — không cần cấu hình lại.",
    "install.askRotate": "Bạn có muốn ĐỔI key không? (y/N) ",
    "install.nothingToDo": "Không có gì phải làm. Bạn đã dùng được rồi.",
    "install.needKeyInvalid": "Key đang lưu không dùng được — cần nhập key mới.",
    "install.needKeyUnverified": "Sẽ kiểm tra lại key khi có mạng.",
    "install.needConfig": "Cần cấu hình provider cho OpenCode.",
    "install.notInstalled": "Chưa cài {what}.",
    "install.willRun": "Lệnh sẽ chạy:  {cmd}",
    "install.installNow": "Cài bây giờ? (Y/n) ",
    "install.installing": "Đang chạy (có thể mất vài phút)...",
    "install.skipInstall": "Bỏ qua cài {what}.",
    "install.opencodeMissingFatal": "Thiếu OpenCode, không thể tiếp tục.",
    "install.installedButNotFound": "Cài xong nhưng không tìm thấy `opencode` trong PATH.",
    "install.alreadyInstalled": "{what} đã có — bỏ qua cài đặt.",
    "install.cmdcInstalledNotInPath": "Cài xong nhưng chưa thấy trong PATH (có thể cần mở lại terminal).",
    "install.skipCli": "Bỏ qua CLI — OpenCode vẫn dùng được.",
    "install.keyPage": "Lấy tại: {url}",
    "install.keyPrompt": "Dán key rồi nhấn Enter: ",
    "install.keyGot": "Key nhận được: {fp}",
    "install.confirmKey": "Đúng chưa? (Y/n) ",
    "install.keyBlank": "Chưa nhập gì.",
    "install.checking": "Đang kiểm tra key với máy chủ Command Code...",
    "install.keyValid": "Key hợp lệ — {n} model.",
    "install.keyInvalid": "Key KHÔNG hợp lệ hoặc không kết nối được ({e}).",
    "install.nothingWritten": "Đã dừng. KHÔNG ghi gì cả — setup hiện tại vẫn nguyên vẹn.",
    "install.cancelled": "Đã huỷ.",
    "install.retry": "Nhập lại.",
    "install.keepKey": "Giữ nguyên key đang có.",
    "install.configLine": "Config: {p} ({src})",
    "install.cliWritten": "CLI: đã ghi key.",
    "install.cliFailed": "Không ghi được phần CLI ({e}) — OpenCode vẫn tiếp tục.",
    "install.backup": "Backup: {f}",
    "install.providerCreated": "providers.cmd đã tạo → {n} model.",
    "install.providerKeyOnly": "providers.cmd đã có → chỉ đổi key, giữ nguyên danh sách model.",
    "install.claudeCreated": "providers.cmd-claude → {n} model.",
    "install.verifyHeader": "Kiểm chứng",
    "install.keyMatch": "Key khớp ở cả 2 provider.",
    "install.keyMismatch": "Key ghi vào chưa khớp!",
    "install.modelsCount": "providers.cmd: {n} model.",
    "install.preserved": "Giữ nguyên: {list}.",
    "install.e2eRunning": "Đang thử thật một request qua OpenCode...",
    "install.e2eOk": "Thử thật thành công ({m}).",
    "install.e2eWarn": "Chưa thử được end-to-end (có thể cần mở lại OpenCode). {e}",
    "install.done": "XONG — ĐÃ NỐI XONG",
    "install.configLabel": "Config : {p}",
    "install.backupLabel": "Backup : {p}",
    "install.noBackup": "(chưa có, file mới)",
    "install.restartHint": "Mở lại OpenCode, rồi gõ /models để chọn model cmd/...",
  }
);

async function installWithConfirm(what, cmd) {
  say();
  warn(t("install.notInstalled", { what }));
  say(`      ${t("install.willRun", { cmd: "" })}${C.cyan}${cmd}${C.reset}`);
  if (!(await askYes("      " + t("install.installNow"), true))) {
    warn(t("install.skipInstall", { what }));
    return false;
  }
  say("      " + t("install.installing"));
  const r = tryRun(cmd, { stdio: "inherit" });
  return r.ok;
}

export const installCmd = {
  name: "install",
  summary: () => t("install.summary"),

  async run() {
    banner(t("install.title"));

    // ---------- 1. Dò môi trường ----------
    say();
    step("1/6", t("install.step1"));

    ok(t("install.nodePresent", { v: process.version }));

    let env = probeEnvironment();
    let opencode = env.opencode;
    let cmdc = env.cmdc;

    opencode ? ok(t("install.opencodePresent", { v: opencode.version })) : warn(t("install.opencodeMissing"));
    cmdc
      ? ok(t("install.cmdcPresent", { v: cmdc.version, n: cmdc.name }))
      : warn(t("install.cmdcMissing"));

    if (env.existing === null) {
      say();
      bad(t("install.configBadJson", { f: env.configFile }));
      warn(t("install.configBadJsonHint"));
      return 1;
    }

    // ---------- 2. Đánh giá kết nối ----------
    say();
    step("2/6", t("install.step2"));

    const storedKey = env.existing?.providers?.cmd?.settings?.apiKey;
    let keyValid = null;
    if (storedKey) {
      try { await fetchModels(storedKey); keyValid = true; }
      catch { keyValid = false; }
    }

    const status = assessConnection(env.existing, keyValid);
    const STATUS_TEXT = {
      ready: t("install.statusReady"),
      "not-configured": t("install.statusNotConfigured"),
      "key-invalid": t("install.statusKeyInvalid"),
      "configured-unverified": t("install.statusUnverified"),
    };

    if (env.existing?.providers?.cmd)
      ok(t("install.providerPresent", { n: Object.keys(env.existing.providers.cmd.models || {}).length }));
    else warn(t("install.providerAbsent"));
    say(`      ${t("install.statusLabel", { s: `${C.bold}${STATUS_TEXT[status]}${C.reset}` })}`);

    // ---------- 3. Quyết định ----------
    say();
    step("3/6", t("install.step3"));

    let key = null;
    let needConfig = false;

    if (status === "ready") {
      ok(t("install.alreadyConnected"));
      if (await askYes("      " + t("install.askRotate"), false)) {
        needConfig = true;
      } else {
        say();
        say(`${C.green}${C.bold}${t("install.nothingToDo")}${C.reset}`);
        return 0;
      }
    } else {
      needConfig = true;
      if (status === "key-invalid") warn(t("install.needKeyInvalid"));
      if (status === "configured-unverified") say("      " + t("install.needKeyUnverified"));
      if (status === "not-configured") say("      " + t("install.needConfig"));
    }

    // ---------- 4. Cài nếu thiếu ----------
    say();
    step("4/6", t("install.step4"));

    if (!opencode) {
      if (!(await installWithConfirm("OpenCode", CMD_OPENCODE))) {
        bad(t("install.opencodeMissingFatal"));
        return 1;
      }
      opencode = findTool(["opencode"]);
      if (!opencode) { bad(t("install.installedButNotFound")); return 1; }
      ok(t("install.opencodePresent", { v: opencode.version }));
      env = probeEnvironment();
    } else ok(t("install.alreadyInstalled", { what: "OpenCode" }));

    if (!cmdc) {
      if (await installWithConfirm("Command Code CLI", CMD_CMDC)) {
        cmdc = findTool(["cmdc", "command-code", "cmd"]);
        cmdc
          ? ok(t("install.cmdcPresent", { v: cmdc.version, n: cmdc.name }))
          : warn(t("install.cmdcInstalledNotInPath"));
      } else warn(t("install.skipCli"));
    } else ok(t("install.alreadyInstalled", { what: "Command Code" }));

    // ---------- 5. Nhập key ----------
    if (needConfig) {
      say();
      step("5/6", t("install.step5"));
      say(`${C.dim}      ${t("install.keyPage", { url: KEY_PAGE })}${C.reset}`);
      for (;;) {
        key = (await askHidden("      " + t("install.keyPrompt"))).trim();
        if (!key) { bad(t("install.keyBlank")); return 1; }
        say(`      ${t("install.keyGot", { fp: `${C.yellow}${fingerprint(key)}${C.reset}` })}`);
        if (await askYes("      " + t("install.confirmKey"), true)) break;
        if (!isTTY()) { bad(t("install.cancelled")); return 0; }
        warn(t("install.retry"));
      }

      say();
      say("      " + t("install.checking"));
      try {
        const n = (await fetchModels(key)).length;
        ok(t("install.keyValid", { n }));
        keyValid = true;
      } catch (e) {
        bad(t("install.keyInvalid", { e: e.message }));
        warn(t("install.nothingWritten"));
        return 1;
      }
    } else {
      say();
      step("5/6", t("install.step5"));
      ok(t("install.keepKey"));
      key = storedKey;
    }

    // ---------- 6. Ghi cấu hình ----------
    say();
    step("6/6", t("install.step6"));
    const st = stamp();
    const configFile = env.configFile;
    const cliAuthFile = env.cliAuthFile;
    say(`${C.dim}      ${t("install.configLine", { p: configFile, src: env.configSrc })}${C.reset}`);

    try {
      fs.mkdirSync(path.dirname(cliAuthFile), { recursive: true });
      if (fs.existsSync(cliAuthFile)) fs.copyFileSync(cliAuthFile, `${cliAuthFile}.bak-${st}`);
      const a = fs.existsSync(cliAuthFile) ? readJsonFile(cliAuthFile) : {};
      a.apiKey = key;
      writeAtomic(cliAuthFile, JSON.stringify(a, null, 2));
      ok(t("install.cliWritten"));
    } catch (e) {
      warn(t("install.cliFailed", { e: e.message }));
    }

    fs.mkdirSync(env.configDir, { recursive: true });
    if (fs.existsSync(configFile)) {
      fs.copyFileSync(configFile, `${configFile}.bak-${st}`);
      ok(t("install.backup", { f: path.basename(configFile) + `.bak-${st}` }));
    }

    const models = await fetchModels(key);
    const { openaiCapable, anthropicOnly } = splitModels(models);
    const cfg = readConfigIfAny(configFile) || {};
    const hadCmd = isProviderPresent(cfg, "cmd");

    const openaiBlock = hadCmd
      ? { ...cfg.providers.cmd, settings: { ...cfg.providers.cmd.settings, apiKey: key } }
      : buildProviderBlock({ models: openaiCapable, apiKey: key, packageName: PKG_OPENAI, displayName: "Command Code" });

    const claudeBlock = buildProviderBlock({
      models: anthropicOnly, apiKey: key, packageName: PKG_ANTHROPIC, displayName: "Command Code (Claude)",
    });

    const merged = mergeProviders(cfg, { cmd: openaiBlock, "cmd-claude": claudeBlock });
    if (!merged.$schema) merged.$schema = "https://opencode.ai/config.json";
    writeAtomic(configFile, JSON.stringify(merged, null, 2) + "\n");

    hadCmd ? ok(t("install.providerKeyOnly")) : ok(t("install.providerCreated", { n: openaiCapable.length }));
    ok(t("install.claudeCreated", { n: anthropicOnly.length }));

    // ---------- Kiểm chứng ----------
    say();
    say(`${C.cyan}${t("install.verifyHeader")}${C.reset}`);
    const after = readJsonFile(configFile);
    const bothKeysOk = after.providers?.cmd?.settings?.apiKey === key
      && after.providers?.["cmd-claude"]?.settings?.apiKey === key;
    bothKeysOk ? ok(t("install.keyMatch")) : bad(t("install.keyMismatch"));
    ok(t("install.modelsCount", { n: Object.keys(after.providers?.cmd?.models || {}).length }));
    const kept = ["plugins", "mcp", "agents"].filter((k) => after[k]);
    if (kept.length) ok(t("install.preserved", { list: kept.join(", ") }));

    const e2eModel = after.providers?.cmd?.models?.[E2E_PREFERRED]
      ? E2E_PREFERRED
      : Object.keys(after.providers?.cmd?.models || {})[0];
    if (e2eModel && opencode) {
      say("      " + t("install.e2eRunning"));
      const r = tryRun(`opencode run --model cmd/${e2eModel} "Reply with exactly: PONG"`);
      if (r.ok && /PONG/i.test(r.out)) ok(t("install.e2eOk", { m: `cmd/${e2eModel}` }));
      else warn(t("install.e2eWarn", { e: r.out.split(/\r?\n/).slice(-1)[0] || "" }));
    }

    say();
    say(`${C.green}${C.bold}==================================================${C.reset}`);
    say(`${C.green}${C.bold}   ${t("install.done")}${C.reset}`);
    say(`${C.green}${C.bold}==================================================${C.reset}`);
    say("  " + t("install.configLabel", { p: configFile }));
    const bk = `${configFile}.bak-${st}`;
    say("  " + t("install.backupLabel", { p: fs.existsSync(bk) ? bk : t("install.noBackup") }));
    say();
    say(`  ${C.yellow}${t("install.restartHint")}${C.reset}`);
    say();
    return 0;
  },
};
