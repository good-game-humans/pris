# pris

**pris** continually rebuilds itself, from open source software.  See the live display 
[here](http://161.178.136.162/pris/index.html).

This is a reprise of an artwork originally created for the Whitney Museum's 
[Artport](https://whitney.org/artport/) in 2004.  The idea is the same — a computer that 
rebuilds itself from downloaded source code, rests for a day, then reboots and repeats. 
This update also acknowledges changes in the tech landscape over the last 
20 years (the move to virtual machines in the cloud, the rise of new software, 
and the fall of others).


## How it works

```
QEMU virtual machine (running pris-rebuild scripts)
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

The serial console output from the virtual machine is captured, split into numbered chunk
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

## More

For more details, including instructions on building and running, see [CLAUDE.md](CLAUDE.md).

## Acknowledgements

- **Linux** — originally created by Linus Torvalds, and continued by many others
- **Open source software** — this project stands on the shoulders of the
  many open source projects and their contributors
- **Linux From Scratch** — created by Gerard Beekmans; an invaluable guide
  to building a Linux system from the ground up
- **San Francisco** — font by Apple
- **Claude Code** — for being the beast that it is
- **Whitney Museum of American Art** — commissioned the first version of
  this work

## License

MIT — see [LICENSE](LICENSE).
