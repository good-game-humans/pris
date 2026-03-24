#!/bin/bash
# Start QEMU VM for LFS build - direct kernel boot with serial console

PRIS_DIR="/Users/victor/Documents/pris"
BOOT_DIR="$PRIS_DIR/setup/local/arch-boot"
LOG_FILE="$PRIS_DIR/setup/local/build.log"

cat << 'EOF'
Starting QEMU with direct kernel boot...
Serial console enabled - output will appear below.
Login: root (no password)
---
EOF

exec qemu-system-x86_64 \
  -m 8G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/local/lfs.qcow2" \
  -cdrom "$PRIS_DIR/tools/Arch Linux/archlinux-x86_64.iso" \
  -kernel "$BOOT_DIR/vmlinuz-linux" \
  -initrd "$BOOT_DIR/initramfs-linux.img" \
  -append "console=ttyS0,115200 archisobasedir=arch archisolabel=ARCH_202602" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s]' | tee "$LOG_FILE"
