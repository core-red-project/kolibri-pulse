# ==============================================================================
# KolibriPulse - Makefile (Fallback Task Runner)
# Pure POSIX / Bash tooling with zero external runtime dependencies.
# ==============================================================================

FASM ?= fasm
SRC  = src/pulse.asm
BIN  = bin/pulse.kex

.PHONY: all install dev build test typecheck lint format check clean docker-build docker-image run-qemu

all: build

install:
	@if command -v $(FASM) >/dev/null 2>&1; then \
		echo "[+] Local 'fasm' detected."; \
	elif command -v docker >/dev/null 2>&1; then \
		echo "[*] Pulling Docker amd64 image for compilation..."; \
		docker pull --platform linux/amd64 debian:bookworm-slim; \
	fi

dev: build

build: $(BIN)

$(BIN): $(SRC) src/kolibri.inc src/config.inc src/sysinfo.asm src/ui.asm
	@mkdir -p bin
	@if command -v $(FASM) >/dev/null 2>&1; then \
		echo "[*] Assembling with local FASM..."; \
		$(FASM) $(SRC) $(BIN); \
	elif command -v docker >/dev/null 2>&1; then \
		echo "[*] Assembling via Docker (linux/amd64)..."; \
		docker run --rm --platform linux/amd64 -v "$$(pwd)":/work -w /work debian:bookworm-slim \
			bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm $(SRC) $(BIN)"; \
	else \
		echo "[-] Error: 'fasm' or 'docker' required to build."; exit 1; \
	fi
	@echo "[+] Binary generated: $(BIN) ($$(wc -c < $(BIN) | tr -d ' ') bytes)"

typecheck:
	@echo "[*] Checking syntax and symbol resolution..."
	@if command -v $(FASM) >/dev/null 2>&1; then \
		$(FASM) $(SRC) /dev/null >/dev/null && echo "[+] Syntax check passed."; \
	elif command -v docker >/dev/null 2>&1; then \
		docker run --rm --platform linux/amd64 -v "$$(pwd)":/work -w /work debian:bookworm-slim \
			bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm $(SRC) /dev/null >/dev/null" \
			&& echo "[+] Syntax check passed."; \
	fi

lint:
	@bash scripts/lint.sh

format:
	@bash scripts/format.sh

test: build
	@bash scripts/test.sh $(BIN)

check: format lint typecheck test
	@echo "[+] All quality gates passed successfully."

clean:
	rm -rf bin/ scripts/*.py

docker-build:
	@mkdir -p bin
	docker run --rm --platform linux/amd64 -v "$$(pwd)":/work -w /work debian:bookworm-slim \
		bash -c "apt-get update -qq && apt-get install -y -qq fasm > /dev/null && fasm $(SRC) $(BIN)"
	@echo "Done! Binary size: $$(wc -c < $(BIN)) bytes"

docker-image:
	docker build --platform linux/amd64 -t kolibri-fasm .
	docker run --rm -v "$$(pwd)":/work kolibri-fasm $(SRC) $(BIN)

run-qemu: $(BIN)
	@if [ -f "kolibri.img" ]; then \
		echo "Launching KolibriOS in QEMU..."; \
		qemu-system-i386 -fda kolibri.img -boot a; \
	else \
		echo "Put 'kolibri.img' in this directory to test with QEMU."; \
	fi
