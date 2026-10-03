# Changelog

All notable changes to **KolibriPulse** are documented here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

### Fixed

### Changed

---

## [1.0.0] — 2026-10-03

### Added

- Initial release of KolibriPulse written in pure x86 Assembly (FASM).
- Non-blocking event loop using KolibriOS `Syscall 23` with 1.0s timeout (~0% CPU overhead).
- Rolling sparkline waveform history of 40 CPU samples with dynamic color coding (cyan, amber, coral).
- Real-time RAM consumption gauge (Used / Free / Total in MB) with percentage progress bar.
- Additional hardware and kernel metrics: CPU frequency (MHz), active thread count, and uptime (`HH:MM:SS`).
- Dockerized build setup with `linux/amd64` emulation for seamless compilation on Apple Silicon and Linux hosts.

---

[Unreleased]: https://github.com/core-red-project/kolibri-pulse/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/core-red-project/kolibri-pulse/releases/tag/v1.0.0
