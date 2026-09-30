: << 'BATCH_EOF'
@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
set "SELF=%~f0"
set "PAYLOAD=%TEMP%\cmdcode-%RANDOM%-%RANDOM%.mjs"

rem ---- Chon ngon ngu / Choose language (luon o dau tien) ----
echo.
echo   ==================================================
echo    Chon ngon ngu  /  Choose language
echo   ==================================================
echo.
echo      [1] English
echo      [2] Tieng Viet (Vietnamese)
echo.
set "CMD_LANG=1"
set /p "CMD_LANG=  Chon / Choose: "
rem So sanh bang ky tu dau: neu input bi pipe qua PowerShell thi gia tri co the
rem dinh kem , so ca chuoi se truot.
if "!CMD_LANG:~0,1!"=="2" (set "CMDCODE_LANG=vi") else (set "CMDCODE_LANG=en")
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo   Node.js is not installed. / Node.js chua duoc cai tren may nay.
  echo.
  where winget >nul 2>nul
  if errorlevel 1 (
    echo   winget not found. / Khong tim thay winget.
echo.
echo   ==================================================
echo    CANNOT INSTALL NODE AUTOMATICALLY
echo    KHONG CAI DUOC NODE TU DONG
echo   ==================================================
echo.
echo    Install Node manually / Hay cai Node THU CONG:
echo.
echo      1. https://nodejs.org/en/download
echo      2. LTS build for your OS / ban LTS cho he dieu hanh cua ban
echo      3. Install it / Cai dat xong
echo      4. Run this file again / Chay lai file nay
echo.
echo    Node is all you need - no extra config.
echo    Co Node la chay duoc, khong can cau hinh gi them.
echo.
    start "" "https://nodejs.org/en/download"
    pause
    exit /b 1
  )
  set "ANS="
  set /p "ANS=  Install Node.js LTS with winget? / Cai bang winget? (Y/n) "
  if /i "!ANS!"=="n" (
    echo   Cancelled. / Da huy.
    pause
    exit /b 1
  )
  if /i "!ANS!"=="no" (
    echo   Cancelled. / Da huy.
    pause
    exit /b 1
  )
  echo.
  echo   Installing Node.js LTS... / Dang cai, co the mat vai phut...
  winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  if errorlevel 1 (
    echo.
    echo   winget reported an error. / winget bao loi khi cai Node.
    echo.
  )
  rem Node vua cai co the chua kip vao PATH cua tien trinh nay
  set "PATH=%ProgramFiles%\nodejs;%PATH%"
)

where node >nul 2>nul
if errorlevel 1 (
echo.
echo   ==================================================
echo    CANNOT INSTALL NODE AUTOMATICALLY
echo    KHONG CAI DUOC NODE TU DONG
echo   ==================================================
echo.
echo    Install Node manually / Hay cai Node THU CONG:
echo.
echo      1. https://nodejs.org/en/download
echo      2. LTS build for your OS / ban LTS cho he dieu hanh cua ban
echo      3. Install it / Cai dat xong
echo      4. Run this file again / Chay lai file nay
echo.
echo    Node is all you need - no extra config.
echo    Co Node la chay duoc, khong can cau hinh gi them.
echo.
  pause
  exit /b 1
)

rem Tach phan JavaScript o cuoi file ra file tam (dung PowerShell cho chac)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#__PAYLOAD__'; $t=[IO.File]::ReadAllText('%SELF%'); $i=$t.LastIndexOf($m); if($i -lt 0){ exit 1 }; [IO.File]::WriteAllText('%PAYLOAD%', $t.Substring($i + $m.Length).TrimStart(), (New-Object Text.UTF8Encoding $false))"
if errorlevel 1 (
  echo.
  echo   Cannot extract the JavaScript payload. / Khong tach duoc phan JavaScript.
  echo.
  pause
  exit /b 1
)

node "%PAYLOAD%"
set "RC=%errorlevel%"
del "%PAYLOAD%" >nul 2>nul
echo.
pause
exit /b %RC%
BATCH_EOF
SELF="$0"
PAYLOAD="${TMPDIR:-/tmp}/cmdcode-$$.mjs"

