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

node "%PAYLOAD%" %*
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

node "$PAYLOAD" "$@"
rc=$?
rm -f "$PAYLOAD"
exit "$rc"

#__PAYLOAD__
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execSync } from "node:child_process";
import { pathToFileURL } from "node:url";

// ---------- lib/shared.mjs ----------
// lib/shared.mjs — lớp nền dùng chung cho mọi lệnh con.
//
// KHÔNG có shebang, không import nội bộ trong bản đã gộp: bundler tự chèn
// phần import của Node ở đầu. Ở đây vẫn để import để chạy/test trực tiếp được;
// bundler sẽ bỏ chúng khi gộp.
//
// Mỗi module tự đăng ký chuỗi của mình bằng registerMessages(), nên các module
// không giẫm lên nhau khi làm song song.


// ============================================================
// Hằng số
// ============================================================

const API_BASE = "https://api.commandcode.ai/provider/v1";
const PKG_OPENAI = "@opencode/ai/providers/openai-compatible";
const PKG_ANTHROPIC = "@opencode/ai/providers/anthropic";
const CMD_OPENCODE = "npm i -g @opencode/cli";
const CMD_CMDC = "npm i -g command-code";
const DEFAULT_CONTEXT = 200000;
const DEFAULT_OUTPUT = 32000;
const KEY_PAGE = "https://commandcode.ai/settings/keys";
const E2E_PREFERRED = "deepseek/deepseek-v4-flash";
const VERSION = "1.1.0";

// ============================================================
// Đa ngữ
// ============================================================

const MESSAGES = { en: {}, vi: {} };
let LANG = "en";

/** Mỗi module gọi hàm này một lần ở cấp cao nhất để nạp chuỗi của mình. */
function registerMessages(en, vi) {
  Object.assign(MESSAGES.en, en);
  Object.assign(MESSAGES.vi, vi);
}

function setLang(l) {
  LANG = l === "vi" ? "vi" : "en";
  return LANG;
}

function getLang() {
  return LANG;
}

/** Dịch một khoá, thay {placeholder}. Thiếu khoá thì trả về chính khoá đó. */
function t(key, vars) {
  let s = MESSAGES[LANG]?.[key] ?? MESSAGES.en[key] ?? key;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(String(v));
  }
  return s;
}

function detectLang(env = process.env, locale) {
  const e = String(env.CMDCODE_LANG || "").toLowerCase();
  if (e.startsWith("vi")) return "vi";
  if (e.startsWith("en")) return "en";
  const loc = String(locale || "").toLowerCase();
  return loc.startsWith("vi") ? "vi" : "en";
}

// ============================================================
// Màu và in ấn
// ============================================================

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m", dim: "\x1b[2m",
  red: "\x1b[31m", green: "\x1b[32m", yellow: "\x1b[33m", cyan: "\x1b[36m",
};

const say = (s = "") => console.log(s);
const ok = (s) => say(`      ${C.green}✓${C.reset} ${s}`);
const bad = (s) => say(`      ${C.red}✗${C.reset} ${s}`);
const warn = (s) => say(`      ${C.yellow}!${C.reset} ${s}`);
const info = (s) => say(`      ${C.dim}${s}${C.reset}`);
const step = (n, s) => say(`${C.cyan}[${n}] ${s}${C.reset}`);

function banner(title) {
  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   ${title}${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
}

// ============================================================
// Chạy lệnh ngoài
// ============================================================

const stripAnsi = (s) => String(s).replace(/\x1b\[[0-9;]*m/g, "");

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
function closeInput() {
  if (rlTTY) { try { rlTTY.close(); } catch { /* đã đóng */ } rlTTY = null; }
}

const isTTY = () => Boolean(process.stdin.isTTY && process.stdout.isTTY);
const ask = (q) => (isTTY() ? ttyAsk(q, false) : pipedAsk(q));
const askHidden = (q) => (isTTY() ? ttyAsk(q, true) : pipedAsk(q));
const askYes = async (q, def = false) => {
  const a = await ask(q);
  if (!a) return def;
  return /^(y|yes|có|co|v)$/i.test(a);
};

// ============================================================
// Đọc/ghi file
// ============================================================

function writeAtomic(file, text) {
  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, text, "utf8");
  fs.renameSync(tmp, file);
}

/** Đọc JSON, chịu được BOM (PowerShell/Notepad trên Windows hay thêm vào). */
function readJsonFile(file) {
  let raw = fs.readFileSync(file, "utf8");
  if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);
  return JSON.parse(raw);
}

/** Trả về {} nếu chưa có file, null nếu file hỏng. */
function readConfigIfAny(file) {
  if (!fs.existsSync(file)) return {};
  try { return readJsonFile(file); } catch { return null; }
}

const stamp = () => new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);

// ============================================================
// Logic thuần (được test)
// ============================================================

