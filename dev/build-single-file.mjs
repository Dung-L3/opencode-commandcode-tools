// build-single-file.mjs — gộp não (.mjs) + bootstrap vào MỘT file polyglot.
//
//   node dev/build-single-file.mjs
//
// Kết quả: ../Cai-CommandCode.cmd — file duy nhất để gửi sang máy khác.
//
// Cách file polyglot hoạt động:
//   - sh (Linux/macOS): dòng đầu `: << 'BATCH_EOF'` là heredoc rỗng => bỏ qua
//     toàn bộ khối batch, rồi chạy tiếp phần sh.
//   - cmd (Windows): dòng đầu bắt đầu bằng ':' nên là label => bỏ qua, rồi
//     chạy thẳng khối batch bên dưới.
//   - Cả hai đều tự tách phần JavaScript ở cuối file ra file tạm rồi gọi node.
//
// Bắt buộc: file kết quả phải dùng LF. Nếu là CRLF, sh sẽ hỏng heredoc.
//
// Ngôn ngữ: bootstrap hỏi chọn Anh/Việt TRƯỚC TIÊN, rồi truyền lựa chọn cho
// não qua CMDCODE_LANG. Thông báo của chính bootstrap thì song ngữ luôn, để
// không phải rẽ nhánh trong batch — ít chỗ sai hơn.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { buildPayload } from "./bundle.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SRC = path.join(HERE, "setup-commandcode.mjs");
const OUT = path.join(HERE, "..", "Cai-CommandCode.cmd");
const MARKER = "#__PAYLOAD__";
const DL = "https://nodejs.org/en/download";

// Thông báo khi KHÔNG cài được Node — song ngữ, dùng chung mọi nhánh thất bại.
const NOTIFY_BAT = [
  "echo.",
  "echo   ==================================================",
  "echo    CANNOT INSTALL NODE AUTOMATICALLY",
  "echo    KHONG CAI DUOC NODE TU DONG",
  "echo   ==================================================",
  "echo.",
  "echo    Install Node manually / Hay cai Node THU CONG:",
  "echo.",
  "echo      1. " + DL,
  "echo      2. LTS build for your OS / ban LTS cho he dieu hanh cua ban",
  "echo      3. Install it / Cai dat xong",
  "echo      4. Run this file again / Chay lai file nay",
  "echo.",
  "echo    Node is all you need - no extra config.",
  "echo    Co Node la chay duoc, khong can cau hinh gi them.",
  "echo.",
].join("\n");

const NOTIFY_SH = [
  "echo",
  'echo "  =================================================="',
  'echo "   CANNOT INSTALL NODE AUTOMATICALLY"',
  'echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"',
  'echo "  =================================================="',
  "echo",
  'echo "   Install Node manually / Hãy cài Node THỦ CÔNG:"',
  "echo",
  'echo "     1. ' + DL + '"',
  'echo "     2. LTS build for your OS / bản LTS cho hệ điều hành của bạn"',
  'echo "     3. Install it / Cài đặt xong"',
  'echo "     4. Run this file again / Chạy lại file này"',
  "echo",
  'echo "   Node is all you need - no extra config."',
  'echo "   Có Node là chạy được, không cần cấu hình gì thêm."',
  "echo",
].join("\n");

// --- Khối Windows (cmd) ---
const BATCH = `@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
set "SELF=%~f0"
set "PAYLOAD=%TEMP%\\cmdcode-%RANDOM%-%RANDOM%.mjs"

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
rem dinh kem \r, so ca chuoi se truot.
if "!CMD_LANG:~0,1!"=="2" (set "CMDCODE_LANG=vi") else (set "CMDCODE_LANG=en")
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo   Node.js is not installed. / Node.js chua duoc cai tren may nay.
  echo.
  where winget >nul 2>nul
  if errorlevel 1 (
    echo   winget not found. / Khong tim thay winget.
${NOTIFY_BAT}
    start "" "${DL}"
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
  set "PATH=%ProgramFiles%\\nodejs;%PATH%"
)

where node >nul 2>nul
if errorlevel 1 (
${NOTIFY_BAT}
  pause
  exit /b 1
)

rem Tach phan JavaScript o cuoi file ra file tam (dung PowerShell cho chac)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='${MARKER}'; $t=[IO.File]::ReadAllText('%SELF%'); $i=$t.LastIndexOf($m); if($i -lt 0){ exit 1 }; [IO.File]::WriteAllText('%PAYLOAD%', $t.Substring($i + $m.Length).TrimStart(), (New-Object Text.UTF8Encoding $false))"
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
exit /b %RC%`;

