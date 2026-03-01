# Local QEMU Setup for LFS Build

## Overview
QEMU virtualized environment for bootstrapping Arch Linux locally on Mac (Apple Silicon),
producing a qcow2 image ready for LFS building on AWS EC2.

- Local machine: Mac (Apple Silicon), x86_64 emulated
- Target deployment: Amazon EC2 (x86_64)
- Purpose: EC2 lacks sufficient RAM and KVM to run `pacstrap` reliably, so Arch is
  installed locally and the completed image is transferred to EC2.

## Steps

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

### 3. Create disk image
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

### 5. Boot the live ISO
```bash
./setup/local/start-qemu.sh
```

Wait ~2 minutes for the Arch live environment to boot.

### 6. Set up SSH access

The live ISO has no root password and sshd runs automatically. SSH in from a second terminal:
```bash
ssh -p 2222 -o StrictHostKeyChecking=no root@localhost
```

### 7. Expand cowspace (via SSH)

The live ISO's writable overlay is small by default. Expand it so pacman has room:
```bash
mount -o remount,size=4G /run/archiso/cowspace
```

Verify:
```bash
df -h /run/archiso/cowspace
```

### 8. Partition and format the disk (via SSH)
```bash
parted /dev/sda --script mklabel msdos
parted /dev/sda --script mkpart primary ext4 1MiB 41GiB
parted /dev/sda --script mkpart primary linux-swap 41GiB 100%
parted /dev/sda --script set 1 boot on
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda1 /mnt
```

Resulting layout:
```
Device      Boot    Start       End  Sectors Size Type
/dev/sda1   *        2048  85983231 85981184  41G Linux
/dev/sda2        85983232 104857599 18874368   9G Linux swap
```

### 9. Bootstrap Arch Linux with pacstrap (via SSH)
```bash
pacman -Sy
pacstrap /mnt base linux linux-firmware grub openssh base-devel wget nano python
```

This takes several minutes.

### 10. Configure the installed system (via SSH)
```bash
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

Inside the chroot:
```bash
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "pris" > /etc/hostname
passwd -d root
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF
systemctl enable sshd
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
exit
```

### 11. Shut down cleanly
```bash
umount /mnt
poweroff
```

### 12. Compress the qcow2 for transfer

The 50GB qcow2 is mostly empty after a base install. Compress it to reduce transfer size:
```bash
qemu-img convert -c -O qcow2 \
  setup/local/lfs.qcow2 \
  setup/local/lfs-compressed.qcow2
```

A fresh Arch install compresses to ~2-5GB. QEMU can use the compressed qcow2 directly.

Transfer to EC2:
```bash
scp -i ~/.ssh/your-key.pem \
  setup/local/lfs-compressed.qcow2 \
  ubuntu@<EC2-IP>:~/pris/setup/aws/lfs.qcow2
```

See `setup/aws/aws-qemu-setup.md` for EC2 setup steps.

## Boot Script Details

The start script (`setup/local/start-qemu.sh`) boots the Arch live ISO with direct kernel boot:

```bash
qemu-system-x86_64 \
  -m 8G \
  -smp 4 \
  -hda setup/local/lfs.qcow2 \
  -cdrom "tools/Arch Linux/archlinux-x86_64.iso" \
  -kernel setup/local/arch-boot/vmlinuz-linux \
  -initrd setup/local/arch-boot/initramfs-linux.img \
  -append "console=ttyS0,115200 archisobasedir=arch archisolabel=ARCH_202602" \
  -nic user,hostfwd=tcp::2222-:22 \
  -serial stdio \
  -display none \
  2>&1 | ts '[pris %.s] ' | tee setup/local/build.log
```

Key flags:
- `-m 8G`: 8GB RAM — needed for pacstrap to complete reliably
- `-kernel` / `-initrd`: Boot live ISO kernel directly (bypasses ISO bootloader)
- `-append "console=ttyS0,115200"`: Serial console output
- `-nic user,hostfwd=tcp::2222-:22`: SSH port forward
- `-serial stdio`: Connect serial to terminal (interactive)
- `-display none`: No graphical display needed
- `ts | tee`: Timestamps and logs all output

## Directory Structure
```
setup/
├── local/
│   ├── arch-boot/
│   │   ├── vmlinuz-linux           # Extracted from live ISO (for booting installer)
│   │   └── initramfs-linux.img     # Extracted from live ISO
│   ├── lfs.qcow2                   # 50GB disk image (installed Arch)
│   ├── lfs-compressed.qcow2        # Compressed image for transfer to EC2
│   ├── start-qemu.sh               # Boot script (live ISO)
│   └── build.log                   # Timestamped output log
└── local-qemu-setup.md             # This file
tools/
└── Arch Linux/
    └── archlinux-x86_64.iso
```

## Notes
- Using x86_64 ISO to match EC2 target environment
- On Apple Silicon, x86_64 runs fully emulated (slower, but correct architecture)
- Boot takes ~2 minutes; pacstrap takes several more minutes
- GRUB is installed but EC2 boots using direct kernel boot (serial console visibility)
- If kernel is updated in the installed system, re-extract vmlinuz and initramfs on EC2
