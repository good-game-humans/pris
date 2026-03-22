#!/bin/bash
# Start QEMU VM - boots LFS system from pris.qcow2
# Note: No -enable-kvm because standard EC2 instances don't support nested virtualization
# Use .metal instance types for KVM support

PRIS_DIR="$HOME/pris"
LOG_FILE="$PRIS_DIR/setup/aws/pris.log"
BOOT_DIR="$PRIS_DIR/setup/aws/pris-boot"

cat << 'EOF'
Starting QEMU with installed Arch Linux kernel...
Serial console enabled - output will appear below.
Login: root (password set during install)
---
EOF

exec qemu-system-x86_64 \
  -m 2G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/aws/pris.qcow2" \
  -hdb "$PRIS_DIR/setup/aws/pris-scripts.qcow2" \
  -kernel "$BOOT_DIR/vmlinuz-pris" \
  -append "root=/dev/sda1 rw console=ttyS0,115200" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s] ' | tee "$LOG_FILE"
