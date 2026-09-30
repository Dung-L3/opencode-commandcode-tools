: << 'BATCH_EOF'
@echo off
setlocal EnableDelayedExpansion
set "SELF=%~f0"
set "PAYLOAD=%TEMP%\cmdcode-%RANDOM%-%RANDOM%.mjs"

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo   Node.js chua duoc cai tren may nay.
  echo.
  where winget >nul 2>nul
  if errorlevel 1 (
    echo   Khong tim thay winget tren may nay.
echo.
echo   ==================================================
echo    KHONG CAI DUOC NODE TU DONG
echo   ==================================================
echo.
echo    Cong cu nay can Node.js de chay.
echo    Phan cai tu dong khong thanh cong.
echo.
echo    Hay cai Node THU CONG:
echo.
echo      1. Mo trang:  https://nodejs.org/en/download
echo      2. Tai ban LTS cho he dieu hanh cua ban
echo      3. Cai dat xong
echo      4. Chay lai file nay
echo.
echo    Node cai xong la chay duoc, khong can cau hinh gi them.
echo.
    start "" "https://nodejs.org/en/download"
    pause
    exit /b 1
  )
  set "ANS="
  set /p "ANS=  Cai Node.js LTS bang winget bay gio? (Y/n) "
  if /i "!ANS!"=="n" (
    echo   Da huy.
    pause
    exit /b 1
  )
  if /i "!ANS!"=="no" (
    echo   Da huy.
    pause
    exit /b 1
  )
  echo.
  echo   Dang cai Node.js LTS, co the mat vai phut...
  winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  if errorlevel 1 (
    echo.
    echo   winget bao loi khi cai Node.
    echo.
  )
  rem Node vua cai co the chua kip vao PATH cua tien trinh nay
  set "PATH=%ProgramFiles%\nodejs;%PATH%"
)

where node >nul 2>nul
if errorlevel 1 (
echo.
echo   ==================================================
echo    KHONG CAI DUOC NODE TU DONG
echo   ==================================================
echo.
echo    Cong cu nay can Node.js de chay.
echo    Phan cai tu dong khong thanh cong.
echo.
echo    Hay cai Node THU CONG:
echo.
echo      1. Mo trang:  https://nodejs.org/en/download
echo      2. Tai ban LTS cho he dieu hanh cua ban
echo      3. Cai dat xong
echo      4. Chay lai file nay
echo.
echo    Node cai xong la chay duoc, khong can cau hinh gi them.
echo.
  pause
  exit /b 1
)

