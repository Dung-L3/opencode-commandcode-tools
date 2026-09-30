# opencode-commandcode-tools

Bộ cài **Command Code → OpenCode**, chỉ gồm **một file duy nhất** để gửi sang máy khác.

Công cụ tự phát hiện và cấu hình provider Command Code cho OpenCode: lấy danh sách model
từ API, ghi vào `opencode.json` của OpenCode, giữ nguyên mọi thứ khác (plugins, MCP, agents).

---

## Dùng

Gửi **một file** `Cai-CommandCode.cmd` sang máy đích. Không cần gửi gì kèm theo.

| Hệ điều hành | Cách chạy |
|---|---|
| **Windows** | Nhấp đúp |
| **Linux / macOS** | `sh Cai-CommandCode.cmd` |

Nếu máy chưa có Node.js, công cụ sẽ hỏi trước khi tự cài. Nếu cài không được, nó in
hướng dẫn cài thủ công kèm link tải.

Sau khi xong, mở lại OpenCode rồi gõ `/models` để chọn model `cmd/...`.

---

## Một file chạy được cả hai hệ điều hành?

File này là **polyglot** — cùng một file, mỗi hệ điều hành đọc một phần khác nhau.

Dòng đầu tiên:

```
: << 'BATCH_EOF'
```

- **sh** hiểu là heredoc rỗng → bỏ qua toàn bộ khối batch, chạy tiếp phần sh
- **cmd** hiểu là label → bỏ qua dòng đó, chạy thẳng khối batch

Cả hai sau đó tự tách phần JavaScript ở cuối file ra file tạm rồi gọi `node`.

Cấu trúc file, theo thứ tự:

1. Khối bootstrap Windows (batch)
2. Khối bootstrap Linux/macOS (sh)
3. Marker `#__PAYLOAD__`
4. Toàn bộ JavaScript

Bắt buộc: file phải dùng **LF**. Nếu là CRLF, sh sẽ hỏng heredoc.

---

## An toàn

**Trong file không có API key.** Công cụ chỉ *ghi* key vào config của máy, không *chứa* key.

Key được lưu vào:

- `~/.commandcode/auth.json` — cho Command Code CLI
- `~/.config/opencode/opencode.json` → `providers.cmd.settings.apiKey` — cho OpenCode

Cả hai đều là file cục bộ, không thuộc repo này.

Trước khi ghi bất cứ thứ gì, công cụ **kiểm tra key với máy chủ Command Code**. Key sai thì
dừng ngay và không ghi gì — không có tình huống tự khoá mình khỏi setup đang chạy tốt.

---

## Công cụ làm gì

1. Dò môi trường: Node, OpenCode, Command Code
2. Xác định thư mục config bằng cách **hỏi chính OpenCode** (`opencode debug paths`),
   không hardcode đường dẫn. Dự phòng: `$XDG_CONFIG_HOME` → `~/.config`
3. Kiểm tra xem OpenCode đã nối với Command Code chưa:
   - chưa có provider → cấu hình
   - có provider nhưng key hỏng → đòi key mới
   - đã nối sẵn sàng → hỏi có muốn đổi key không
4. Thiếu OpenCode / Command Code → in lệnh, hỏi xác nhận, rồi cài
5. Lấy danh sách model từ API, chia theo route:
   - `/chat/completions` + `/responses` → provider `cmd` (package openai-compatible)
   - `/messages` → provider `cmd-claude` (package anthropic)
6. Ghi config **nguyên tử** (file tạm rồi rename), có backup kèm timestamp
7. Kiểm chứng: chạy thử một request thật qua OpenCode

Bước 7 quan trọng — config trông hợp lệ vẫn có thể hỏng thật. Chỉ request thật mới bắt được.

Quy tắc idempotent: nếu provider `cmd` đã tồn tại thì **chỉ đổi key**, giữ nguyên danh sách model.

---

## Phát triển

Nguồn nằm trong `dev/`. File `Cai-CommandCode.cmd` ở gốc là **file sinh ra**, không sửa tay.

```bash
cd dev
node --test setup-commandcode.test.mjs    # 22 test
node build-single-file.mjs                # sinh lại ../Cai-CommandCode.cmd
```

Sửa logic thì sửa `dev/setup-commandcode.mjs`, rồi chạy `build-single-file.mjs` để sinh lại
file polyglot. Nếu không chạy build, thay đổi sẽ không vào file phát hành.

### Vì sao cần bước build

JavaScript phải nằm trong file polyglot, mà file polyglot phải có LF và đúng cấu trúc.
Build script lo việc gộp và kiểm tra (CRLF = 0, marker xuất hiện đúng 1 lần).

### Giới hạn đã biết

- Chưa test được trên **macOS thật** (dùng bash 3.2 và `sed`/`awk`/`tail` bản BSD, khác GNU)
- Nhánh **cài Node thành công rồi chạy tiếp** chưa chạy thật lần nào
  (WSL1 không chạy nổi Node ≥18 — `Exec format error`, là hạn chế của WSL1)

---

## Giấy phép

Chưa chọn giấy phép. Mọi quyền được bảo lưu.

---

## English summary

A single-file installer that wires **Command Code** up as a provider for **OpenCode**.

One file, `Cai-CommandCode.cmd`, runs on both Windows (double-click) and Linux/macOS (`sh`).
It detects whether Node.js, OpenCode and Command Code are present, installs what is missing
after asking, discovers OpenCode's config directory by asking OpenCode itself (no hardcoded
paths), then writes the provider config while preserving everything else.

No API key is contained in the file — it is only ever written to local config. A real request
is run at the end to verify the wiring actually works, because a config that *looks* valid can
still be broken.
