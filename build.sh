#!/usr/bin/env bash
# ==============================================================================
# KolibriPulse Build Script
# ==============================================================================
set -e

SRC_DIR="src"
OUT_DIR="bin"
SRC_FILE="${SRC_DIR}/pulse.asm"
OUT_FILE="${OUT_DIR}/pulse.kex"

echo "=== Compiling KolibriPulse ==="

# Check for FASM locally
if command -v fasm &> /dev/null; then
    echo "[*] Using local 'fasm'..."
    mkdir -p "${OUT_DIR}"
    fasm "${SRC_FILE}" "${OUT_FILE}"
elif command -v docker &> /dev/null; then
    echo "[*] 'fasm' not found locally, but Docker is available."
    echo "[*] Building inside isolated container (linux/amd64)..."
    mkdir -p "${OUT_DIR}"
    docker run --rm --platform linux/amd64 -v "$PWD":/work -w /work debian:bookworm-slim \
        bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm ${SRC_FILE} ${OUT_FILE}"
else
    echo "[-] Error: Neither 'fasm' nor 'docker' were found in your PATH."
    echo ""
    echo "Options to compile on macOS:"
    echo "  1. If you use Docker: start Docker Desktop and rerun ./build.sh"
    echo "  2. Inside KolibriOS: FASM is pre-installed in /sys/fasm"
    echo "     Run: fasm src/pulse.asm bin/pulse.kex"
    echo "  3. Download FASM/FASMG from: https://flatassembler.net/download.php"
    echo ""
    exit 1
fi

if [ -f "${OUT_FILE}" ]; then
    SIZE=$(wc -c < "${OUT_FILE}" | tr -d ' ')
    echo "[+] Build Successful!"
    echo "    Binary: ${OUT_FILE}"
    echo "    Size:   ${SIZE} bytes"
else
    echo "[-] Build failed."
    exit 1
fi
