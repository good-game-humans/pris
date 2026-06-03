# pris

**pris** captures Linux From Scratch (LFS) builds running inside a QEMU VM
and replays them through a browser-based terminal renderer with a real-time
5-second delay.

## Architecture

```
QEMU VM (LFS build)
  └─ serial console
                          ↓
                 pris-crlf-filter   (Zig: \r\n→\n, bare \r→\n+0x01 sentinel)
                          ↓
                 ts → pris.log      (timestamps each line)
                          ↓
                 pris-chunk-writer  (Zig, static binary)
                          ↓
              pris-lines/pris-lines-NNNNNN.txt
              pris-lines/manifest.json
                          ↓
              pris-screen (browser)
              ├─ main.ts            (TypeScript)
              └─ pris-screen.wasm   (Zig → WASM, terminal emulator)
```

## Components

### `code/pris-rebuild/`
Shell scripts that automate the LFS build inside a QEMU guest:
- `pris-fns.sh` — helpers: `cmd`, `echo_cmd`, `marker_exists`, `place_marker`
- `pris-rebuild-a.sh` — root: filesystem setup, package downloads, chroot setup
- `pris-rebuild-b.sh` — lfs user: cross-toolchain build
- `pris-rebuild-c.sh` — chroot: toolchain build
- `pris-rebuild-d.sh` — chroot: final system packages

**Marker system:** `place_marker <name>` creates a file in `/pris/markers/`;
`marker_exists <name>` checks for it. Markers let scripts skip completed
steps on restart. `pris-scripts.qcow2` is mounted at `/pris` in the guest
and contains the scripts and `markers/` directory.

### `code/pris-chunk-writer/`
Zig executable (`src/main.zig`) that tails the QEMU log and writes numbered
chunk files (`pris-lines-NNNNNN.txt`) into a data directory. Writes
`-=END=-` sentinel on shutdown. Build with `zig build`.

Cross-compile for Linux (x86_64) from Mac:
```
cd code/pris-chunk-writer
zig build -Dtarget=x86_64-linux-musl
```
Output: `zig-out/bin/pris-chunk-writer` — copy to `~/pris/bin/` on EC2.

### `code/pris-crlf-filter/`
Zig executable (`src/main.zig`) in the `run-pris.sh` pipeline between QEMU and
`ts`. Byte-streams the serial output: collapses `\r\n` → `\n`, and turns a bare
carriage return into `\n` + a `0x01` sentinel. The newline lets `ts` timestamp
and stream each update (carriage-return-only progress like ninja/LLVM keeps
flowing); the sentinel tells pris-screen the break was a carriage return, so it
overwrites in place instead of scrolling. (`tr` could stream but is 1→1 and
can't emit the sentinel; `sed`/`perl` can emit it but buffer until a newline.)

Cross-compile for Linux (x86_64) from Mac:
```
cd code/pris-crlf-filter
zig build -Dtarget=x86_64-linux-musl
```
Output: `zig-out/bin/pris-crlf-filter` — copy to `~/pris/bin/` on EC2.

### `code/pris-screen/`
Browser-based terminal renderer.

**WASM** (`wasm/src/main.zig`): Zig compiled to WASM. Parses ANSI escape
codes, renders glyphs from embedded bitmap font (`font.zig`), writes RGBA
pixels into a shared memory buffer. Build with `zig build -Dcols=92 -Drows=36 -Dfont-size=16` inside `wasm/`.

**TypeScript** (`ts/src/main.ts`): Fetches chunks from `./data/`, passes
bytes to WASM, renders frames via `requestAnimationFrame`. In `realtime`
mode, applies `REALTIME_DELAY_MS = 5000` so playback trails live output by
5 seconds. Build with `npx tsc` inside `ts/`.

Manifest format (`pris-lines/manifest.json`):
```json
{"mode": "realtime", "startTime": <unix_ms>}
```

**Timing model**: `initTiming(startMs, durationMs, nowMs)` is called with
`nowMs = startTime + REALTIME_DELAY_MS` in realtime mode. The WASM shows a
line when `line_offset_ms <= Date.now() - run_start_epoch_ms`.

Regenerate font data (run on Mac, requires Pillow):
```
python3 code/util/rasterize_font.py > code/pris-screen/wasm/src/font.zig
```

### `setup/aws/`
- `run-pris.sh` — main loop: cleans chunks/markers, writes manifest, starts
  chunk-writer, runs QEMU, signals END, repeats
- `aws-qemu-setup.md` — full EC2 setup instructions
- `pris.qcow2` — main LFS disk (~3 GB, not in git)
- `pris-scripts.qcow2` — scripts + markers disk (100 MB ext4)

## Code Conventions

### Zig: 3+ parameter functions — one parameter per line
```zig
fn initTiming(
    start_ms: u64,
    duration_ms: u64,
    now_ms: u64,
) void { ... }
```

### General — 120-char line limit, exceptions where sensible

### Shell `cmd` blocks — 80-char line limit, use `\` continuations
```bash
cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /acl-2.3.2.tar.xz$ /pris/wget-list-sysv)'
```

## Edit Workflow
Present proposed file changes for approval before applying them.
