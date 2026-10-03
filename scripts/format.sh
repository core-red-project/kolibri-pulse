#!/usr/bin/env bash
# ==============================================================================
# KolibriPulse - Source Code Formatter
# Pure POSIX / Bash implementation with zero external dependencies.
# ==============================================================================
set -e

FILES=$(find src scripts -type f \( -name "*.asm" -o -name "*.inc" -o -name "*.sh" \) 2>/dev/null; \
        ls Makefile Justfile Dockerfile build.sh 2>/dev/null || true)

COUNT=0

for f in $FILES; do
    [ -f "$f" ] || continue

    # Use portable awk to strip trailing whitespaces and ensure EOF newline
    TMP_FILE="${f}.tmp.$$"
    awk '{sub(/[ \t\r]+$/, ""); print}' "$f" > "$TMP_FILE"

    # Ensure newline at EOF
    if [ -s "$TMP_FILE" ] && [ "$(tail -c 1 "$TMP_FILE")" != "" ]; then
        printf "\n" >> "$TMP_FILE"
    fi

    if ! cmp -s "$f" "$TMP_FILE"; then
        mv "$TMP_FILE" "$f"
        echo "[*] Formatted: $f"
        COUNT=$((COUNT + 1))
    else
        rm -f "$TMP_FILE"
    fi
done

echo "[+] Formatting complete. $COUNT file(s) updated."
