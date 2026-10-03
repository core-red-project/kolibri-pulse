# KolibriPulse — Engineering Guide

## Topology
- **Topology:** Monolithic (single deployable native KolibriOS binary).
- **Primary Language:** x86 Assembly (FASM / Flat Assembler 1.73+).
- **Target OS:** KolibriOS (32-bit protected mode, MENUET01 format).
- **Tooling Philosophy:** Zero external runtime dependencies (pure POSIX/Bash scripts, no Python).

## Task Runner Interface
The project exposes a standard command surface via `Justfile` (run with `just`, or fallback to `make`):

```bash
just install      # Bootstrap assembly toolchain / container
just dev          # Fast local compilation
just build        # Assemble native binary (bin/pulse.kex)
just typecheck    # Validate syntax and symbol resolution
just lint         # Verify code hygiene and formatting rules (scripts/lint.sh)
just format       # Apply deterministic whitespace formatting (scripts/format.sh)
just test         # Execute automated binary format & size verification (scripts/test.sh)
just check        # Full quality gate (format -> lint -> typecheck -> test)
just clean        # Remove build artifacts
```

## Architecture & Source Layout
```
kolibri-pulse/
├── src/
│   ├── pulse.asm        # Program entry point, MENUET01 header, interrupt event loop
│   ├── kolibri.inc      # Syscall macros (mcall), window styles, event flags
│   ├── config.inc       # UI coordinates, color tokens, sparkline geometry
│   ├── sysinfo.asm      # Metric collectors (CPU, RAM, Uptime, Threads, Frequency)
│   └── ui.asm           # UI rendering engine (rectangles, text, sparkline, gauges)
├── scripts/
│   ├── test.sh          # Binary test verifying MENUET01 header, entry point, size (POSIX)
│   ├── lint.sh          # Source code hygiene check (POSIX)
│   └── format.sh        # Deterministic whitespace formatter (POSIX)
├── bin/
│   └── pulse.kex        # Generated executable (budget: < 8 KB, actual: 2,068 bytes)
├── .github/
│   └── workflows/
│       ├── ci.yml       # Quality gate validation on push and PR
│       └── release.yml  # Automated release with binaries and sha256 checksums
├── Justfile             # Primary command surface
├── Makefile             # Secondary fallback runner
└── Dockerfile           # Isolated build container for cross-platform support
```

## Coding Conventions & System Constraints
1. **FASM Assembly Rules**:
   - Always include macros (`kolibri.inc`, `config.inc`) *before* invoking them.
   - Use `mcall <fn>, <ebx>, <ecx>, <edx>, <esi>, <edi>` for kernel system calls (`int 0x40`).
   - Preserve registers (`pushad` / `popad`) in drawing and metric routines to prevent clobbering.
   - Zero runtime heap allocation: utilize static BSS buffers with bounds checking.
2. **Performance Constraints**:
   - Zero active polling: UI refresh MUST occur via `Syscall 23` timed interrupts.
   - Keep the binary strictly under 8,192 bytes (actual target is ~2,048 bytes).
3. **Commit Standards**:
   - All commits must adhere to Conventional Commits: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`, `perf:`.
