#!/bin/bash
# run-pris.sh - Run the LFS build in a loop with automatic cleanup and restart.
# To stop after the current cycle, create a 'stop' file in the same directory.
# Run it in a tmux session `tmux new -s pris`.

PRIS_DIR="$HOME/pris"
LOG_FILE="$PRIS_DIR/run/pris.log"
CHUNKS_DIR="/var/www/html/pris/data" # Must match pris-screen DATA_PATH
CHUNK_WRITER="$PRIS_DIR/bin/pris-chunk-writer"
BOOT_DIR="$PRIS_DIR/setup/aws/pris-boot"
STOP_FILE="$PRIS_DIR/run/stop"
SCRIPTS_IMG="$PRIS_DIR/setup/aws/pris-scripts.qcow2"

mkdir -p "$PRIS_DIR/run"

while true; do

    # Check for stop signal before starting a new cycle
    if [ -f "$STOP_FILE" ]; then
        echo "Stop file found, exiting."
        rm -f "$STOP_FILE"
        break
    fi

    # --- Cleanup from previous run ---

    # Rotate log
    [ -f "$LOG_FILE" ] && mv "$LOG_FILE" "${LOG_FILE}.1"

    # Clear chunk files, manifest, and chunk-writer state
    mkdir -p "$CHUNKS_DIR"
    rm -f "$CHUNKS_DIR"/pris-lines-*.txt \
          "$CHUNKS_DIR"/pris-chunk-writer.state \
          "$CHUNKS_DIR"/chunk-times.txt \
          "$CHUNKS_DIR"/manifest.json

    # Clear build markers from pris-scripts disk
    sudo modprobe nbd max_part=8
    sudo qemu-nbd -c /dev/nbd0 "$SCRIPTS_IMG"
    sudo mkdir -p /mnt/pris-scripts-tmp
    sudo mount /dev/nbd0 /mnt/pris-scripts-tmp
    sudo rm -f /mnt/pris-scripts-tmp/markers/*
    sudo umount /mnt/pris-scripts-tmp
    sudo qemu-nbd -d /dev/nbd0

    # --- Write manifest ---
    START_MS=$(date +%s%3N)
    echo "{\"mode\":\"realtime\",\"startTime\":$START_MS}" \
        > "$CHUNKS_DIR/manifest.json"

    # --- Start chunk writer ---
    "$CHUNK_WRITER" "$LOG_FILE" "$CHUNKS_DIR" &
    CHUNK_PID=$!

    # --- Run QEMU ---
    qemu-system-x86_64 \
        -m 2560M \
        -smp 4 \
        -hda "$PRIS_DIR/setup/aws/pris-overlay.qcow2" \
        -hdb "$SCRIPTS_IMG" \
        -kernel "$BOOT_DIR/vmlinuz-pris" \
        -append "root=/dev/sda1 rw console=ttyS0,115200" \
        -nic user,hostfwd=tcp::2222-:22 \
        -serial stdio \
        -display none \
        2>&1 | ts '[pris %.s]' | tee "$LOG_FILE"

    # Signal chunk writer to flush and exit
    echo "-=END=-" >> "$LOG_FILE"
    wait $CHUNK_PID

    echo "Build cycle complete, restarting..."
done
