# opencode-commandcode-tools

**[English](#english) · [Tiếng Việt](#tiếng-việt)**

One file that wires **Command Code** up as a provider for **OpenCode**.
Một file để nối **Command Code** thành provider cho **OpenCode**.

---

<a id="english"></a>

## English

### What it is

A single-file installer that configures Command Code as a provider for OpenCode.
It fetches the model list from the API, writes the provider config, and **preserves
everything else** in your OpenCode config (plugins, MCP servers, agents).

### Usage

Send **one file** — `Cai-CommandCode.cmd` — to the target machine. Nothing else needed.

| OS | How to run |
|---|---|
| **Windows** | Double-click it |
| **Linux / macOS** | `sh Cai-CommandCode.cmd` |

The first thing it asks is the language: **English or Vietnamese**.

If Node.js is missing, it asks before installing. If the install fails, it prints
manual instructions with a download link.

When it finishes, reopen OpenCode and type `/models` to pick a `cmd/...` model.

### One file, two operating systems

The file is a **polyglot** — the same file, but each OS reads a different part.

The first line is:

```
: << 'BATCH_EOF'
```

- **sh** reads this as an empty heredoc → skips the whole batch block, runs the sh part
- **cmd** reads this as a label → skips the line, runs the batch block below

Each then extracts the JavaScript at the end of the file into a temp file and runs
`node` on it. The file contains, in order:

1. Windows bootstrap (batch)
2. Linux/macOS bootstrap (sh)
3. Marker `#__PAYLOAD__`
4. The JavaScript

**Line endings are deliberately mixed**: CRLF for the batch block, LF for the sh
part. `cmd.exe` reads batch files by byte offset and mis-seeks on a large LF-only
file with nested blocks — it ends up running the sh block too. `sh` is the opposite:
it does not strip `\r`, so CRLF would corrupt variable values. The
`.gitattributes` marks the file `binary` so git never rewrites it.

### Security

**The file contains no API key.** It only *writes* a key to local config, never
*contains* one. Keys go to:

- `~/.commandcode/auth.json` — for the Command Code CLI
- `~/.config/opencode/opencode.json` → `providers.cmd.settings.apiKey` — for OpenCode

Before writing anything, the tool **validates the key against the Command Code
server**. A bad key stops it immediately with nothing written — there is no way to
lock yourself out of a working setup.

### What it does

1. Detects the environment: Node, OpenCode, Command Code
2. Finds the config directory by **asking OpenCode itself** (`opencode debug paths`)
   — no hardcoded paths. Fallback: `$XDG_CONFIG_HOME` → `~/.config`
3. Checks whether OpenCode is already wired to Command Code:
   - no provider → configure it
   - provider but a broken key → ask for a new key
   - already working → offer to rotate the key
4. Missing OpenCode / Command Code → prints the command, asks, then installs
5. Fetches models from the API and splits them by route:
   - `/chat/completions` + `/responses` → provider `cmd` (openai-compatible)
   - `/messages` → provider `cmd-claude` (anthropic)
6. Writes config **atomically** (temp file then rename), with a timestamped backup
7. Verifies by running a real request through OpenCode

Step 7 matters: a config that *looks* valid can still be broken. Only a real request
catches that.

Idempotent by design: if the `cmd` provider already exists, it **only updates the
key** and leaves the model list alone.

### Development

The source lives in `dev/`. `Cai-CommandCode.cmd` at the root is **generated** — do
not edit it by hand.

```bash
cd dev
node --test setup-commandcode.test.mjs    # 29 tests
node build-single-file.mjs                # regenerate ../Cai-CommandCode.cmd
```

Change the logic in `dev/setup-commandcode.mjs`, then run `build-single-file.mjs` to
regenerate the polyglot. Skipping the build means your change never reaches the
released file.

Translations live in the `M` object at the top of `setup-commandcode.mjs` — both
`en` and `vi` must have the same keys.

### Known limitations

- **macOS has not been tested.** It ships bash 3.2 and BSD `sed`/`awk`/`tail`,
  which differ from GNU.
- **The "install Node succeeded, then continue" path has never actually run.**
  WSL1 cannot execute Node ≥18 (`Exec format error`) — a WSL1 limitation, not a
  bug in this tool.

### License

No license chosen. All rights reserved.

---

<a id="tiếng-việt"></a>

## Tiếng Việt

### Đây là gì

Bộ cài một file, cấu hình Command Code thành provider cho OpenCode. Nó lấy danh sách
model từ API, ghi cấu hình provider, và **giữ nguyên mọi thứ khác** trong config
OpenCode của bạn (plugins, MCP servers, agents).

### Dùng

Gửi **một file** — `Cai-CommandCode.cmd` — sang máy đích. Không cần gì kèm theo.

| Hệ điều hành | Cách chạy |
|---|---|
| **Windows** | Nhấp đúp |
| **Linux / macOS** | `sh Cai-CommandCode.cmd` |

Việc đầu tiên nó hỏi là ngôn ngữ: **English hoặc Tiếng Việt**.

Nếu máy chưa có Node.js, nó hỏi trước khi cài. Nếu cài thất bại, nó in hướng dẫn
cài thủ công kèm link tải.

Xong rồi thì mở lại OpenCode và gõ `/models` để chọn model `cmd/...`.

### Một file, hai hệ điều hành

File này là **polyglot** — cùng một file, mỗi hệ điều hành đọc một phần khác nhau.

Dòng đầu tiên:

```
: << 'BATCH_EOF'
```

- **sh** hiểu là heredoc rỗng → bỏ qua toàn bộ khối batch, chạy tiếp phần sh
- **cmd** hiểu là label → bỏ qua dòng đó, chạy thẳng khối batch bên dưới

Cả hai sau đó tách phần JavaScript ở cuối file ra file tạm rồi gọi `node`. Cấu trúc
file, theo thứ tự:

1. Bootstrap Windows (batch)
2. Bootstrap Linux/macOS (sh)
3. Marker `#__PAYLOAD__`
4. Toàn bộ JavaScript

**Line ending cố ý trộn**: CRLF cho khối batch, LF cho phần sh. `cmd.exe` đọc file
batch theo byte offset và tính sai dòng khi file LF thuần đủ lớn có khối lồng nhau —
nó chạy lạc sang cả khối sh. `sh` thì ngược lại: không tự cắt `\r`, nên CRLF sẽ làm
hỏng giá trị biến. `.gitattributes` đánh dấu file là `binary` để git không bao giờ
ghi đè.

### An toàn

**Trong file không có API key.** Nó chỉ *ghi* key vào config cục bộ, không bao giờ
*chứa* key. Key được lưu vào:

- `~/.commandcode/auth.json` — cho Command Code CLI
- `~/.config/opencode/opencode.json` → `providers.cmd.settings.apiKey` — cho OpenCode

Trước khi ghi bất cứ thứ gì, công cụ **kiểm tra key với máy chủ Command Code**. Key
sai thì dừng ngay và không ghi gì — không có tình huống tự khoá mình khỏi setup đang
chạy tốt.

### Công cụ làm gì

1. Dò môi trường: Node, OpenCode, Command Code
2. Tìm thư mục config bằng cách **hỏi chính OpenCode** (`opencode debug paths`) —
   không hardcode đường dẫn. Dự phòng: `$XDG_CONFIG_HOME` → `~/.config`
3. Kiểm tra xem OpenCode đã nối với Command Code chưa:
   - chưa có provider → cấu hình
   - có provider nhưng key hỏng → đòi key mới
   - đã nối sẵn sàng → hỏi có muốn đổi key không
4. Thiếu OpenCode / Command Code → in lệnh, hỏi xác nhận, rồi cài
5. Lấy danh sách model từ API, chia theo route:
   - `/chat/completions` + `/responses` → provider `cmd` (openai-compatible)
   - `/messages` → provider `cmd-claude` (anthropic)
6. Ghi config **nguyên tử** (file tạm rồi rename), có backup kèm timestamp
7. Kiểm chứng bằng cách chạy thật một request qua OpenCode

Bước 7 quan trọng: config trông hợp lệ vẫn có thể hỏng thật. Chỉ request thật mới bắt
được.

Idempotent: nếu provider `cmd` đã tồn tại thì **chỉ đổi key**, giữ nguyên danh sách
model.

### Phát triển

Nguồn nằm trong `dev/`. File `Cai-CommandCode.cmd` ở gốc là **file sinh ra**, không
sửa tay.

```bash
cd dev
node --test setup-commandcode.test.mjs    # 29 test
node build-single-file.mjs                # sinh lại ../Cai-CommandCode.cmd
```

Sửa logic trong `dev/setup-commandcode.mjs`, rồi chạy `build-single-file.mjs` để sinh
lại file polyglot. Không chạy build thì thay đổi không vào file phát hành.

Bản dịch nằm trong object `M` ở đầu `setup-commandcode.mjs` — cả `en` và `vi` phải có
đủ cùng số khoá.

### Giới hạn đã biết

- **Chưa test trên macOS.** macOS dùng bash 3.2 và `sed`/`awk`/`tail` bản BSD, khác GNU.
- **Nhánh "cài Node thành công rồi chạy tiếp" chưa từng chạy thật.** WSL1 không chạy
  nổi Node ≥18 (`Exec format error`) — hạn chế của WSL1, không phải lỗi công cụ này.

### Giấy phép

Chưa chọn giấy phép. Mọi quyền được bảo lưu.
