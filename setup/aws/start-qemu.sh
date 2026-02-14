#!/bin/bash
# Start QEMU VM for LFS build - direct kernel boot with serial console

PRIS_DIR="$HOME/pris"
BOOT_DIR="$PRIS_DIR/setup/aws/arch-boot"
LOG_FILE="$PRIS_DIR/setup/aws/build.log"

# Update ARCH_YYYYMM to match downloaded ISO label
ARCH_LABEL="ARCH_202602"

cat << 'EOF'
Starting QEMU with direct kernel boot...
Serial console enabled - output will appear below.
Login: root (no password)
---
EOF

exec qemu-system-x86_64 \
  -enable-kvm \
  -m 8G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/aws/lfs.qcow2" \
  -cdrom "$PRIS_DIR/tools/archlinux-x86_64.iso" \
  -kernel "$BOOT_DIR/vmlinuz-linux" \
  -initrd "$BOOT_DIR/initramfs-linux.img" \
  -append "console=ttyS0,115200 archisobasedir=arch archisolabel=$ARCH_LABEL" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts -- '-=pr %.s is=-' | sed 's/is=- /is=-\
/' | tee "$LOG_FILE"
