# opencode-commandcode-tools

**English** · **[Tiếng Việt](README.vi.md)**

One file that wires **Command Code** up as a provider for **OpenCode**.

---

## What it is

A single-file installer that configures Command Code as a provider for OpenCode.
It fetches the model list from the API, writes the provider config, and **preserves
everything else** in your OpenCode config (plugins, MCP servers, agents).

## Usage

Send **one file** — `Cai-CommandCode.cmd` — to the target machine. Nothing else needed.

| OS | How to run |
|---|---|
| **Windows** | Double-click it |
| **Linux / macOS** | `sh Cai-CommandCode.cmd` |

The first thing it asks is the language: **English or Vietnamese**.

If Node.js is missing, it asks before installing. If the install fails, it prints
manual instructions with a download link.

When it finishes, reopen OpenCode and type `/models` to pick a `cmd/...` model.

## One file, two operating systems

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
part. `sh` does not strip `\r`, so CRLF would corrupt variable values; `cmd.exe`
tracks its position in a batch file by byte, so CRLF is what it expects. The
`.gitattributes` marks the file `binary` so git never rewrites it.

**The batch block must stay pure ASCII.** Multi-byte UTF-8 characters in it make
`cmd.exe` mis-seek and run the sh block too. All batch messages are therefore
ASCII, and the language menu is the only place both languages appear.

## Security

**The file contains no API key.** It only *writes* a key to local config, never
*contains* one. Keys go to:

- `~/.commandcode/auth.json` — for the Command Code CLI
- `~/.config/opencode/opencode.json` → `providers.cmd.settings.apiKey` — for OpenCode

Before writing anything, the tool **validates the key against the Command Code
server**. A bad key stops it immediately with nothing written — there is no way to
lock yourself out of a working setup.

## What it does

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

## Development

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

## Known limitations

- **macOS has not been tested.** It ships bash 3.2 and BSD `sed`/`awk`/`tail`,
  which differ from GNU.
- **The "install Node succeeded, then continue" path has never actually run.**
  WSL1 cannot execute Node ≥18 (`Exec format error`) — a WSL1 limitation, not a
  bug in this tool.

## License

No license chosen. All rights reserved.
