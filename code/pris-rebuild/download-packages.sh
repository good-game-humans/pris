#!/bin/bash

WGET_LIST="$1"
MIRROR_LIST="$2"
MD5SUMS="$3"
DEST="${LFS}/sources"
FAILURES_LOG="$DEST/download-failures.log"

mkdir -p "$DEST"
> "$FAILURES_LOG"

download_file() {
    local url="$1"
    local filename="$2"

    if wget --timeout=30 --tries=2 --continue \
            --progress=bar --directory-prefix="$DEST" "$url"; then
        return 0
    fi

    echo "Primary failed for $filename, trying mirrors..."
    while IFS= read -r mirror; do
        [ -z "$mirror" ] && continue
        mirror_url="${mirror%/}/$filename"
        echo "  Trying: $mirror_url"
        if wget --timeout=30 --tries=1 --continue \
                --progress=bar --directory-prefix="$DEST" "$mirror_url"; then
            return 0
        fi
    done < "$MIRROR_LIST"

    return 1
}

check_md5() {
    local filename="$1"
    local expected_md5

    expected_md5=$(grep " $filename$" "$MD5SUMS" | awk '{print $1}')
    if [ -z "$expected_md5" ]; then
        echo "  WARNING: No md5sum entry found for $filename, skipping check"
        return 0
    fi

    actual_md5=$(md5sum "$DEST/$filename" | awk '{print $1}')
    if [ "$actual_md5" != "$expected_md5" ]; then
        echo "  MD5 MISMATCH for $filename"
        echo "    expected: $expected_md5"
        echo "    actual:   $actual_md5"
        rm -f "$DEST/$filename"
        return 1
    fi

    echo "  MD5 OK: $filename"
    return 0
}

while IFS= read -r url; do
    [ -z "$url" ] && continue
    filename=$(basename "$url")

    if [ -f "$DEST/$filename" ]; then
        echo "Already have $filename, verifying md5..."
        if check_md5 "$filename"; then
            continue
        fi
        echo "  Re-downloading $filename due to md5 failure..."
    fi

    echo "Downloading $filename..."
    if ! download_file "$url" "$filename"; then
        echo "FAILED to download: $filename" | tee -a "$FAILURES_LOG"
        continue
    fi

    if ! check_md5 "$filename"; then
        echo "FAILED md5 check: $filename" | tee -a "$FAILURES_LOG"
        exit 1
    fi

done < "$WGET_LIST"

echo "---"
if [ -s "$FAILURES_LOG" ]; then
    echo "Some downloads failed. See $FAILURES_LOG"
    exit 1
else
    echo "All packages downloaded and verified successfully."
fi
