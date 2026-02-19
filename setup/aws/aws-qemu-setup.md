# AWS QEMU Setup for LFS Build

## Overview
QEMU virtualized environment for building Linux From Scratch (LFS) on AWS EC2.
- Host: Ubuntu x86_64 EC2 instance
- Guest: Arch Linux (bootstrap environment)
- Output: Timestamped logs for pris-screen display

## Setup Steps

### 1. Install QEMU and dependencies
```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils moreutils p7zip-full
```
- **qemu-system-x86**: x86_64 emulator (runs native on x86_64 host)
- **qemu-utils**: provides qemu-img
- **moreutils**: provides `ts` for timestamps
- **p7zip-full**: for extracting kernel from ISO

### 2. Create working directory
```bash
mkdir -p ~/pris/setup/aws/arch-boot
mkdir -p ~/pris/tools
cd ~/pris
```

### 3. Download Arch Linux ISO
```bash
curl -L -o ~/pris/tools/archlinux-x86_64.iso \
  https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso
```

### 4. Create disk image for LFS build
```bash
qemu-img create -f qcow2 ~/pris/setup/aws/lfs.qcow2 50G
```

### 5. Extract kernel and initramfs from ISO
```bash
7z x -o/tmp/archiso ~/pris/tools/archlinux-x86_64.iso arch/boot/x86_64/vmlinuz-linux arch/boot/x86_64/initramfs-linux.img -y
cp /tmp/archiso/arch/boot/x86_64/vmlinuz-linux ~/pris/setup/aws/arch-boot/
cp /tmp/archiso/arch/boot/x86_64/initramfs-linux.img ~/pris/setup/aws/arch-boot/
```

Get the ISO label for boot parameters:
```bash
7z l ~/pris/tools/archlinux-x86_64.iso | grep -i label
# Or check the ISO filename for date (e.g., ARCH_202602)
```

### 6. Create start script
```bash
cat > ~/pris/setup/aws/start-qemu.sh << 'SCRIPT'
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
  -m 2G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/aws/lfs.qcow2" \
  -cdrom "$PRIS_DIR/tools/archlinux-x86_64.iso" \
  -kernel "$BOOT_DIR/vmlinuz-linux" \
  -initrd "$BOOT_DIR/initramfs-linux.img" \
  -append "console=ttyS0,115200 archisobasedir=arch archisolabel=$ARCH_LABEL" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s] ' | tee "$LOG_FILE"
SCRIPT
chmod +x ~/pris/setup/aws/start-qemu.sh
```

Key flags:
- `-m 2G`: 2GB RAM (limited by EC2 instance memory)
- `-smp 4`: 4 virtual CPUs
- `-kernel` / `-initrd`: Direct kernel boot (bypasses ISO bootloader)
- `-append "console=ttyS0,115200"`: Serial console output
- `-nic user,hostfwd=tcp::2222-:22`: User networking with SSH port forward
- `-serial stdio`: Connect serial to terminal
- `-display none`: No graphical display needed
- `ts | tee`: Timestamps and logs all output

**Note:** No `-enable-kvm` because standard EC2 instances don't support nested virtualization.


### 7. Boot the VM
```bash
~/pris/setup/aws/start-qemu.sh
```

Login: `root` (no password)

## Prepare LFS Build Environment

### Set up SSH access
```bash
passwd
```

SSH from another terminal:
```bash
ssh -p 2222 root@localhost
```

### Enlarge cowspace for package building
```bash
mount -o remount,size=2G /run/archiso/cowspace
```

### Install base packages
```bash
pacman -Sy
pacman -S base-devel
```

### Create and mount partitions
```bash
fdisk /dev/sda
# Create partitions:
# /dev/sda1 - 40G Linux (type 83)
# /dev/sda2 - 10G swap (type 82)

mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mount /dev/sda1 /mnt
```

## Output Capture for pris-screen

The build output is logged with timestamps in the format:
```
[pris SECONDS.MICROSECONDS] line of output
```

To chunk the log for pris-screen:
```bash
# TODO: Add chunking script
```

## Directory Structure
```
~/pris/
├── setup/
│   └── aws/
│       ├── arch-boot/
│       │   ├── vmlinuz-linux
│       │   └── initramfs-linux.img
│       ├── lfs.qcow2
│       ├── start-qemu.sh
│       ├── build.log
│       └── aws-qemu-setup.md
└── tools/
    └── archlinux-x86_64.iso
```

## Notes
- Same timestamp format as local setup for pris-screen compatibility
