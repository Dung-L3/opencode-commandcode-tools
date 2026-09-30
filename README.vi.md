# opencode-commandcode-tools

**[English](README.md)** · **Tiếng Việt**

Một file để nối **Command Code** thành provider cho **OpenCode**.

---

## Đây là gì

Bộ cài một file, cấu hình Command Code thành provider cho OpenCode. Nó lấy danh sách
model từ API, ghi cấu hình provider, và **giữ nguyên mọi thứ khác** trong config
OpenCode của bạn (plugins, MCP servers, agents).

## Dùng

Gửi **một file** — `Cai-CommandCode.cmd` — sang máy đích. Không cần gì kèm theo.

| Hệ điều hành | Cách chạy |
|---|---|
| **Windows** | Nhấp đúp |
| **Linux / macOS** | `sh Cai-CommandCode.cmd` |

Việc đầu tiên nó hỏi là ngôn ngữ: **English hoặc Tiếng Việt**.

Nếu máy chưa có Node.js, nó hỏi trước khi cài. Nếu cài thất bại, nó in hướng dẫn
cài thủ công kèm link tải.

Xong rồi thì mở lại OpenCode và gõ `/models` để chọn model `cmd/...`.

## Một file, hai hệ điều hành

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

**Line ending cố ý trộn**: CRLF cho khối batch, LF cho phần sh. `sh` không tự cắt
`\r` nên CRLF sẽ làm hỏng giá trị biến; còn `cmd.exe` theo dõi vị trí trong file
batch theo byte nên CRLF mới là dạng nó chờ đợi. `.gitattributes` đánh dấu file là
`binary` để git không bao giờ ghi đè.

**Khối batch phải thuần ASCII.** Ký tự UTF-8 nhiều byte trong đó làm `cmd.exe`
tính sai vị trí và chạy lạc sang cả khối sh. Nên mọi thông báo trong batch đều là
ASCII, và menu chọn ngôn ngữ là chỗ duy nhất có cả hai thứ tiếng.

## An toàn

**Trong file không có API key.** Nó chỉ *ghi* key vào config cục bộ, không bao giờ
*chứa* key. Key được lưu vào:

- `~/.commandcode/auth.json` — cho Command Code CLI
- `~/.config/opencode/opencode.json` → `providers.cmd.settings.apiKey` — cho OpenCode

Trước khi ghi bất cứ thứ gì, công cụ **kiểm tra key với máy chủ Command Code**. Key
sai thì dừng ngay và không ghi gì — không có tình huống tự khoá mình khỏi setup đang
chạy tốt.

## Công cụ làm gì

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

## Phát triển

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

## Giới hạn đã biết

- **Chưa test trên macOS.** macOS dùng bash 3.2 và `sed`/`awk`/`tail` bản BSD, khác GNU.
- **Nhánh "cài Node thành công rồi chạy tiếp" chưa từng chạy thật.** WSL1 không chạy
  nổi Node ≥18 (`Exec format error`) — hạn chế của WSL1, không phải lỗi công cụ này.

## Giấy phép

Chưa chọn giấy phép. Mọi quyền được bảo lưu.
