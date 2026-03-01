# AWS QEMU Setup for LFS Build

## Overview
QEMU virtualized environment for building Linux From Scratch (LFS) on AWS EC2.
- Host: Ubuntu x86_64 EC2 instance
- Guest: Arch Linux (pre-installed, bootstrapped locally)
- Output: Timestamped logs for pris-screen display

**Note:** Arch Linux is bootstrapped locally (not on EC2) because EC2 instances lack
sufficient RAM and KVM support to run `pacstrap` reliably. The completed qcow2 image
is then transferred to EC2.

## Setup Steps

### 1. Install QEMU and dependencies
```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils moreutils
```
- **qemu-system-x86**: x86_64 emulator (runs native on x86_64 host)
- **qemu-utils**: provides `qemu-img` and `qemu-nbd`
- **moreutils**: provides `ts` for timestamps

### 2. Create working directory
```bash
mkdir -p ~/pris/setup/aws/arch-boot
cd ~/pris
```

### 3. Bootstrap Arch Linux locally

Arch Linux is installed onto the qcow2 image on the local Mac (8GB RAM, 50GB disk).
See `setup/local/local-qemu-setup.md` for the full local bootstrap process. Summary:

- Boot local QEMU with Arch live ISO
- Partition `/dev/sda`: 41G ext4 (`/dev/sda1`) + 9G swap (`/dev/sda2`)
- `pacstrap /mnt base linux linux-firmware grub openssh base-devel wget nano python`
- `genfstab`, `arch-chroot`, configure locale/hostname/sshd/GRUB
- Passwordless root: `passwd -d root`, permit empty passwords in sshd_config
- Serial console autologin via systemd getty override
- `grub-install --target=i386-pc /dev/sda && grub-mkconfig`
- Power off

### 4. Compress and transfer the qcow2

On the local Mac, compress the image (reduces ~50GB to ~2-5GB):
```bash
qemu-img convert -c -O qcow2 \
  setup/local/lfs.qcow2 \
  setup/local/lfs-compressed.qcow2
```

Transfer to EC2:
```bash
scp -i ~/.ssh/your-key.pem \
  setup/local/lfs-compressed.qcow2 \
  ubuntu@<EC2-IP>:~/pris/setup/aws/lfs.qcow2
```

### 5. Extract kernel and initramfs from installed qcow2

GRUB inside the qcow2 outputs to VGA only, which is not visible with `-display none`.
Instead, boot the installed kernel directly by extracting it via `qemu-nbd`:

```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd -c /dev/nbd0 ~/pris/setup/aws/lfs.qcow2
sleep 2
sudo mkdir -p /mnt/lfs
sudo mount /dev/nbd0p1 /mnt/lfs
sudo cp /mnt/lfs/boot/vmlinuz-linux ~/pris/setup/aws/arch-boot/
sudo cp /mnt/lfs/boot/initramfs-linux.img ~/pris/setup/aws/arch-boot/
sudo umount /mnt/lfs
sudo qemu-nbd -d /dev/nbd0
```

### 6. Boot the VM
```bash
~/pris/setup/aws/start-qemu.sh
```

The start script boots the installed kernel directly with `root=/dev/sda1 console=ttyS0`,
bypassing GRUB. Boot messages appear immediately on the serial console.

Login: automatic (autologin configured on ttyS0, no password required)

### 7. Set up SSH access

SSH from another terminal on EC2:
```bash
ssh -p 2222 root@localhost
```

(sshd is enabled and starts automatically at boot)

## Start Script

The start script (`setup/aws/start-qemu.sh`) uses direct kernel boot:

```bash
qemu-system-x86_64 \
  -m 2G \
  -smp 4 \
  -hda "$PRIS_DIR/setup/aws/lfs.qcow2" \
  -kernel "$BOOT_DIR/vmlinuz-linux" \
  -initrd "$BOOT_DIR/initramfs-linux.img" \
  -append "root=/dev/sda1 rw console=ttyS0,115200" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s] ' | tee "$LOG_FILE"
```

Key flags:
- `-kernel` / `-initrd`: Boot installed kernel directly (bypasses GRUB, enables serial console)
- `-append "root=/dev/sda1 rw console=ttyS0,115200"`: Mount installed root, serial output
- `-m 2G`: 2GB RAM (limited by EC2 instance memory)
- `-smp 4`: 4 virtual CPUs
- `-nic user,hostfwd=tcp::2222-:22`: SSH port forward
- `-serial stdio`: Connect serial to terminal
- `-display none`: No graphical display needed
- No `-enable-kvm`: standard EC2 instances don't support nested virtualization

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
│       │   ├── vmlinuz-linux       # Extracted from installed qcow2
│       │   └── initramfs-linux.img # Extracted from installed qcow2
│       ├── lfs.qcow2               # Installed Arch Linux (compressed qcow2)
│       ├── start-qemu.sh           # Boot script
│       ├── build.log               # Timestamped output log
│       └── aws-qemu-setup.md       # This file
```

## Notes
- EC2 root volume is 8GB — keep it clean, the qcow2 is the main storage
- qcow2 compression is transparent to QEMU; no decompression needed before use
- If the installed kernel is updated, re-extract vmlinuz-linux and initramfs-linux.img
- Use .metal EC2 instance types if KVM support is needed (faster emulation)