rem Tach phan JavaScript o cuoi file ra file tam (dung PowerShell cho chac)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#__PAYLOAD__'; $t=[IO.File]::ReadAllText('%SELF%'); $i=$t.LastIndexOf($m); if($i -lt 0){ exit 1 }; [IO.File]::WriteAllText('%PAYLOAD%', $t.Substring($i + $m.Length).TrimStart(), (New-Object Text.UTF8Encoding $false))"
if errorlevel 1 (
  echo.
  echo   Loi: khong tach duoc phan JavaScript trong file nay.
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

install_node() {
  if command -v brew >/dev/null 2>&1; then
    printf "  Cài Node.js bằng Homebrew bây giờ? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    brew install node || return 1
  elif command -v apt-get >/dev/null 2>&1; then
    printf "  Cài Node.js bằng apt (cần quyền sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo apt-get update && sudo apt-get install -y nodejs npm || return 1
  elif command -v dnf >/dev/null 2>&1; then
    printf "  Cài Node.js bằng dnf (cần quyền sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo dnf install -y nodejs || return 1
  elif command -v pacman >/dev/null 2>&1; then
    printf "  Cài Node.js bằng pacman (cần quyền sudo)? (Y/n) "
    read -r ans
    case "${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo pacman -S --noconfirm nodejs npm || return 1
  else
    echo "  Không tìm thấy trình quản lý gói quen thuộc (brew/apt/dnf/pacman)."
    echo
    echo "  Hãy cài Node thủ công: https://nodejs.org/en/download"
    return 1
  fi
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  echo
  echo "  Node.js chưa được cài trên máy này."
  echo

  if ! install_node; then
echo
echo "  =================================================="
echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"
echo "  =================================================="
echo
echo "   Công cụ này cần Node.js để chạy."
echo "   Phần cài tự động không thành công."
echo
echo "   Hãy cài Node THỦ CÔNG:"
echo
echo "     1. Mở trang:  https://nodejs.org/en/download"
echo "     2. Tải bản LTS cho hệ điều hành của bạn"
echo "     3. Cài đặt xong"
echo "     4. Chạy lại file này"
echo
echo "   Node cài xong là chạy được, không cần cấu hình gì thêm."
echo
    exit 1
  fi

  # Cài xong nhưng chưa chắc đã có trong PATH của phiên hiện tại
  if ! command -v node >/dev/null 2>&1; then
echo
echo "  =================================================="
echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"
echo "  =================================================="
echo
echo "   Công cụ này cần Node.js để chạy."
echo "   Phần cài tự động không thành công."
echo
echo "   Hãy cài Node THỦ CÔNG:"
echo
echo "     1. Mở trang:  https://nodejs.org/en/download"
echo "     2. Tải bản LTS cho hệ điều hành của bạn"
echo "     3. Cài đặt xong"
echo "     4. Chạy lại file này"
echo
echo "   Node cài xong là chạy được, không cần cấu hình gì thêm."
echo
    exit 1
  fi
  echo "  Node đã cài xong: $(node --version)"
fi

LINE="$(grep -n '^#__PAYLOAD__$' "$SELF" | tail -n 1 | cut -d: -f1)"
if [ -z "$LINE" ]; then
  echo
  echo "  Lỗi: không tách được phần JavaScript trong file này."
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
// Thường được gọi qua install.cmd (Windows) hoặc install.sh (Linux/macOS),
// vì hai file đó lo việc bảo đảm Node đã có trước.
//
// Không hardcode đường dẫn: hỏi chính OpenCode nơi nó để config,
// fallback theo quy ước XDG / homedir.

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
// Model rẻ, đã kiểm chứng chạy được — dùng để thử end-to-end.
const E2E_PREFERRED = "deepseek/deepseek-v4-flash";

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
  process.stdout.write("<đã nhập>\n");
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
  return /^(y|yes|có|co)$/i.test(a);
};

const fingerprint = (k) =>
  !k || k.length < 20 ? "<không hợp lệ>" : `${k.slice(0, 10)}…${k.slice(-6)}  (${k.length} ký tự)`;

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
  try { return readJsonFile(file); } catch { return null; } // null = hỏng
}

async function installWithConfirm(what, cmd) {
  say();
  warn(`Chưa cài ${what}.`);
  say(`      Lệnh sẽ chạy:  ${C.cyan}${cmd}${C.reset}`);
  if (!(await askYes("      Cài bây giờ? (Y/n) ", true))) {
    warn(`Bỏ qua cài ${what}.`);
    return false;
  }
  say("      Đang chạy (có thể mất vài phút)...");
  const r = tryRun(cmd, { stdio: "inherit" });
  return r.ok;
}

// ============================================================
// main
// ============================================================

