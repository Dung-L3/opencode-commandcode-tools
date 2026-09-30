// main.mjs — điểm vào: chọn ngôn ngữ, định tuyến lệnh con.
//
// Chạy không tham số  -> install
// Có tham số          -> lệnh con tương ứng, hoặc trợ giúp

import {
  C, VERSION, ask, bad, banner, closeInput, detectLang, getLang, ok, registerMessages,
  say, setLang, t,
} from "./lib/shared.mjs";
import { pathToFileURL } from "node:url";

import { installCmd } from "./lib/install.mjs";
import { doctorCmd } from "./lib/doctor.mjs";
import { backupCmd } from "./lib/backup.mjs";
import { uninstallCmd } from "./lib/uninstall.mjs";
import { probeCmd } from "./lib/probe.mjs";
import { modelsCmd } from "./lib/models.mjs";

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