# ---- Chon ngon ngu / Choose language (luon o dau tien) ----
echo
echo "  =================================================="
echo "   Chọn ngôn ngữ  /  Choose language"
echo "  =================================================="
echo
echo "     [1] English"
echo "     [2] Tiếng Việt"
echo
printf "  Chọn / Choose (1/2): "
read -r CHOICE
# Bo  phong khi input bi pipe tu moi truong ghi CRLF
CHOICE=$(printf '%s' "$CHOICE" | tr -d '')
case "${CHOICE:-1}" in
  2) CMDCODE_LANG=vi ;;
  *) CMDCODE_LANG=en ;;
esac
export CMDCODE_LANG
echo

install_node() {
  if command -v brew >/dev/null 2>&1; then
    printf "  Install Node.js with Homebrew? / Cài bằng Homebrew? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    brew install node || return 1
  elif command -v apt-get >/dev/null 2>&1; then
    printf "  Install Node.js with apt (needs sudo)? / Cài bằng apt (cần sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo apt-get update && sudo apt-get install -y nodejs npm || return 1
  elif command -v dnf >/dev/null 2>&1; then
    printf "  Install Node.js with dnf (needs sudo)? / Cài bằng dnf (cần sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo dnf install -y nodejs || return 1
  elif command -v pacman >/dev/null 2>&1; then
    printf "  Install Node.js with pacman (needs sudo)? / Cài bằng pacman (cần sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo pacman -S --noconfirm nodejs npm || return 1
  else
    echo "  No known package manager. / Không tìm thấy trình quản lý gói quen thuộc."
    echo
    echo "  Install Node manually / Hãy cài Node thủ công: https://nodejs.org/en/download"
    return 1
  fi
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  echo
  echo "  Node.js is not installed. / Node.js chưa được cài trên máy này."
  echo

  if ! install_node; then
echo
echo "  =================================================="
echo "   CANNOT INSTALL NODE AUTOMATICALLY"
echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"
echo "  =================================================="
echo
echo "   Install Node manually / Hãy cài Node THỦ CÔNG:"
echo
echo "     1. https://nodejs.org/en/download"
echo "     2. LTS build for your OS / bản LTS cho hệ điều hành của bạn"
echo "     3. Install it / Cài đặt xong"
echo "     4. Run this file again / Chạy lại file này"
echo
echo "   Node is all you need - no extra config."
echo "   Có Node là chạy được, không cần cấu hình gì thêm."
echo
    exit 1
  fi

  # Cai xong nhung chua chac da co trong PATH cua phien hien tai
  if ! command -v node >/dev/null 2>&1; then
echo
echo "  =================================================="
echo "   CANNOT INSTALL NODE AUTOMATICALLY"
echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"
echo "  =================================================="
echo
echo "   Install Node manually / Hãy cài Node THỦ CÔNG:"
echo
echo "     1. https://nodejs.org/en/download"
echo "     2. LTS build for your OS / bản LTS cho hệ điều hành của bạn"
echo "     3. Install it / Cài đặt xong"
echo "     4. Run this file again / Chạy lại file này"
echo
echo "   Node is all you need - no extra config."
echo "   Có Node là chạy được, không cần cấu hình gì thêm."
echo
    exit 1
  fi
  echo "  Node installed: $(node --version) / Node đã cài xong"
fi

LINE="$(grep -n '^#__PAYLOAD__$' "$SELF" | tail -n 1 | cut -d: -f1)"
if [ -z "$LINE" ]; then
  echo
  echo "  Cannot extract the JavaScript payload. / Không tách được phần JavaScript."
  exit 1
fi
awk -v m="#__PAYLOAD__" 'found{print} $0==m{found=1}' "$SELF" > "$PAYLOAD"

node "$PAYLOAD"
rc=$?
rm -f "$PAYLOAD"
exit "$rc"

#__PAYLOAD__
// setup-commandcode.mjs — não của bộ cài: nối OpenCode với Command Code.
//
// KHÔNG thêm shebang vào file này: nó được nhúng làm payload trong file
// polyglot, và ở đó shebang sẽ rơi xuống dòng 2 (Node chỉ chấp nhận ở dòng 1).
//
// Song ngữ Anh/Việt. Ngôn ngữ chọn ở đầu bootstrap và truyền vào qua
// biến môi trường CMDCODE_LANG. Chạy trực tiếp thì tự hỏi.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execSync } from "node:child_process";
import { pathToFileURL } from "node:url";

const API_BASE = "https://api.commandcode.ai/provider/v1";
const PKG_OPENAI = "@opencode/ai/providers/openai-compatible";
const PKG_ANTHROPIC = "@opencode/ai/providers/anthropic";
const CMD_OPENCODE = "npm i -g @opencode/cli";
const CMD_CMDC = "npm i -g command-code";
const DEFAULT_CONTEXT = 200000;
const DEFAULT_OUTPUT = 32000;
const KEY_PAGE = "https://commandcode.ai/settings/keys";
const E2E_PREFERRED = "deepseek/deepseek-v4-flash";

// ============================================================
// Song ngữ
// ============================================================

const M = {
  en: {
    langTitle: "Choose language",
    langAsk: "Choose (1/2): ",

    title: "COMMAND CODE  →  OPENCODE",
    step1: "Detecting environment",
    step2: "Checking whether OpenCode is wired to Command Code",
    step3: "Deciding what to do",
    step4: "Checking installations",
    step5: "Entering API key",
    step6: "Configuring",

    nodePresent: "Node {v} is available.",
    opencodePresent: "OpenCode {v}",
    opencodeMissing: "OpenCode is not installed.",
    cmdcPresent: "Command Code {v} (command: {n})",
    cmdcMissing: "Command Code CLI is not installed.",
    configDeclared: "OpenCode reports its config at: {p}",
    configGuessed: "Guessed by convention: {p}",
    configBadJson: "{f} is not valid JSON.",
    configBadJsonHint: "Stopped so the file is not damaged. Fix it, then run again.",

    providerPresent: "config has providers.cmd ({n} models).",
    providerAbsent: "config has no providers.cmd yet.",
    statusLabel: "Status: {s}",
    statusReady: "connected and ready",
    statusNotConfigured: "not configured",
    statusKeyInvalid: "configured, but the key is invalid",
    statusUnverified: "configured, could not verify (offline)",

    alreadyConnected: "OpenCode and Command Code are already wired together — nothing to reconfigure.",
    askRotate: "Change the API key? (y/N) ",
    nothingToDo: "Nothing to do. You are already set up.",
    needKeyInvalid: "The stored key does not work — enter a new one.",
    needKeyUnverified: "The key will be checked again when there is a network.",
    needConfig: "OpenCode needs the provider configured.",

    notInstalled: "{what} is not installed.",
    willRun: "Command to run:  {cmd}",
    installNow: "Install now? (Y/n) ",
    installing: "Running (this can take a few minutes)...",
    skipInstall: "Skipping {what}.",
    opencodeMissingFatal: "OpenCode is missing, cannot continue.",
    installedButNotFound: "Installed, but `opencode` still not found on PATH.",
    alreadyInstalled: "{what} is already installed — skipping.",
    cmdcInstalledNotInPath: "Installed, but not yet on PATH (you may need to reopen the terminal).",
    skipCli: "Skipping the CLI — OpenCode still works.",

    keyPage: "Get one at: {url}",
    keyPrompt: "Paste the key and press Enter: ",
    keyGot: "Key received: {fp}",
    confirmKey: "Correct? (Y/n) ",
    keyBlank: "Nothing entered.",
    invalidFp: "<invalid>",
    checking: "Checking the key with Command Code...",
    keyValid: "Key is valid — {n} models.",
    keyInvalid: "Key is NOT valid, or the server is unreachable ({e}).",
    nothingWritten: "Stopped. Nothing was written — your current setup is untouched.",
    cancelled: "Cancelled.",
    retry: "Try again.",
    keepKey: "Keeping the existing key.",

    configLine: "Config: {p} ({src})",
    srcDeclared: "reported by opencode",
    srcConvention: "by convention",
    cliWritten: "CLI: key written.",
    cliFailed: "Could not write the CLI part ({e}) — OpenCode continues anyway.",
    backup: "Backup: {f}",
    providerCreated: "providers.cmd created → {n} models.",
    providerKeyOnly: "providers.cmd already existed → key updated only, model list untouched.",
    claudeCreated: "providers.cmd-claude → {n} models.",

    verifyHeader: "Verifying",
    keyMatch: "Key matches in both providers.",
    keyMismatch: "The written key does not match!",
    modelsCount: "providers.cmd: {n} models.",
    preserved: "Preserved: {list}.",
    e2eRunning: "Running a real request through OpenCode...",
    e2eOk: "Live request succeeded ({m}).",
    e2eWarn: "Could not verify end-to-end (you may need to reopen OpenCode). {e}",

    done: "DONE — WIRED UP",
    configLabel: "Config : {p}",
    backupLabel: "Backup : {p}",
    noBackup: "(none, new file)",
    restartHint: "Reopen OpenCode, then type /models to pick a cmd/... model.",
    errorPrefix: "Error:",
  },

  vi: {
    langTitle: "Chọn ngôn ngữ",
    langAsk: "Chọn (1/2): ",

    title: "COMMAND CODE  →  OPENCODE",
    step1: "Dò môi trường",
    step2: "Kiểm tra OpenCode đã nối với Command Code chưa",
    step3: "Xác định việc cần làm",
    step4: "Kiểm tra cài đặt",
    step5: "Nhập API key",
    step6: "Cấu hình",

    nodePresent: "Node {v} đã có.",
    opencodePresent: "OpenCode {v}",
    opencodeMissing: "Chưa cài OpenCode.",
    cmdcPresent: "Command Code {v} (lệnh: {n})",
    cmdcMissing: "Chưa cài Command Code CLI.",
    configDeclared: "OpenCode khai báo config tại: {p}",
    configGuessed: "Đoán theo quy ước: {p}",
    configBadJson: "{f} không phải JSON hợp lệ.",
    configBadJsonHint: "Đã dừng để không làm hỏng file. Sửa file đó rồi chạy lại.",

    providerPresent: "config có providers.cmd ({n} model).",
    providerAbsent: "config chưa có providers.cmd.",
    statusLabel: "Trạng thái: {s}",
    statusReady: "đã nối sẵn sàng",
    statusNotConfigured: "chưa cấu hình",
    statusKeyInvalid: "có cấu hình nhưng key không hợp lệ",
    statusUnverified: "có cấu hình, chưa kiểm tra được (offline)",

    alreadyConnected: "OpenCode và Command Code đã nối với nhau — không cần cấu hình lại.",
    askRotate: "Bạn có muốn ĐỔI key không? (y/N) ",
    nothingToDo: "Không có gì phải làm. Bạn đã dùng được rồi.",
    needKeyInvalid: "Key đang lưu không dùng được — cần nhập key mới.",
    needKeyUnverified: "Sẽ kiểm tra lại key khi có mạng.",
    needConfig: "Cần cấu hình provider cho OpenCode.",

    notInstalled: "Chưa cài {what}.",
    willRun: "Lệnh sẽ chạy:  {cmd}",
    installNow: "Cài bây giờ? (Y/n) ",
    installing: "Đang chạy (có thể mất vài phút)...",
    skipInstall: "Bỏ qua cài {what}.",
    opencodeMissingFatal: "Thiếu OpenCode, không thể tiếp tục.",
    installedButNotFound: "Cài xong nhưng không tìm thấy `opencode` trong PATH.",
    alreadyInstalled: "{what} đã có — bỏ qua cài đặt.",
    cmdcInstalledNotInPath: "Cài xong nhưng chưa thấy trong PATH (có thể cần mở lại terminal).",
    skipCli: "Bỏ qua CLI — OpenCode vẫn dùng được.",

    keyPage: "Lấy tại: {url}",
    keyPrompt: "Dán key rồi nhấn Enter: ",
    keyGot: "Key nhận được: {fp}",
    confirmKey: "Đúng chưa? (Y/n) ",
    keyBlank: "Chưa nhập gì.",
    invalidFp: "<không hợp lệ>",
    checking: "Đang kiểm tra key với máy chủ Command Code...",
    keyValid: "Key hợp lệ — {n} model.",
    keyInvalid: "Key KHÔNG hợp lệ hoặc không kết nối được ({e}).",
    nothingWritten: "Đã dừng. KHÔNG ghi gì cả — setup hiện tại vẫn nguyên vẹn.",
    cancelled: "Đã huỷ.",
    retry: "Nhập lại.",
    keepKey: "Giữ nguyên key đang có.",

    configLine: "Config: {p} ({src})",
    srcDeclared: "opencode tự khai báo",
    srcConvention: "theo quy ước",
    cliWritten: "CLI: đã ghi key.",
    cliFailed: "Không ghi được phần CLI ({e}) — OpenCode vẫn tiếp tục.",
    backup: "Backup: {f}",
    providerCreated: "providers.cmd đã tạo → {n} model.",
    providerKeyOnly: "providers.cmd đã có → chỉ đổi key, giữ nguyên danh sách model.",
    claudeCreated: "providers.cmd-claude → {n} model.",

    verifyHeader: "Kiểm chứng",
    keyMatch: "Key khớp ở cả 2 provider.",
    keyMismatch: "Key ghi vào chưa khớp!",
    modelsCount: "providers.cmd: {n} model.",
    preserved: "Giữ nguyên: {list}.",
    e2eRunning: "Đang thử thật một request qua OpenCode...",
    e2eOk: "Thử thật thành công ({m}).",
    e2eWarn: "Chưa thử được end-to-end (có thể cần mở lại OpenCode). {e}",

    done: "XONG — ĐÃ NỐI XONG",
    configLabel: "Config : {p}",
    backupLabel: "Backup : {p}",
    noBackup: "(chưa có, file mới)",
    restartHint: "Mở lại OpenCode, rồi gõ /models để chọn model cmd/...",
    errorPrefix: "Lỗi:",
  },
};

let LANG = "en";

/** Dịch một khoá, thay {placeholder}. Thiếu khoá thì rơi về tiếng Anh. */
export function t(key, vars) {
  let s = M[LANG]?.[key] ?? M.en[key] ?? key;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(String(v));
  }
  return s;
}

