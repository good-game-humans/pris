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
                 pris-chunk-writer  (Zig: chunks + periodic screen keyframes)
                          ↓
              data/pris-lines-NNNNNNNN.txt   (line chunks) + chunk-times.txt
              data/keyframe-NNNNNNNN.bin     (screen snapshots) + keyframes.txt
              data/manifest.json
                          ↓
              pris-screen (browser)
              ├─ main.ts            (TypeScript)
              └─ pris-screen.wasm   (Zig → WASM, terminal emulator)

  terminal.zig — the cursor/grid terminal core (ANSI parsing, the screen
  grid, keyframe serialize/load). Shared by the WASM renderer and
  pris-chunk-writer's keyframe writer so both produce identical state.
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
chunk files (`pris-lines-NNNNNNNN.txt`) + `chunk-times.txt` into a data
directory. Writes `-=END=-` sentinel on shutdown.

It also feeds every line through the shared `terminal.zig` core and writes a
**screen keyframe** every 5s of stream time (`keyframe-NNNNNNNN.bin` + a
`keyframes.txt` index, pruned to the last 12), so a fresh browser connection
can prime a full screen instead of starting blank. File I/O uses raw
`std.os.linux` syscalls (stable across the zig 0.16 `std.Io` rework).

Cross-compile for Linux (x86_64) from Mac — `-Dcols`/`-Drows` must match the
pris-screen build so keyframes are the right grid size:
```
cd code/pris-chunk-writer
zig build -Dtarget=x86_64-linux-musl -Dcols=92 -Drows=36
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

**WASM** (`wasm/src/main.zig` + `wasm/src/terminal.zig`): Zig compiled to WASM.
`terminal.zig` is the terminal core — interprets the control stream (`\r`,
`\n`, `ESC M`, `ESC[J/K/G`, `ESC(0` DEC charset, the `0x01` CR sentinel) into a
character grid, with a work grid plus a display grid that is only "presented"
at completed frames (no flicker on in-place redraws). `main.zig` adds the
rendering (glyphs from `font-{size}.zig`, RGBA pixels), the chunk ring buffer,
timing, and the exports. Build with `zig build -Dcols=92 -Drows=36 -Dfont-size=16`
inside `wasm/`.

**TypeScript** (`ts/src/main.ts`): Fetches chunks from `./data/`, passes
bytes to WASM, renders frames via `requestAnimationFrame`. In `realtime`
mode, applies `REALTIME_DELAY_MS = 5000` so playback trails live output by
5 seconds. On connect it primes the screen from the latest `keyframe-*.bin`
≤ now−5s (`loadKeyframe`), then replays only the delta forward. Build with
`npx tsc` inside `ts/`.

Manifest format (`pris-lines/manifest.json`):
```json
{"mode": "realtime", "startTime": <unix_ms>}
```

**Timing model**: `initTiming(startMs, durationMs, nowMs)` is called with
`nowMs = startTime + REALTIME_DELAY_MS` in realtime mode. The WASM shows a
line when `line_offset_ms <= Date.now() - run_start_epoch_ms`.

Regenerate font data (run on Mac, requires Pillow):
```
python3 code/util/rasterize_font.py 16 > code/pris-screen/wasm/src/font-16.zig
```

### `setup/aws/`
- `run-pris.sh` — main loop: cleans chunks/keyframes/markers, writes manifest,
  starts chunk-writer, runs QEMU, signals END, repeats
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
