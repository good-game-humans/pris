#!/bin/bash
# Start QEMU VM for pris, using local overlay over aws pris.qcow2
# Create overlay qcow2 file with:
#   qemu-img create -f qcow2 -b ../../setup/aws/pris.qcow2 -F qcow2 setup/local/pris-overlay.qcow2

PRIS_DIR="/Users/victor/Documents/pris"
BOOT_DIR="$PRIS_DIR/setup/aws/pris-boot"
LOG_FILE="/tmp/pris.log"
SCRIPTS_IMG="$PRIS_DIR/setup/local/pris-scripts.qcow2"

cat << 'EOF'
Starting QEMU with direct kernel boot...
Serial console enabled - output will appear below.
Login: root (no password)
---
EOF

exec qemu-system-x86_64 \
  -m 2560M \
  -smp 4 \
  -hda "$PRIS_DIR/setup/local/pris-overlay.qcow2" \
  -hdb "$SCRIPTS_IMG" \
  -kernel "$BOOT_DIR/vmlinuz-pris" \
  -append "root=/dev/sda1 rw console=ttyS0,115200" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s]' | tee "$LOG_FILE"
