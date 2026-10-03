# ==============================================================================
# KolibriPulse - Task Runner Interface
# Pure POSIX / Bash tooling with zero external runtime dependencies.
# ==============================================================================

# Default target
default:
    @just --list

# Bootstrap and verify assembly toolchain
install:
    @if command -v fasm >/dev/null 2>&1; then \
        echo "[+] Local 'fasm' detected: $(fasm | head -n 1)"; \
    elif command -v docker >/dev/null 2>&1; then \
        echo "[*] Local fasm not found. Pulling Docker amd64 build container..."; \
        docker pull --platform linux/amd64 debian:bookworm-slim; \
        echo "[+] Docker build container ready."; \
    else \
        echo "[-] Error: Neither 'fasm' nor 'docker' found in PATH."; exit 1; \
    fi

# Fast local recompile / development build
dev: build

# Assemble native KolibriOS binary (pulse.kex)
build:
    @mkdir -p bin
    @if command -v fasm >/dev/null 2>&1; then \
        echo "[*] Assembling with local FASM..."; \
        fasm src/pulse.asm bin/pulse.kex; \
    elif command -v docker >/dev/null 2>&1; then \
        echo "[*] Assembling via Docker (linux/amd64)..."; \
        docker run --rm --platform linux/amd64 -v "$$(pwd)":/work -w /work debian:bookworm-slim \
            bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm src/pulse.asm bin/pulse.kex"; \
    else \
        echo "[-] Error: 'fasm' or 'docker' required to build."; exit 1; \
    fi
    @echo "[+] Build complete. Output: bin/pulse.kex ($$(wc -c < bin/pulse.kex | tr -d ' ') bytes)"

# Verify static correctness and symbol resolution (FASM assembly pass)
typecheck:
    @echo "[*] Running static correctness verification pass..."
    @if command -v fasm >/dev/null 2>&1; then \
        fasm src/pulse.asm /dev/null >/dev/null && echo "[+] Syntax and symbol resolution check passed."; \
    elif command -v docker >/dev/null 2>&1; then \
        docker run --rm --platform linux/amd64 -v "$$(pwd)":/work -w /work debian:bookworm-slim \
            bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm src/pulse.asm /dev/null >/dev/null" \
            && echo "[+] Syntax and symbol resolution check passed."; \
    fi

# Run static hygiene and lint analysis
lint:
    @bash scripts/lint.sh

# Apply deterministic formatting
format:
    @bash scripts/format.sh

# Run automated binary verification tests
test: build
    @bash scripts/test.sh bin/pulse.kex

# Full quality gate (required by CI)
check: format lint typecheck test
    @echo "[+] All quality gates passed successfully."

# Remove build artifacts and temporary files
clean:
    @rm -rf bin/ scripts/*.py
    @echo "[+] Workspace cleaned."
