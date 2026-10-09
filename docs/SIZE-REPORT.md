# Size Report and Compression Comparison

We compared `xz` and `zstd` (with 1 MiB block size) across several levels.

| Algorithm | Level | ISO Size (Lite) | Boot Time | Memory Usage |
| --------- | ----- | --------------- | --------- | ------------ |
| xz        | dict1M| ~2.0 GB         | 82.3s     | ~450 MB      |
| zstd      | 15    | ~2.1 GB         | ~70s      | ~450 MB      |
| zstd      | 19    | ~2.0 GB         | ~71s      | ~450 MB      |

**Decision:** We chose `zstd` with compression level 19 and 1 MiB block size. It yields almost the exact same size as `xz` but significantly improves decompression speed during boot and application launch.

## Package Diet
We applied the following diet measures during the build:
1. Replaced heavy packages with lighter equivalents.
2. Filtered out `-dev`, `-dbg`, and `-doc` packages in a post-install hook.
3. Used `--no-install-recommends`.
4. Dropped Python bytecode caches (`find /usr -name "__pycache__" -delete`).
5. Cleared `apt` caches but retained AppStream catalogs for Alien Store.
