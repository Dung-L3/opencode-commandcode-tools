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

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SRC = path.join(HERE, "setup-commandcode.mjs");
const OUT = path.join(HERE, "..", "Cai-CommandCode.cmd");
const MARKER = "#__PAYLOAD__";
const DL = "https://nodejs.org/en/download";

// Thông báo khi KHÔNG cài được Node tự động — dùng chung cho mọi nhánh thất bại
// để người dùng luôn nhận đúng một hướng dẫn.
const NOTIFY_BAT = [
  "echo.",
  "echo   ==================================================",
  "echo    KHONG CAI DUOC NODE TU DONG",
  "echo   ==================================================",
  "echo.",
  "echo    Cong cu nay can Node.js de chay.",
  "echo    Phan cai tu dong khong thanh cong.",
  "echo.",
  "echo    Hay cai Node THU CONG:",
  "echo.",
  "echo      1. Mo trang:  " + DL,
  "echo      2. Tai ban LTS cho he dieu hanh cua ban",
  "echo      3. Cai dat xong",
  "echo      4. Chay lai file nay",
  "echo.",
  "echo    Node cai xong la chay duoc, khong can cau hinh gi them.",
  "echo.",
].join("\n");

const NOTIFY_SH = [
  "echo",
  'echo "  =================================================="',
  'echo "   KHÔNG CÀI ĐƯỢC NODE TỰ ĐỘNG"',
  'echo "  =================================================="',
  "echo",
  'echo "   Công cụ này cần Node.js để chạy."',
  'echo "   Phần cài tự động không thành công."',
  "echo",
  'echo "   Hãy cài Node THỦ CÔNG:"',
  "echo",
  'echo "     1. Mở trang:  ' + DL + '"',
  'echo "     2. Tải bản LTS cho hệ điều hành của bạn"',
  'echo "     3. Cài đặt xong"',
  'echo "     4. Chạy lại file này"',
  "echo",
  'echo "   Node cài xong là chạy được, không cần cấu hình gì thêm."',
  "echo",
].join("\n");

// --- Khối Windows (cmd) ---
const BATCH = `@echo off
setlocal EnableDelayedExpansion
set "SELF=%~f0"
set "PAYLOAD=%TEMP%\\cmdcode-%RANDOM%-%RANDOM%.mjs"

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo   Node.js chua duoc cai tren may nay.
  echo.
  where winget >nul 2>nul
  if errorlevel 1 (
    echo   Khong tim thay winget tren may nay.
${NOTIFY_BAT}
    start "" "${DL}"
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
exit /b %RC%`;

// --- Khối Linux/macOS (sh) ---
const SH = `SELF="$0"
PAYLOAD="\${TMPDIR:-/tmp}/cmdcode-\$\$.mjs"

install_node() {
  if command -v brew >/dev/null 2>&1; then
    printf "  Cài Node.js bằng Homebrew bây giờ? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    brew install node || return 1
  elif command -v apt-get >/dev/null 2>&1; then
    printf "  Cài Node.js bằng apt (cần quyền sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo apt-get update && sudo apt-get install -y nodejs npm || return 1
  elif command -v dnf >/dev/null 2>&1; then
    printf "  Cài Node.js bằng dnf (cần quyền sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo dnf install -y nodejs || return 1
  elif command -v pacman >/dev/null 2>&1; then
    printf "  Cài Node.js bằng pacman (cần quyền sudo)? (Y/n) "
    read -r ans
    case "\${ans:-y}" in
      n|N|no|NO|No) echo "  Đã huỷ."; return 1 ;;
    esac
    sudo pacman -S --noconfirm nodejs npm || return 1
  else
    echo "  Không tìm thấy trình quản lý gói quen thuộc (brew/apt/dnf/pacman)."
    echo
    echo "  Hãy cài Node thủ công: ${DL}"
    return 1
  fi
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  echo
  echo "  Node.js chưa được cài trên máy này."
  echo

  if ! install_node; then
${NOTIFY_SH}
    exit 1
  fi

  # Cài xong nhưng chưa chắc đã có trong PATH của phiên hiện tại
  if ! command -v node >/dev/null 2>&1; then
${NOTIFY_SH}
    exit 1
  fi
  echo "  Node đã cài xong: $(node --version)"
fi

LINE="$(grep -n '^${MARKER}$' "$SELF" | tail -n 1 | cut -d: -f1)"
if [ -z "$LINE" ]; then
  echo
  echo "  Lỗi: không tách được phần JavaScript trong file này."
  exit 1
fi
awk -v m="${MARKER}" 'found{print} $0==m{found=1}' "$SELF" > "$PAYLOAD"

node "$PAYLOAD"
rc=$?
rm -f "$PAYLOAD"
exit "$rc"`;

const brain = fs.readFileSync(SRC, "utf8");

const out = [
  ": << 'BATCH_EOF'",
  BATCH,
  "BATCH_EOF",
  "",
  SH,
  "",
  MARKER,
  brain,
].join("\n");

// Bắt buộc LF
const lf = out.replace(/\r\n/g, "\n");
fs.writeFileSync(OUT, lf, "utf8");

const crlf = (lf.match(/\r\n/g) || []).length;
console.log(`Đã tạo: ${OUT}`);
console.log(`  kích thước : ${fs.statSync(OUT).size} bytes`);
console.log(`  dòng       : ${lf.split("\n").length}`);
console.log(`  CRLF       : ${crlf} (phải là 0)`);
console.log(`  marker     : ${(lf.match(new RegExp(`^${MARKER}$`, "gm")) || []).length} lần (phải là 1)`);
