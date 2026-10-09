# ADR 0002: live-build

## Decision
We use `live-build` running in a container.

## Rationale
`live-build` is the official Debian way to build live images. Using it within a container ensures a clean, reproducible build environment that does not alter the host system.
