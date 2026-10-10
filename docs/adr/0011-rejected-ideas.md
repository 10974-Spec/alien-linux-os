# ADR 0011: Rejected Architectural and Tuning Proposals

## Status
Accepted

## Context
During initial planning and architectural exploration inspired by conceptual proposals (including "Verve OS" and AI brainstorming sessions), several aggressive architectural and system tuning proposals were evaluated. While superficially appealing, rigorous technical analysis revealed severe stability, security, or usability drawbacks for a production Debian 13 distribution.

## Rejected Proposals & Technical Rationale

| Proposal | Proposed Idea | Reason for Rejection | Chosen Alien OS Solution |
| :--- | :--- | :--- | :--- |
| **"Time-Travel HUD"** | 3D visual slider rendering past desktop states in an OpenGL HUD overlay | Enormous complexity, compositor lock-in, high RAM usage, fragile across driver updates | Simple, robust `alien-recover` GUI/CLI listing plain-English snapshots with instant rollback |
| **Blanket `powertop --auto-tune`** | Automated power saving on all hardware buses via systemd service | Known to cause USB mouse/keyboard disconnects, audio popping on codec power-down, and SATA link resets | Granular hardware detection in `alien-tune`: TLP with battery thresholds only when supported by hardware |
| **Disable CPU Mitigations (`mitigations=off`)** | Boot parameter to boost CPU benchmark numbers | Severe security vulnerability exposing user passwords, keys, and browser data to Spectre/Meltdown attacks | Keep signed Debian kernel with standard security mitigations; offer optional `preempt=full` profile |
| **Mandatory Immutable Root** | Read-only image-based root filesystem without apt capability | Breaks standard Debian package management (`apt`), prevents DKMS proprietary driver builds, confuses standard Linux tooling | Opt-in `alien-protect` with transparent `DPkg::Pre-Invoke` / `Post-Invoke` hooks; default OFF |
| **Custom Kernel / Non-Debian Kernel** | Rolling third-party liquorix or custom patched kernel binaries | Breaks Debian Secure Boot signing, introduces maintenance burden, unstable ABI for drivers | Debian 13 signed kernel with optional Debian RT kernel (`linux-image-rt-amd64`) in GRUB Advanced menu |
| **Unconditional Copy to RAM (`toram`)** | Always copy live ISO image into system memory | Causes kernel panic or early userspace OOM crash on systems with <= 2 GB RAM | Dynamic RAM assessment (`alien.toram=auto`) scaling based on physical memory headroom |
| **Replacing Wayland / X11 Compositor** | Rewriting desktop shell with new tiling or custom Wayland compositor | Violates project constraint: desktop layout, Openbox, LXQt panel, and themes must remain intact and stable | Preserved LXQt + Openbox + Picom stack untouched |

## Consequences
- Prevents regressions in hardware stability, security, and desktop responsiveness.
- Alien OS remains 100% faithful to the upstream Debian 13 foundation while delivering tangible architectural improvements.
