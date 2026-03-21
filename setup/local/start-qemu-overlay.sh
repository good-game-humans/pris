#!/bin/bash
# Start an overlay QEMU VM for testing LFS build locally.
# Create overlay qcow2 file with:
#   qemu-img create -f qcow2 -b lfs.qcow2 -F qcow2 lfs-overlay.qcow2

PRIS_DIR="/Users/victor/Documents/pris"
BOOT_DIR="$PRIS_DIR/setup/aws/arch-boot"
LOG_FILE="$PRIS_DIR/setup/build.log"

cat << 'EOF'
Test LFS build locally
Login: root (no password)
---
EOF

exec qemu-system-x86_64 \
  -m 8G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/local/lfs-overlay.qcow2" \
  -kernel "$BOOT_DIR/vmlinuz-linux" \
  -initrd "$BOOT_DIR/initramfs-linux.img" \
  -append "root=/dev/sda1 rw console=ttyS0,115200" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s]' | tee "$LOG_FILE"
