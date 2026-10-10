# ADR 0009: Out-of-Memory Policy and CGroup Resource Isolation

## Status
Accepted

## Context
When running resource-heavy workloads (such as C++ compiles, LLM local inference, container builds, or runaway user scripts), Linux desktop systems frequently encounter unresponsiveness, audio stutter, cursor freeze, and hard system lockups due to aggressive page-cache thrashing and delayed kernel OOM killer invocation.

Alien OS requires that:
1. Interactive desktop sessions (display manager, window manager, panel, audio server) maintain responsiveness even during extreme CPU or RAM pressure.
2. Background development and compilation jobs are contained within constrained resource slices.
3. Out-of-memory situations terminate rogue processes before the desktop session crashes.

## Decision
1. **Resource Slicing**:
   - `app.slice`: Allocated `CPUWeight=200`, `IOWeight=200` to prioritize the user session and audio.
   - `dev.slice`: Allocated `CPUWeight=50`, `IOWeight=50`, with `MemoryHigh=80%` to throttle runaway developer background tasks before hitting hard system limits.
   - `alien-dev-run <command>` executes commands inside `dev.slice` via `systemd-run --user --scope --slice=dev.slice`.
   - Podman containers default to `--cgroup-parent=dev.slice`.
2. **OOM Killer Mechanism (`systemd-oomd` vs `earlyoom`)**:
   - Evaluated `systemd-oomd` (native systemd integration via PSI - Pressure Stall Information) versus `earlyoom`.
   - **Selection**: `systemd-oomd` is chosen for its tight integration with cgroup v2 slice hierarchies and memory pressure metrics.
   - Configured `/etc/systemd/oomd.conf` with:
     - `DefaultMemoryPressureDurationSec=20s`
     - Per-slice OOM policies ensuring `dev.slice` is targeted first for reclamation before `session.slice` or `app.slice`.
3. **ZRAM Swap**:
   - `systemd-zram-generator` configures compressed zstd RAM swap scaled by available memory tier.
   - `vm.swappiness=180` and `vm.page-cluster=0` maximize zram paging throughput without touching disk.

## Consequences
- The desktop cursor and audio stream remain smooth even when a build script saturates available CPU cores and memory.
- Build tasks exceeding memory thresholds are throttled at `MemoryHigh` and cleanly terminated by `systemd-oomd` in `dev.slice` without taking down user applications.