// --- Khối Linux/macOS (sh) ---
const SH = `SELF="$0"
PAYLOAD="\${TMPDIR:-/tmp}/cmdcode-\$\$.mjs"

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
# Bo \r phong khi input bi pipe tu moi truong ghi CRLF
CHOICE=$(printf '%s' "$CHOICE" | tr -d '\r')
case "\${CHOICE:-1}" in
  2) CMDCODE_LANG=vi ;;
  *) CMDCODE_LANG=en ;;
esac
export CMDCODE_LANG
echo

install_node() {
  if command -v brew >/dev/null 2>&1; then
    printf "  Install Node.js with Homebrew? / Cài bằng Homebrew? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    brew install node || return 1
  elif command -v apt-get >/dev/null 2>&1; then
    printf "  Install Node.js with apt (needs sudo)? / Cài bằng apt (cần sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo apt-get update && sudo apt-get install -y nodejs npm || return 1
  elif command -v dnf >/dev/null 2>&1; then
    printf "  Install Node.js with dnf (needs sudo)? / Cài bằng dnf (cần sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo dnf install -y nodejs || return 1
  elif command -v pacman >/dev/null 2>&1; then
    printf "  Install Node.js with pacman (needs sudo)? / Cài bằng pacman (cần sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Cancelled. / Đã huỷ."; return 1 ;;
    esac
    sudo pacman -S --noconfirm nodejs npm || return 1
  else
    echo "  No known package manager. / Không tìm thấy trình quản lý gói quen thuộc."
    echo
    echo "  Install Node manually / Hãy cài Node thủ công: ${DL}"
    return 1
  fi
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  echo
  echo "  Node.js is not installed. / Node.js chưa được cài trên máy này."
  echo

  if ! install_node; then
${NOTIFY_SH}
    exit 1
  fi

  # Cai xong nhung chua chac da co trong PATH cua phien hien tai
  if ! command -v node >/dev/null 2>&1; then
${NOTIFY_SH}
    exit 1
  fi
  echo "  Node installed: $(node --version) / Node đã cài xong"
fi

LINE="$(grep -n '^${MARKER}$' "$SELF" | tail -n 1 | cut -d: -f1)"
if [ -z "$LINE" ]; then
  echo
  echo "  Cannot extract the JavaScript payload. / Không tách được phần JavaScript."
  exit 1
fi
awk -v m="${MARKER}" 'found{print} $0==m{found=1}' "$SELF" > "$PAYLOAD"

node "$PAYLOAD" "$@"
rc=$?
rm -f "$PAYLOAD"
exit "$rc"`;

const brain = buildPayload();

// LINE ENDING HỖN HỢP — cố ý:
//
//   Khối batch dùng CRLF. Dù đã xác minh bản LF hiện tại cũng chạy, CRLF mới là
//   dạng cmd.exe được thiết kế để đọc (nó theo dõi vị trí theo byte), và đây là
//   dạng đã chạy đúng khi mọi thứ khác đều hỏng — nên giữ cho chắc.
//
//   Phần sh dùng LF: sh không tự cắt \r, CRLF sẽ làm hỏng giá trị biến.
//   sh bỏ qua toàn bộ khối batch qua heredoc nên CRLF bên trong vô hại.
//
//   Dòng mở và dòng kết đều CRLF => với sh, delimiter là "BATCH_EOF\r" ở cả hai
//   đầu nên vẫn khớp.
//
//   .gitattributes đánh dấu file là `binary` để git lưu nguyên byte.
const BATCH_CRLF = BATCH.replace(/\r?\n/g, "\r\n");
const batchPart = [": << 'BATCH_EOF'", BATCH_CRLF, "BATCH_EOF"].join("\r\n") + "\r\n";
const shPart = [SH, "", MARKER, brain].join("\n").replace(/\r\n/g, "\n");
const out = batchPart + shPart;

fs.writeFileSync(OUT, out, "utf8");

const bytes = Buffer.from(out, "utf8");
let crlf = 0, lfOnly = 0;
for (let i = 0; i < bytes.length; i++) {
  if (bytes[i] === 10) { if (i > 0 && bytes[i - 1] === 13) crlf++; else lfOnly++; }
}
const batchBlock = out.slice(0, batchPart.length);
const nonAsciiInBatch = batchBlock.split("\n").filter((l) => /[^\x00-\x7F]/.test(l.replace(/\r$/, ""))).length;
const markerLines = (out.match(new RegExp(`^${MARKER}$`, "gm")) || []).length;
const shBody = out.slice(batchPart.length);
const crlfInSh = (shBody.match(/\r\n/g) || []).length;

console.log(`Đã tạo: ${OUT}`);
console.log(`  kích thước            : ${bytes.length} bytes`);
console.log(`  CRLF                  : ${crlf} (khối batch)`);
console.log(`  LF đơn                : ${lfOnly} (phần sh + payload)`);
console.log(`  CRLF trong phần sh    : ${crlfInSh} (phải là 0)`);
console.log(`  dòng batch ngoài ASCII: ${nonAsciiInBatch} (phải là 0)`);
console.log(`  marker                : ${markerLines} lần (phải là 1)`);
