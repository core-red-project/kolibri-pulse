#!/usr/bin/env bash
# ==============================================================================
# KolibriPulse - Source Code Hygiene & Linting
# Pure POSIX / Bash implementation with zero external dependencies.
# ==============================================================================
set -e

ERRORS=0

FILES=$(find src scripts -type f \( -name "*.asm" -o -name "*.inc" -o -name "*.sh" \) 2>/dev/null; \
        ls Makefile Justfile Dockerfile build.sh 2>/dev/null || true)

for f in $FILES; do
    [ -f "$f" ] || continue

    # Check for trailing whitespace
    if grep -q '[[:blank:]]$' "$f" 2>/dev/null; then
        echo "[-] Trailing whitespace found in: $f"
        grep -n '[[:blank:]]$' "$f" | head -n 3
        ERRORS=$((ERRORS + 1))
    fi

    # Check for missing newline at end of file
    if [ -s "$f" ] && [ "$(tail -c 1 "$f")" != "" ]; then
        echo "[-] Missing newline at end of file: $f"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ "$ERRORS" -gt 0 ]; then
    echo "[-] Lint check failed with $ERRORS issue(s). Run 'just format' or 'make format' to fix."
    exit 1
fi

echo "[+] Lint passed: all source files follow hygiene conventions."
