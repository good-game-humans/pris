# pris

**pris** continually rebuilds itself, from open source software. See the live display 
[here](http://161.178.136.162/pris/index.html).

## How it works

```
QEMU VM (LFS build)
  └─ serial console → pris.log
                          ↓
                 pris-chunk-writer
                          ↓
              pris-lines/  (chunk files + chunk-times.txt + manifest.json)
                          ↓
              pris-screen (browser)
              ├─ main.ts   (TypeScript)
              └─ pris-screen.wasm  (Zig → WASM)
```

The serial console output from the VM is captured, split into numbered chunk
files, and served to the browser. The WASM-based renderer parses ANSI escape
codes and renders glyphs from an embedded bitmap font. In realtime mode,
playback trails live output by 5 seconds.

## Components

| Component | Language | Description |
|-----------|----------|-------------|
| `code/pris-chunk-writer` | Zig | Tails the QEMU log, writes numbered chunk files |
| `code/pris-screen/wasm` | Zig → WASM | Terminal renderer (ANSI parser, bitmap font, pixel output) |
| `code/pris-screen/ts` | TypeScript | Browser frontend, fetches chunks, drives the WASM |
| `code/pris-rebuild` | Bash | Automates the LFS build inside the QEMU guest |
| `setup/aws` | Bash | EC2 deployment scripts |

## Building

**pris-chunk-writer** (cross-compile for Linux from Mac):
```bash
cd code/pris-chunk-writer
zig build -Dtarget=x86_64-linux-musl
# output: zig-out/bin/pris-chunk-writer
```

**pris-screen WASM:**
```bash
cd code/pris-screen/wasm
zig build
```

**pris-screen TypeScript:**
```bash
cd code/pris-screen/ts
npx tsc
```

**Regenerate font data** (requires Pillow):
```bash
python3 code/util/rasterize_font.py > code/pris-screen/wasm/src/font.zig
```

## Running

See [`setup/aws/aws-qemu-setup.md`](setup/aws/aws-qemu-setup.md) for full
EC2 deployment instructions. The main entry point is `setup/aws/run-pris.sh`,
which cleans up chunk files, writes a manifest, starts `pris-chunk-writer`,
and launches QEMU in a loop.

## Credits

- **Linux** — created by Linus Torvalds
- **Open source software** — this project stands on the shoulders of the
  many open source projects and their contributors
- **Linux From Scratch** — created by Gerard Beekmans; an invaluable guide
  to building a Linux system from the ground up
- **San Francisco** — font by Apple
- **Whitney Museum of American Art** — commissioned the first version of
  this work

## License

MIT — see [LICENSE](LICENSE).