export function setLang(l) {
  LANG = l === "vi" ? "vi" : "en";
  return LANG;
}

export function getLang() {
  return LANG;
}

export function detectLang(env = process.env, locale) {
  const e = String(env.CMDCODE_LANG || "").toLowerCase();
  if (e.startsWith("vi")) return "vi";
  if (e.startsWith("en")) return "en";
  const loc = String(locale || "").toLowerCase();
  return loc.startsWith("vi") ? "vi" : "en";
}

// ============================================================
// Logic thuần (được test trong setup-commandcode.test.mjs)
// ============================================================

const stripAnsi = (s) => s.replace(/\x1b\[[0-9;]*m/g, "");

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
 * Đánh giá mức độ "đã nối OpenCode với Command Code chưa".
 *   not-configured      — chưa có provider, hoặc có mà thiếu key
 *   key-invalid         — có provider + key nhưng key hỏng
 *   ready               — có provider + key hợp lệ
 *   configured-unverified — có provider + key, chưa kiểm tra được (offline)
 */
export function assessConnection(config, keyValid) {
  const key = config?.providers?.cmd?.settings?.apiKey;
  if (!isProviderPresent(config, "cmd") || !key) return "not-configured";
  if (keyValid === true) return "ready";
  if (keyValid === false) return "key-invalid";
  return "configured-unverified";
}

// ============================================================
// Tiện ích I/O
// ============================================================

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m", dim: "\x1b[2m",
  red: "\x1b[31m", green: "\x1b[32m", yellow: "\x1b[33m", cyan: "\x1b[36m",
};
const say = (s = "") => console.log(s);
const ok = (s) => say(`      ${C.green}✓${C.reset} ${s}`);
const bad = (s) => say(`      ${C.red}✗${C.reset} ${s}`);
const warn = (s) => say(`      ${C.yellow}!${C.reset} ${s}`);
const step = (n, s) => say(`${C.cyan}[${n}] ${s}${C.reset}`);

function tryRun(cmd, opts = {}) {
  try {
    const out = execSync(cmd, { stdio: ["ignore", "pipe", "pipe"], encoding: "utf8", ...opts });
    return { ok: true, out: stripAnsi(String(out)).trim() };
  } catch (e) {
    const out = stripAnsi(String(e.stdout || "") + String(e.stderr || "")).trim();
    return { ok: false, out };
  }
}

function findTool(names) {
  for (const n of names) {
    const r = tryRun(`${n} --version`);
    if (r.ok && r.out) return { name: n, version: r.out.split(/\r?\n/)[0].trim() };
  }
  return null;
}

// --- Nhập liệu ---
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

const isTTY = () => Boolean(process.stdin.isTTY && process.stdout.isTTY);
const ask = (q) => (isTTY() ? ttyAsk(q, false) : pipedAsk(q));
const askHidden = (q) => (isTTY() ? ttyAsk(q, true) : pipedAsk(q));
const askYes = async (q, def = false) => {
  const a = await ask(q);
  if (!a) return def;
  return /^(y|yes|có|co|v)$/i.test(a);
};

const fingerprint = (k) =>
  !k || k.length < 20 ? t("invalidFp") : `${k.slice(0, 10)}…${k.slice(-6)}  (${k.length})`;

async function fetchModels(apiKey) {
  const res = await fetch(`${API_BASE}/models`, { headers: { Authorization: `Bearer ${apiKey}` } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const j = await res.json();
  return Array.isArray(j) ? j : j.data || [];
}

function writeAtomic(file, text) {
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

function readConfigIfAny(file) {
  if (!fs.existsSync(file)) return {};
  try { return readJsonFile(file); } catch { return null; }
}

async function installWithConfirm(what, cmd) {
  say();
  warn(t("notInstalled", { what }));
  say(`      ${t("willRun", { cmd: "" })}${C.cyan}${cmd}${C.reset}`);
  if (!(await askYes("      " + t("installNow"), true))) {
    warn(t("skipInstall", { what }));
    return false;
  }
  say("      " + t("installing"));
  const r = tryRun(cmd, { stdio: "inherit" });
  return r.ok;
}

async function chooseLanguage() {
  const fromEnv = detectLang(process.env, null);
  if (String(process.env.CMDCODE_LANG || "").length > 0) {
    setLang(fromEnv);
    return;
  }
  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   ${M.en.langTitle}  /  ${M.vi.langTitle}${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say();
  say("     [1] English");
  say("     [2] Tiếng Việt");
  say();
  const a = await ask("  " + M.en.langAsk);
  setLang(a === "2" ? "vi" : "en");
}

// ============================================================
// main
// ============================================================

async function main() {
  await chooseLanguage();

  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   ${t("title")}${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);

  // ---------- 1. Dò môi trường ----------
  say();
  step("1/6", t("step1"));

  ok(t("nodePresent", { v: process.version }));

  let opencode = findTool(["opencode"]);
  opencode ? ok(t("opencodePresent", { v: opencode.version })) : warn(t("opencodeMissing"));

  let cmdc = findTool(["cmdc", "command-code", "cmd"]);
  cmdc ? ok(t("cmdcPresent", { v: cmdc.version, n: cmdc.name })) : warn(t("cmdcMissing"));

  const discoverConfigDir = () => {
    if (opencode) {
      const r = tryRun("opencode debug paths");
      if (r.ok) {
        const p = parseDebugPaths(r.out);
        if (p.config) return { dir: p.config, src: t("srcDeclared") };
      }
    }
    return { dir: resolveConfigDir({ env: process.env, homedir: os.homedir() }), src: t("srcConvention") };
  };

  let cfgInfo = discoverConfigDir();
  const configFileEarly = path.join(cfgInfo.dir, "opencode.json");
  let existing = readConfigIfAny(configFileEarly);

  if (existing === null) {
    say();
    bad(t("configBadJson", { f: configFileEarly }));
    warn(t("configBadJsonHint"));
    process.exit(1);
  }

  // ---------- 2. Đánh giá kết nối ----------
  say();
  step("2/6", t("step2"));

  const storedKey = existing?.providers?.cmd?.settings?.apiKey;
  let keyValid = null;
  if (storedKey) {
    try { await fetchModels(storedKey); keyValid = true; }
    catch { keyValid = false; }
  }

  const status = assessConnection(existing, keyValid);
  const STATUS_TEXT = {
    ready: t("statusReady"),
    "not-configured": t("statusNotConfigured"),
    "key-invalid": t("statusKeyInvalid"),
    "configured-unverified": t("statusUnverified"),
  };

  if (existing?.providers?.cmd) ok(t("providerPresent", { n: Object.keys(existing.providers.cmd.models || {}).length }));
  else warn(t("providerAbsent"));
  say(`      ${t("statusLabel", { s: `${C.bold}${STATUS_TEXT[status]}${C.reset}` })}`);

  // ---------- 3. Quyết định ----------
  say();
  step("3/6", t("step3"));

  let key = null;
  let needConfig = false;

  if (status === "ready") {
    ok(t("alreadyConnected"));
    if (await askYes("      " + t("askRotate"), false)) {
      needConfig = true;
    } else {
      say();
      say(`${C.green}${C.bold}${t("nothingToDo")}${C.reset}`);
      return;
    }
  } else {
    needConfig = true;
    if (status === "key-invalid") warn(t("needKeyInvalid"));
    if (status === "configured-unverified") say("      " + t("needKeyUnverified"));
    if (status === "not-configured") say("      " + t("needConfig"));
  }

  // ---------- 4. Cài nếu thiếu ----------
  say();
  step("4/6", t("step4"));

  if (!opencode) {
    if (!(await installWithConfirm("OpenCode", CMD_OPENCODE))) {
      bad(t("opencodeMissingFatal")); process.exit(1);
    }
    opencode = findTool(["opencode"]);
    if (!opencode) { bad(t("installedButNotFound")); process.exit(1); }
    ok(t("opencodePresent", { v: opencode.version }));
    cfgInfo = discoverConfigDir();
  } else ok(t("alreadyInstalled", { what: "OpenCode" }));

  if (!cmdc) {
    if (await installWithConfirm("Command Code CLI", CMD_CMDC)) {
      cmdc = findTool(["cmdc", "command-code", "cmd"]);
      cmdc ? ok(t("cmdcPresent", { v: cmdc.version, n: cmdc.name })) : warn(t("cmdcInstalledNotInPath"));
    } else warn(t("skipCli"));
  } else ok(t("alreadyInstalled", { what: "Command Code" }));

  // ---------- 5. Nhập key ----------
  if (needConfig) {
    say();
    step("5/6", t("step5"));
    say(`${C.dim}      ${t("keyPage", { url: KEY_PAGE })}${C.reset}`);
    while (true) {
      key = (await askHidden("      " + t("keyPrompt"))).trim();
      if (!key) { bad(t("keyBlank")); process.exit(1); }
      say(`      ${t("keyGot", { fp: `${C.yellow}${fingerprint(key)}${C.reset}` })}`);
      if (await askYes("      " + t("confirmKey"), true)) break;
      if (!isTTY()) { bad(t("cancelled")); process.exit(0); }
      warn(t("retry"));
    }

    say();
    say("      " + t("checking"));
    try {
      const n = (await fetchModels(key)).length;
      ok(t("keyValid", { n }));
      keyValid = true;
    } catch (e) {
      bad(t("keyInvalid", { e: e.message }));
      warn(t("nothingWritten"));
      process.exit(1);
    }
  } else {
    say();
    step("5/6", t("step5"));
    ok(t("keepKey"));
    key = storedKey;
  }

  // ---------- 6. Ghi cấu hình ----------
  say();
  step("6/6", t("step6"));
  const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const configDir = cfgInfo.dir;
  const configFile = path.join(configDir, "opencode.json");
  const cliAuthFile = path.join(os.homedir(), ".commandcode", "auth.json");
  say(`${C.dim}      ${t("configLine", { p: configFile, src: cfgInfo.src })}${C.reset}`);

  try {
    fs.mkdirSync(path.dirname(cliAuthFile), { recursive: true });
    if (fs.existsSync(cliAuthFile)) fs.copyFileSync(cliAuthFile, `${cliAuthFile}.bak-${stamp}`);
    const a = fs.existsSync(cliAuthFile) ? readJsonFile(cliAuthFile) : {};
    a.apiKey = key;
    writeAtomic(cliAuthFile, JSON.stringify(a, null, 2));
    ok(t("cliWritten"));
  } catch (e) {
    warn(t("cliFailed", { e: e.message }));
  }

  fs.mkdirSync(configDir, { recursive: true });
  if (fs.existsSync(configFile)) {
    fs.copyFileSync(configFile, `${configFile}.bak-${stamp}`);
    ok(t("backup", { f: path.basename(configFile) + `.bak-${stamp}` }));
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

  hadCmd
    ? ok(t("providerKeyOnly"))
    : ok(t("providerCreated", { n: openaiCapable.length }));
  ok(t("claudeCreated", { n: anthropicOnly.length }));

  // ---------- Kiểm chứng ----------
  say();
  say(`${C.cyan}${t("verifyHeader")}${C.reset}`);
  const after = readJsonFile(configFile);
  const bothKeysOk = after.providers?.cmd?.settings?.apiKey === key
    && after.providers?.["cmd-claude"]?.settings?.apiKey === key;
  bothKeysOk ? ok(t("keyMatch")) : bad(t("keyMismatch"));
  ok(t("modelsCount", { n: Object.keys(after.providers?.cmd?.models || {}).length }));
  const kept = ["plugins", "mcp", "agents"].filter((k) => after[k]);
  if (kept.length) ok(t("preserved", { list: kept.join(", ") }));

  const e2eModel = after.providers?.cmd?.models?.[E2E_PREFERRED]
    ? E2E_PREFERRED
    : Object.keys(after.providers?.cmd?.models || {})[0];
  if (e2eModel && opencode) {
    say("      " + t("e2eRunning"));
    const r = tryRun(`opencode run --model cmd/${e2eModel} "Reply with exactly: PONG"`);
    if (r.ok && /PONG/i.test(r.out)) ok(t("e2eOk", { m: `cmd/${e2eModel}` }));
    else warn(t("e2eWarn", { e: r.out.split(/\r?\n/).slice(-1)[0] || "" }));
  }

  say();
  say(`${C.green}${C.bold}==================================================${C.reset}`);
  say(`${C.green}${C.bold}   ${t("done")}${C.reset}`);
  say(`${C.green}${C.bold}==================================================${C.reset}`);
  say("  " + t("configLabel", { p: configFile }));
  const bk = `${configFile}.bak-${stamp}`;
  say("  " + t("backupLabel", { p: fs.existsSync(bk) ? bk : t("noBackup") }));
  say();
  say(`  ${C.yellow}${t("restartHint")}${C.reset}`);
  say();
}

const isDirect = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isDirect) {
  main()
    .catch((e) => { console.error(`${C.red}${M[LANG]?.errorPrefix ?? M.en.errorPrefix}${C.reset} ${e.message}`); process.exitCode = 1; })
    .finally(() => {
      // readline giữ event loop sống: không đóng thì Node treo, không bao giờ thoát.
      if (rlTTY) { try { rlTTY.close(); } catch { /* đã đóng */ } }
      // Lưới an toàn: nếu còn thứ gì khác giữ tiến trình sống, ép thoát.
      // unref() nên hẹn giờ này không tự giữ tiến trình sống.
      setTimeout(() => process.exit(process.exitCode ?? 0), 250).unref();
    });
}
