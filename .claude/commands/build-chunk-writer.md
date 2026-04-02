Build pris-chunk-writer as a static Linux x86_64 binary (for deployment to EC2).

```bash
cd /Users/victor/Documents/pris/code/pris-chunk-writer && zig build -Dtarget=x86_64-linux-musl
```

Report success and remind the user to copy `zig-out/bin/pris-chunk-writer` to `~/pris/bin/` on the EC2 instance.
