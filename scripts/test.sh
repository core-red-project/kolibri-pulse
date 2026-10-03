#!/usr/bin/env bash
# ==============================================================================
# KolibriPulse - Binary Integrity Test (MENUET01 Format)
# Pure POSIX / Bash implementation with zero dependencies.
# ==============================================================================
set -e

TARGET="${1:-bin/pulse.kex}"

if [ ! -f "$TARGET" ]; then
    echo "[-] Error: Binary '$TARGET' not found. Run 'just build' first."
    exit 1
fi

# 1. Check File Size Budget (Max 8192 bytes)
FILE_SIZE=$(wc -c < "$TARGET" | tr -d ' ')
echo "[*] Testing binary: $TARGET ($FILE_SIZE bytes)"

if [ "$FILE_SIZE" -lt 32 ]; then
    echo "[-] Error: File size ($FILE_SIZE bytes) is too small to contain a MENUET01 header."
    exit 1
fi

if [ "$FILE_SIZE" -gt 8192 ]; then
    echo "[-] Error: Binary size exceeds budget of 8192 bytes."
    exit 1
fi
echo "  [+] Size budget passed ($FILE_SIZE / 8192 bytes)"

# 2. Check Magic Signature ('MENUET01', first 8 bytes)
MAGIC=$(dd if="$TARGET" bs=1 count=8 2>/dev/null)
if [ "$MAGIC" != "MENUET01" ]; then
    echo "[-] Error: Invalid signature '$MAGIC', expected 'MENUET01'."
    exit 1
fi
echo "  [+] Magic Signature: MENUET01 (Valid)"

# 3. Check Header Version (bytes 9-12 must be uint32 == 1)
VERSION=$(od -An -j 8 -N 4 -t u4 "$TARGET" | tr -d ' ')
if [ "$VERSION" != "1" ]; then
    echo "[-] Error: Unexpected header version '$VERSION', expected 1."
    exit 1
fi
echo "  [+] Header Version: $VERSION (Valid)"

# 4. Check Memory Layout (Entry Point, Image End, Memory Size)
ENTRY_POINT=$(od -An -j 12 -N 4 -t u4 "$TARGET" | tr -d ' ')
IMAGE_END=$(od -An -j 16 -N 4 -t u4 "$TARGET" | tr -d ' ')
MEM_SIZE=$(od -An -j 20 -N 4 -t u4 "$TARGET" | tr -d ' ')

if [ "$ENTRY_POINT" -ge "$IMAGE_END" ]; then
    echo "[-] Error: Entry point ($ENTRY_POINT) exceeds image end ($IMAGE_END)."
    exit 1
fi

if [ "$MEM_SIZE" -lt "$IMAGE_END" ]; then
    echo "[-] Error: Memory size ($MEM_SIZE) is smaller than image size ($IMAGE_END)."
    exit 1
fi

echo "  [+] Entry Point: 0x$(printf '%X' "$ENTRY_POINT")"
echo "  [+] Image End:   $IMAGE_END bytes"
echo "  [+] Memory Size: $MEM_SIZE bytes"
echo "[+] All binary integrity tests PASSED."
