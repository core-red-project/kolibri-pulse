# KolibriPulse

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/core-red-project/kolibri-pulse/actions/workflows/ci.yml/badge.svg)](https://github.com/core-red-project/kolibri-pulse/actions)

<p align="center">
  <strong>Compact ✦ Precise ✦ Essential</strong><br>
  <em>Real-time system monitor for KolibriOS with zero idle overhead.</em>
</p>

<p align="center">
  <a href="#about">About</a> ✦
  <a href="#features">Features</a> ✦
  <a href="#installation">Installation</a> ✦
  <a href="#usage">Usage</a> ✦
  <a href="#architecture">Architecture</a> ✦
  <a href="#contributing">Contributing</a>
</p>

---

## About

**KolibriPulse** is a technical, ultra-lightweight real-time system monitor written in pure x86 Assembly (FASM) for KolibriOS.

It exists for developers, experimenters, and retro-computing enthusiasts who need to know exactly what is happening inside the OS without altering system performance. In resource-constrained operating systems, traditional monitors create an observer effect by constantly burning CPU cycles just to poll metrics; KolibriPulse eliminates this by suspending its execution thread directly in the kernel via timed interrupts.

At a glance, it provides instantaneous visibility into CPU workload patterns (via a 40-sample rolling sparkline), RAM allocation (Used/Free/Total), processor frequency, active threads, and system uptime.

### Philosophy

> *"A system monitor must never distort the metrics it seeks to measure."*

This is a Core Red Project, part of the Sxnnyside Project.

## Features

- **Zero Overhead (~0% CPU)**: Employs `Syscall 23` timed interrupts to sleep in the kernel instead of burning CPU cycles with polling.
- **Microscopic Footprint**: Generates a self-contained native binary under **2.1 KB** (2,068 bytes).
- **Rolling Sparkline Waveform**: 40-interval dynamic CPU load history with threshold-based color coding (Cyan <70%, Amber 70-85%, Coral >85%).
- **Precise Memory Metrics**: Real-time used, free, and total RAM in megabytes with percentage visualization.
- **Kernel & Hardware Gauges**: Processor clock frequency detection (MHz), active thread count, and elapsed uptime (`HH:MM:SS`).
- **High-Contrast Slate Theme**: Engineered using KolibriOS native bitmap drawing syscalls for crisp readability without external assets.

## Installation

### Prerequisites

- Docker Desktop / OrbStack / Podman (with Rosetta 2 on Apple Silicon) OR Flat Assembler (`fasm`) 1.73+

### From Source

```bash
git clone https://github.com/core-red-project/kolibri-pulse.git
cd kolibri-pulse

make docker-build
```

*(If you have `fasm` installed locally or inside KolibriOS, simply run `make` or `fasm src/pulse.asm bin/pulse.kex`)*.

## Usage

### In KolibriOS (QEMU / VirtualBox / Real Hardware)

```bash
# Launch KolibriOS in QEMU with an existing image containing pulse.kex
qemu-system-i386 -fda kolibri.img -boot a
```

1. Copy `bin/pulse.kex` into your KolibriOS disk or virtual floppy image.
2. Double-click `pulse.kex` in the KolibriOS file manager or launch it from the terminal.

### Controls

- **`Q`** or **`ESC`**: Exit the application.
- **`[X]`**: Standard window close button.

## Architecture

```
kolibri-pulse/
├── src/
│   ├── pulse.asm        # Entry point, MENUET01 header, and interrupt event loop
│   ├── kolibri.inc      # Syscall macros (mcall), window styles, and event constants
│   ├── config.inc       # UI coordinates, color tokens, and sparkline configuration
│   ├── sysinfo.asm      # Metric collectors (CPU via IDLE thread, RAM, uptime, frequency)
│   └── ui.asm           # Canvas rendering engine (rectangles, labels, sparkline, gauges)
├── scripts/
│   ├── test.sh          # Binary test verifying MENUET01 header, entry point, size (POSIX)
│   ├── lint.sh          # Source code hygiene check (POSIX)
│   └── format.sh        # Deterministic whitespace formatter (POSIX)
├── bin/
│   └── pulse.kex        # Native compiled KolibriOS executable (2,068 bytes)
├── Justfile             # Primary command surface (just check, just build, etc.)
├── Makefile             # Fallback task runner
├── Dockerfile           # Multi-platform Linux amd64 build container
├── build.sh             # Convenience shell script
├── CLAUDE.md            # Repository engineering context
└── .github/
    ├── CODEOWNERS       # Ownership specification
    ├── PULL_REQUEST_TEMPLATE.md
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── workflows/
        ├── ci.yml       # Quality gate validation on push and PR
        └── release.yml  # Automated GitHub releases with checksums
```

## System Calls Reference (`int 0x40`)

| Syscall | Subfunction | Purpose |
| :--- | :--- | :--- |
| `0` | - | Window definition (`WS_SKINNED_FIXED`) |
| `12` | `1`, `2` | Atomic redraw start/finish |
| `23` | - | Non-blocking event wait with 100cs timeout |
| `18` | `4` | CPU frequency detection |
| `18` | `7` | Active process and thread count |
| `18` | `16`, `17` | Total and free system memory |
| `9` | `1` | IDLE thread sampling for CPU load calculation |
| `26` | `1` | Kernel timer ticks for uptime calculation |
| `13` | - | Solid rectangle rendering |
| `4` | - | Monospace bitmap string rendering |
| `47` | - | Formatted decimal number output |
| `17` | - | Button press event handling |
| `-1` | - | Clean process termination |

## Contributing

Contributions are accepted. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Before contributing, read the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>KolibriPulse</strong> — A Core Red Project<br>
  <em>&copy; 2026 Sxnnyside Project</em>
</p>
