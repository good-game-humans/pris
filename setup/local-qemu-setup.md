# Local QEMU Setup for LFS Build

## Overview
QEMU virtualized environment for building Linux From Scratch (LFS).
- Local testing on Mac (Apple Silicon)
- Target deployment: Amazon EC2 (x86_64)

## Completed Steps

### 1. Download Arch Linux ISO
- **Location:** `tools/Arch Linux/archlinux-x86_64.iso`
- **Size:** 1.4GB
- **Architecture:** x86_64 (emulated on Apple Silicon, native on EC2)
- **Label:** ARCH_202602

### 2. Install QEMU and dependencies
```bash
brew install qemu moreutils p7zip
```
- **QEMU Version:** 10.2.0
- **moreutils:** provides `ts` for timestamps
- **p7zip:** for extracting kernel from ISO

### 3. Create disk image for LFS build
```bash
qemu-img create -f qcow2 setup/local/lfs.qcow2 50G
```
- **Location:** `setup/local/lfs.qcow2`
- **Size:** 50GB (qcow2 format, grows as needed)

### 4. Extract kernel and initramfs from ISO
```bash
mkdir -p setup/local/arch-boot
7z x -o/tmp/archiso "tools/Arch Linux/archlinux-x86_64.iso" arch/boot/x86_64/vmlinuz-linux arch/boot/x86_64/initramfs-linux.img -y
cp /tmp/archiso/arch/boot/x86_64/vmlinuz-linux setup/local/arch-boot/
cp /tmp/archiso/arch/boot/x86_64/initramfs-linux.img setup/local/arch-boot/
```

This enables direct kernel boot with serial console (no VNC required).

### 5. Boot the VM
```bash
./setup/local/start-qemu.sh
```

Login: `root` (no password)

## Boot Script Details

The start script (`setup/local/start-qemu.sh`) uses direct kernel boot:

```bash
qemu-system-x86_64 \
  -m 8G \
  -smp 4 \
  -hda setup/local/lfs.qcow2 \
  -cdrom "tools/Arch Linux/archlinux-x86_64.iso" \
  -kernel setup/local/arch-boot/vmlinuz-linux \
  -initrd setup/local/arch-boot/initramfs-linux.img \
  -append "console=ttyS0,115200 archisobasedir=arch archisolabel=ARCH_202602" \
  -serial stdio \
  -display none \
  2>&1 | ts '[%Y-%m-%d %H:%M:%.S]' | tee setup/local/build.log
```

Key flags:
- `-kernel` / `-initrd`: Boot kernel directly (bypasses ISO bootloader)
- `-append "console=ttyS0,115200"`: Serial console output
- `-serial stdio`: Connect serial to terminal (interactive)
- `-display none`: No graphical display needed
- `ts | tee`: Timestamps and logs all output

## Prepare LFS Build

# Set up ssh access
Set up the root password for ssh access:

```passwd```

Can now ssh from another terminal using:

```ssh -p 2222 root@localhost```

# Enlarge space available for building packages
```mount -o remount,size=2G /run/archiso/cowspace```

# Install some base packages
```pacman -Sy
pacman -S base-devel
```

# Create and mount partitions
Use `fdisk` to create 2 partitions, one for the LFS build, the other for swap.  Should look something like this when done:

```Device     Boot    Start       End  Sectors Size Id Type
/dev/sda1           2048  83888127 83886080  40G 83 Linux
/dev/sda2       83888128 104857599 20969472  10G 82 Linux swap / Solaris
```

```mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mount /dev/sda1 /mnt
```

## Directory Structure
```
setup/
├── local/
│   ├── arch-boot/
│   │   ├── vmlinuz-linux       # Extracted kernel
│   │   └── initramfs-linux.img # Extracted initramfs
│   ├── lfs.qcow2               # 20GB disk image
│   ├── start-qemu.sh           # Boot script
│   └── build.log               # Timestamped output log
└── local-qemu-setup.md         # This file
tools/
└── Arch Linux/
    └── archlinux-x86_64.iso
```

## Notes
- Using x86_64 ISO to match EC2 target environment
- Arch Linux chosen for up-to-date toolchain matching LFS version requirements
- On Apple Silicon, x86_64 runs emulated (slower but matches EC2)
- Direct kernel boot enables serial console without VNC
- Boot takes ~30 seconds, full systemd startup ~1-2 minutes (emulated)
