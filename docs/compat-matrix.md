# Compatibility Matrix

| Config | FW | Secure Boot | RAM | CPU | Graphics | Disk | toram | persist | Pass/Fail | Boot Time | Idle RAM | Screenshot |
| ------ | -- | ----------- | --- | --- | -------- | ---- | ----- | ------- | --------- | --------- | -------- | ---------- |
| 1 | BIOS | Off | 1 GB | qemu64 | std | USB | Off | Off | Pass | ~80s | ~400 MB | N/A |
| 2 | UEFI | Off | 2 GB | host | virtio | SATA | On | Off | Pass | ~40s | ~600 MB | N/A |
| 3 | UEFI | On | 4 GB | host | virtio | NVMe | Off | On | Pass | ~45s | ~450 MB | N/A |

### Untestable Items
- **Real hardware**
- **Wi-Fi / Bluetooth**
- **Printers**

*Note: Please test the above on real hardware and record the result here.*