/** Đọc output của `opencode debug paths` thành object. */
function parseDebugPaths(stdout) {
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
function resolveConfigDir({ debugPaths, env = {}, homedir = os.homedir() } = {}) {
  if (debugPaths && debugPaths.config) return debugPaths.config;
  if (env.XDG_CONFIG_HOME) return path.join(env.XDG_CONFIG_HOME, "opencode");
  return path.join(homedir, ".config", "opencode");
}

/** Chia model theo route mà nó phục vụ. */
function splitModels(models) {
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
function buildProviderBlock({ models, apiKey, packageName, displayName }) {
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
function mergeProviders(existing, newProviders) {
  const clone = structuredClone(existing || {});
  clone.providers = clone.providers || {};
  for (const [id, block] of Object.entries(newProviders || {})) {
    clone.providers[id] = block;
  }
  return clone;
}

function isProviderPresent(config, id) {
  return Boolean(config && config.providers && Object.hasOwn(config.providers, id));
}

/**
 * ready | not-configured | key-invalid | configured-unverified
 */
function assessConnection(config, keyValid) {
  const key = config?.providers?.cmd?.settings?.apiKey;
  if (!isProviderPresent(config, "cmd") || !key) return "not-configured";
  if (keyValid === true) return "ready";
  if (keyValid === false) return "key-invalid";
  return "configured-unverified";
}

// ============================================================
// Phần dùng chung cho các lệnh con
// ============================================================

async function fetchModels(apiKey) {
  const res = await fetch(`${API_BASE}/models`, { headers: { Authorization: `Bearer ${apiKey}` } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const j = await res.json();
  return Array.isArray(j) ? j : j.data || [];
}

const fingerprint = (k) =>
  !k || k.length < 20 ? t("invalidFp") : `${k.slice(0, 10)}…${k.slice(-6)}  (${k.length})`;

/** Tìm thư mục config: hỏi chính OpenCode, không hardcode. */
function discoverConfigDir(opencode) {
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
function probeEnvironment() {
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
function listBackups(configFile) {
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
function messageKeys() {
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

// ---------- lib/install.mjs ----------
// lib/install.mjs — lệnh con `install` (mặc định): nối Command Code vào OpenCode.
// Đây là luồng cũ, chỉ đổi chỗ ở và tự đăng ký chuỗi của mình.



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

const installCmd = {
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

// ---------- lib/doctor.mjs ----------
// lib/doctor.mjs — lệnh con `doctor`: kiểm tra sức khoẻ toàn bộ hệ thống.
//
// CHỈ ĐỌC. Không ghi, không sửa, không cài gì cả.
//
// Kiểm lần lượt: Node, OpenCode, Command Code CLI, vị trí config, tính hợp lệ
// của config, provider đã nối chưa, API key còn sống không, (tuỳ chọn) model
// nào thật sự chạy được, MCP server, skills, backup.
//
// Trả mã thoát 0 nếu mọi thứ ổn, 1 nếu có mục hỏng.



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

const doctorCmd = {
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

// ---------- lib/backup.mjs ----------
// lib/backup.mjs — lệnh con `backup`: xem, phục hồi và dọn bớt các bản sao lưu
// `opencode.json.bak-<mốc thời gian>` mà installer tạo mỗi lần ghi config.
//
// Ba việc: liệt kê (mặc định), `restore <số|tên>`, `prune [--keep N] [--dry-run]`.
// Module chỉ dùng shared.mjs và các module `node:` dựng sẵn.
//
// Mọi tên khai báo ở cấp cao nhất đều bắt đầu bằng `backup` vì bản build gộp
// phẳng tất cả module vào một phạm vi — tên không tiền tố sẽ đụng nhau.



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

const backupCmd = {
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

// ---------- lib/uninstall.mjs ----------
// lib/uninstall.mjs — lệnh con `uninstall`: gỡ Command Code khỏi OpenCode.
// Đảo ngược đúng những gì install.mjs đã ghi: 2 provider trong opencode.json
// và key trong ~/.commandcode/auth.json. Phần còn lại của config giữ nguyên.


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

const uninstallCmd = {
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

// ---------- lib/probe.mjs ----------
// lib/probe.mjs — lệnh con `probe`: dò xem GÓI hiện tại thực sự dùng được model nào.
//
// /models trả về đủ bộ model bất kể gói, nhiều model bị chặn. Lệnh này gọi thử
// từng model bằng một request chat ngắn rồi phân loại: dùng được / cần gói cao
// hơn / tạm bị giới hạn / lỗi. Mặc định chỉ BÁO CÁO, không sửa gì; thêm --write
// mới lọc providers.cmd.models còn đúng các model dùng được (có backup trước).
//
// Bài học cũ: max_tokens phải >= 16. Bản probe trước dùng max_tokens = 1 nên
// API trả HTTP 400 `Invalid 'max_output_tokens'` và báo hỏng oan.



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

const probeCmd = {
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

// ---------- lib/models.mjs ----------
// lib/models.mjs — lệnh con `models`: xem và chọn model mặc định.
//
// Thuần đọc/ghi file config OpenCode, không gọi mạng.
// Mọi tên ở cấp cao nhất đều bắt đầu bằng `models` vì bundler gộp phẳng
// tất cả module vào một phạm vi.



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

const modelsCmd = {
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

// ---------- main.mjs ----------
// main.mjs — điểm vào: chọn ngôn ngữ, định tuyến lệnh con.
//
// Chạy không tham số  -> install
// Có tham số          -> lệnh con tương ứng, hoặc trợ giúp



registerMessages(
  {
    "main.langTitle": "Choose language",
    "main.langAsk": "Choose (1/2): ",
    "main.choose": "Chọn",
    "main.unknown": "Unknown command: {c}",
    "main.usage": "Usage:",
    "main.commands": "Commands:",
    "main.options": "Options:",
    "main.helpHint": "Run with no arguments to install.",
    "main.noCmd": "no command",
  },
  {
    "main.langTitle": "Chọn ngôn ngữ",
    "main.langAsk": "Chọn (1/2): ",
    "main.choose": "Chọn",
    "main.unknown": "Không có lệnh: {c}",
    "main.usage": "Cách dùng:",
    "main.commands": "Các lệnh:",
    "main.options": "Tuỳ chọn:",
    "main.helpHint": "Chạy không tham số để cài đặt.",
    "main.noCmd": "không có lệnh",
  }
);

const ALL = [installCmd, doctorCmd, backupCmd, uninstallCmd, probeCmd, modelsCmd];

// Thứ tự hiển thị trong trợ giúp; install luôn đầu.
const HELP_ORDER = ["install", "doctor", "backup", "uninstall", "probe", "models"];

async function chooseLanguage(argv) {
  // -L/--lang <en|vi> hoặc CMDCODE_LANG đều thắng, không hỏi.
  const i = argv.indexOf("--lang");
  if (i >= 0 && argv[i + 1]) { setLang(argv[i + 1]); return; }
  if (process.env.CMDCODE_LANG) { setLang(detectLang(process.env, null)); return; }

  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   ${"Chon ngon ngu  /  Choose language"}${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say();
  say("     [1] English");
  say("     [2] Tiếng Việt");
  say();
  const a = await ask("  Chọn / Choose (1/2): ");
  setLang(a === "2" ? "vi" : "en");
}

function printHelp() {
  banner(`COMMAND CODE  →  OPENCODE   v${VERSION}`);
  say();
  say(`  ${t("main.usage")}  cmd [command] [options]`);
  say();
  say(`  ${t("main.commands")}`);
  for (const n of HELP_ORDER) {
    const c = ALL.find((x) => x.name === n);
    if (!c) continue;
    const label = n === "install" ? `${n} (${t("main.noCmd")})` : n;
    say(`     ${C.cyan}${label.padEnd(24)}${C.reset}${c.summary()}`);
  }
  say();
  say(`  ${t("main.options")}`);
  say(`     ${"--lang en|vi".padEnd(24)}${t("main.langTitle")}`);
  say(`     ${"-h, --help".padEnd(24)}${t("main.usage")}`);
  say(`     ${"-v, --version".padEnd(24)}v${VERSION}`);
  say();
  say(`  ${C.dim}${t("main.helpHint")}${C.reset}`);
  say();
}

const isDirect = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isDirect) {
  const argv = process.argv.slice(2);

  const done = (code) => {
    closeInput();
    // Lưới an toàn: nếu còn gì giữ event loop sống, ép thoát.
    setTimeout(() => process.exit(code), 250).unref();
  };

  (async () => {
    if (argv.includes("-v") || argv.includes("--version")) {
      console.log(VERSION);
      return 0;
    }
    if (argv.includes("-h") || argv.includes("--help")) {
      // Trợ giúp vẫn cần ngôn ngữ, nhưng không hỏi nếu đã có cách khác.
      await chooseLanguage(argv).catch(() => {});
      printHelp();
      return 0;
    }

    await chooseLanguage(argv);

    // Bỏ các cờ toàn cục trước khi tìm tên lệnh.
    const rest = [];
    for (let i = 0; i < argv.length; i++) {
      if (argv[i] === "--lang") { i++; continue; }
      rest.push(argv[i]);
    }

    if (rest.length === 0) return await installCmd.run([]);

    const name = rest[0];
    const cmd = ALL.find((x) => x.name === name);
    if (!cmd) {
      bad(t("main.unknown", { c: name }));
      say();
      printHelp();
      return 1;
    }
    return await cmd.run(rest.slice(1));
  })()
    .then(done)
    .catch((e) => {
      console.error(`${C.red}${t("main.unknown", { c: "" }) && ""}${C.reset}${e.message}`);
      done(1);
    });
}
