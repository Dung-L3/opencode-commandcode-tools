// bundle.mjs — gộp các module trong dev/ thành MỘT đoạn JavaScript duy nhất.
//
//   node dev/bundle.mjs            # kiểm tra, in thống kê
//
// Vì sao cần: file polyglot phát hành chỉ chứa một đoạn JS, chạy từ file tạm
// nằm một mình trong thư mục tạm — nên `import "./shared.mjs"` sẽ không giải
// được. Phải gộp phẳng.
//
// Cách gộp (cố tình đơn giản để dễ kiểm chứng):
//   1. Bỏ mọi dòng `import ...` (bundler tự chèn phần import của Node ở đầu)
//   2. Bỏ tiền tố `export ` (giữ nguyên tên, để test trực tiếp vẫn chạy)
//   3. Nối theo thứ tự cố định
//
// Vì gộp phẳng nên TÊN Ở CẤP CAO NHẤT PHẢI DUY NHẤT giữa các module.
// Hàm buildPayload() kiểm tra điều đó và ném lỗi nếu vi phạm.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { execFileSync } from "node:child_process";

export const HERE = path.dirname(fileURLToPath(import.meta.url));

// Thứ tự quan trọng: shared trước, main cuối.
export const ORDER = [
  "lib/shared.mjs",
  "lib/install.mjs",
  "lib/doctor.mjs",
  "lib/backup.mjs",
  "lib/uninstall.mjs",
  "lib/probe.mjs",
  "lib/models.mjs",
  "main.mjs",
];

const IMPORT_HEADER = `import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execSync } from "node:child_process";
import { pathToFileURL } from "node:url";`;

/** Bỏ câu import (kể cả nhiều dòng) và tiền tố export. */
function stripModule(src) {
  return src
    // import ... ;  — có thể trải nhiều dòng, nên phải bắt tới dấu ; đầu tiên
    .replace(/^import\b[\s\S]*?;[ \t]*\r?\n/gm, "")
    .replace(/^[ \t]*import\b[^\n]*\r?\n/gm, "")
    .replace(/^export\s+/gm, "");
}

/** Tên khai báo ở cấp cao nhất (cột 0) — dùng để phát hiện trùng. */
function topLevelNames(src) {
  const names = [];
  const re = /^(?:const|let|var|function|class)\s+([A-Za-z_$][\w$]*)/gm;
  let m;
  while ((m = re.exec(src))) names.push(m[1]);
  return names;
}

export function buildPayload() {
  const parts = [];
  const seen = new Map(); // tên -> module khai báo
  const collisions = [];

  for (const rel of ORDER) {
    const full = path.join(HERE, rel);
    if (!fs.existsSync(full)) {
      throw new Error(`Thiếu module: ${rel}`);
    }
    const raw = fs.readFileSync(full, "utf8");
    const body = stripModule(raw);

    for (const name of topLevelNames(body)) {
      if (seen.has(name)) collisions.push(`${name}  (${seen.get(name)} và ${rel})`);
      else seen.set(name, rel);
    }

    parts.push(`// ---------- ${rel} ----------\n${body.trim()}\n`);
  }

  if (collisions.length) {
    throw new Error(
      `Trùng tên ở cấp cao nhất giữa các module (gộp phẳng sẽ hỏng):\n  ` +
      collisions.join("\n  ")
    );
  }

  return `${IMPORT_HEADER}\n\n${parts.join("\n")}`;
}

/** Kiểm tra cú pháp đoạn đã gộp bằng chính Node. */
export function checkSyntax(code) {
  const tmp = path.join(HERE, ".payload-check.mjs");
  fs.writeFileSync(tmp, code, "utf8");
  try {
    execFileSync(process.execPath, ["--check", tmp], { stdio: "pipe" });
    return { ok: true };
  } catch (e) {
    return { ok: false, err: String(e.stderr || e.message) };
  } finally {
    fs.rmSync(tmp, { force: true });
  }
}

const isDirect = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isDirect) {
  try {
    const code = buildPayload();
    const lines = code.split("\n").length;
    console.log(`Đã gộp ${ORDER.length} module:`);
    for (const r of ORDER) console.log(`  ${r}`);
    console.log(`  -> ${code.length} bytes, ${lines} dòng`);

    const chk = checkSyntax(code);
    if (!chk.ok) {
      console.error(`\nLỖI CÚ PHÁP:\n${chk.err}`);
      process.exit(1);
    }
    console.log("  cú pháp: OK");
  } catch (e) {
    console.error(`LỖI: ${e.message}`);
    process.exit(1);
  }
}