async function main() {
  const t = { showFooter: false };

  say();
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);
  say(`${C.cyan}${C.bold}   COMMAND CODE  →  OPENCODE${C.reset}`);
  say(`${C.cyan}${C.bold}==================================================${C.reset}`);

  // ---------- 1. Dò môi trường ----------
  say();
  step("1/6", "Dò môi trường");

  ok(`Node ${process.version} đã có.`);

  let opencode = findTool(["opencode"]);
  opencode ? ok(`OpenCode ${opencode.version}`) : warn("Chưa cài OpenCode.");

  let cmdc = findTool(["cmdc", "command-code", "cmd"]);
  cmdc ? ok(`Command Code ${cmdc.version} (${cmdc.name})`) : warn("Chưa cài Command Code CLI.");

  const discoverConfigDir = () => {
    if (opencode) {
      const r = tryRun("opencode debug paths");
      if (r.ok) {
        const p = parseDebugPaths(r.out);
        if (p.config) return { dir: p.config, source: "opencode tự khai báo" };
      }
    }
    return { dir: resolveConfigDir({ env: process.env, homedir: os.homedir() }), source: "theo quy ước" };
  };

  let cfgInfo = discoverConfigDir();
  const configFileEarly = path.join(cfgInfo.dir, "opencode.json");
  let existing = readConfigIfAny(configFileEarly);

  if (existing === null) {
    say();
    bad(`${configFileEarly} không phải JSON hợp lệ.`);
    warn("Đã dừng để không làm hỏng file. Sửa file đó rồi chạy lại.");
    process.exit(1);
  }

  // ---------- 2. Đánh giá kết nối ----------
  say();
  step("2/6", "Kiểm tra OpenCode đã nối với Command Code chưa");

  const storedKey = existing?.providers?.cmd?.settings?.apiKey;
  let keyValid = null;
  if (storedKey) {
    try { await fetchModels(storedKey); keyValid = true; }
    catch { keyValid = false; }
  }

  let status = assessConnection(existing, keyValid);
  const STATUS_TEXT = {
    ready: "đã nối sẵn sàng",
    "not-configured": "chưa cấu hình",
    "key-invalid": "có cấu hình nhưng key không hợp lệ",
    "configured-unverified": "có cấu hình, chưa kiểm tra được (offline)",
  };

  if (existing?.providers?.cmd) ok(`providers.cmd có trong config (${Object.keys(existing.providers.cmd.models || {}).length} model).`);
  else warn(`providers.cmd chưa có trong config.`);
  say(`      Trạng thái: ${C.bold}${STATUS_TEXT[status]}${C.reset}`);

  // ---------- 3. Quyết định có cần key mới không ----------
  say();
  step("3/6", "Xác định việc cần làm");

  let key = null;
  let needConfig = false;

  if (status === "ready") {
    ok("OpenCode và Command Code đã nối với nhau — không cần cấu hình lại.");
    const rotate = await askYes("      Bạn có muốn ĐỔI key không? (y/N) ", false);
    if (rotate) { needConfig = true; }
    else {
      say();
      say(`${C.green}${C.bold}Không có gì phải làm. Bạn đã dùng được rồi.${C.reset}`);
      return;
    }
  } else {
    needConfig = true;
    if (status === "key-invalid") warn("Key đang lưu không dùng được — cần nhập key mới.");
    if (status === "configured-unverified") say("      Sẽ kiểm tra lại key khi có mạng.");
    if (status === "not-configured") say("      Cần cấu hình provider cho OpenCode.");
  }

  // ---------- 4. Cài nếu thiếu ----------
  say();
  step("4/6", "Kiểm tra cài đặt");

  if (!opencode) {
    if (!(await installWithConfirm("OpenCode", CMD_OPENCODE))) {
      bad("Thiếu OpenCode, không thể tiếp tục."); process.exit(1);
    }
    opencode = findTool(["opencode"]);
    if (!opencode) { bad("Cài xong nhưng không tìm thấy `opencode` trong PATH."); process.exit(1); }
    ok(`OpenCode ${opencode.version}`);
    cfgInfo = discoverConfigDir();
  } else ok("OpenCode đã có — bỏ qua cài đặt.");

  if (!cmdc) {
    if (await installWithConfirm("Command Code CLI", CMD_CMDC)) {
      cmdc = findTool(["cmdc", "command-code", "cmd"]);
      cmdc ? ok(`Command Code ${cmdc.version}`) : warn("Cài xong nhưng chưa thấy trong PATH (có thể cần mở lại terminal).");
    } else warn("Bỏ qua CLI — OpenCode vẫn dùng được.");
  } else ok("Command Code đã có — bỏ qua cài đặt.");

  // ---------- 5. Nhập key nếu cần ----------
  if (needConfig) {
    say();
    step("5/6", "Nhập API key");
    say(`${C.dim}      Lấy tại: ${KEY_PAGE}${C.reset}`);
    while (true) {
      key = (await askHidden("      Dán key rồi nhấn Enter: ")).trim();
      if (!key) { bad("Chưa nhập gì."); process.exit(1); }
      say(`      Key nhận được: ${C.yellow}${fingerprint(key)}${C.reset}`);
      if (await askYes("      Đúng chưa? (Y/n) ", true)) break;

      // Cho nhập lại nếu chưa đúng, trừ khi không phải terminal
      if (!isTTY()) { bad("Đã huỷ."); process.exit(0); }
      warn("Nhập lại.");
    }

    say();
    say("      Đang kiểm tra key với máy chủ Command Code...");
    try {
      const n = (await fetchModels(key)).length;
      ok(`Key hợp lệ — ${n} model.`);
      keyValid = true;
    } catch (e) {
      bad(`Key KHÔNG hợp lệ hoặc không kết nối được (${e.message}).`);
      warn("Đã dừng. KHÔNG ghi gì cả — setup hiện tại vẫn nguyên vẹn.");
      process.exit(1);
    }
  } else {
    say();
    step("5/6", "API key");
    ok("Giữ nguyên key đang có.");
    key = storedKey;
  }

  // ---------- 6. Ghi cấu hình ----------
  say();
  step("6/6", "Cấu hình");
  const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const configDir = cfgInfo.dir;
  const configFile = path.join(configDir, "opencode.json");
  const cliAuthFile = path.join(os.homedir(), ".commandcode", "auth.json");
  say(`${C.dim}      Config: ${configFile} (${cfgInfo.source})${C.reset}`);

  // 6a. CLI
  try {
    fs.mkdirSync(path.dirname(cliAuthFile), { recursive: true });
    if (fs.existsSync(cliAuthFile)) fs.copyFileSync(cliAuthFile, `${cliAuthFile}.bak-${stamp}`);
    const a = fs.existsSync(cliAuthFile) ? readJsonFile(cliAuthFile) : {};
    a.apiKey = key;
    writeAtomic(cliAuthFile, JSON.stringify(a, null, 2));
    ok(`CLI: đã ghi key.`);
  } catch (e) {
    warn(`Không ghi được phần CLI (${e.message}) — OpenCode vẫn tiếp tục.`);
  }

  // 6b. OpenCode
  fs.mkdirSync(configDir, { recursive: true });
  if (fs.existsSync(configFile)) {
    fs.copyFileSync(configFile, `${configFile}.bak-${stamp}`);
    ok(`Backup: ${path.basename(configFile)}.bak-${stamp}`);
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
    ? ok("providers.cmd đã có → chỉ đổi key, giữ nguyên danh sách model.")
    : ok(`providers.cmd đã tạo → ${openaiCapable.length} model.`);
  ok(`providers.cmd-claude → ${anthropicOnly.length} model.`);

  // ---------- Kiểm chứng ----------
  say();
  say(`${C.cyan}Kiểm chứng${C.reset}`);
  const after = readJsonFile(configFile);
  const keyOk = after.providers?.cmd?.settings?.apiKey === key
    && after.providers?.["cmd-claude"]?.settings?.apiKey === key;
  keyOk ? ok("Key khớp ở cả 2 provider.") : bad("Key ghi vào chưa khớp!");
  ok(`providers.cmd: ${Object.keys(after.providers?.cmd?.models || {}).length} model.`);
  const kept = ["plugins", "mcp", "agents"].filter((k) => after[k]);
  if (kept.length) ok(`Giữ nguyên: ${kept.join(", ")}.`);

  // Thử thật một request qua OpenCode
  const e2eModel = after.providers?.cmd?.models?.[E2E_PREFERRED]
    ? E2E_PREFERRED
    : Object.keys(after.providers?.cmd?.models || {})[0];
  if (e2eModel && opencode) {
    say("      Đang thử thật một request qua OpenCode...");
    const r = tryRun(`opencode run --model cmd/${e2eModel} "Reply with exactly: PONG"`);
    if (r.ok && /PONG/i.test(r.out)) ok(`Thử thật thành công (cmd/${e2eModel}).`);
    else warn(`Chưa thử được end-to-end (có thể cần mở lại OpenCode). ${r.out.split(/\r?\n/).slice(-1)[0] || ""}`);
  }

  t.showFooter = true;
  say();
  say(`${C.green}${C.bold}==================================================${C.reset}`);
  say(`${C.green}${C.bold}   XONG — ĐÃ NỐI XONG${C.reset}`);
  say(`${C.green}${C.bold}==================================================${C.reset}`);
  say(`  Config : ${configFile}`);
  say(`  Backup : ${fs.existsSync(`${configFile}.bak-${stamp}`) ? `${configFile}.bak-${stamp}` : "(chưa có, file mới)"}`);
  say();
  say(`  ${C.yellow}Mở lại OpenCode, rồi gõ /models để chọn model cmd/...${C.reset}`);
  say();
}

const isDirect = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isDirect) {
  main()
    .catch((e) => { console.error(`${C.red}Lỗi:${C.reset} ${e.message}`); process.exitCode = 1; })
    .finally(() => {
      // readline giữ event loop sống: không đóng thì Node treo, không bao giờ thoát.
      if (rlTTY) { try { rlTTY.close(); } catch { /* đã đóng */ } }
      // Lưới an toàn: nếu còn thứ gì khác giữ tiến trình sống, ép thoát.
      // unref() nên hẹn giờ này không tự giữ tiến trình sống.
      setTimeout(() => process.exit(process.exitCode ?? 0), 250).unref();
    });
}
