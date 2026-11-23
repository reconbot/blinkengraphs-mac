# How macOS fills the Local Metrics

**Status:** accepted

The spec's Local rules read platform-neutral Metrics ([spec ADR 0003](https://github.com/reconbot/blinkengraphs/blob/main/docs/adr/0003-local-metrics-are-platform-neutral.md)). `MacMetrics` maps them from the sources in [spec `docs/local-metrics.md`](https://github.com/reconbot/blinkengraphs/blob/main/docs/local-metrics.md):

| Metric | macOS source |
|---|---|
| `CpuBusy` | `host_statistics(HOST_CPU_LOAD_INFO)`: (user + system + nice) ÷ all ticks |
| `MemPressure` | `sysctl kern.memorystatus_vm_pressure_level`: 1, 2, 4 → normal, warn, critical |
| `MemPageIns` | `host_statistics64(HOST_VM_INFO64)`: Δ(`pageins` + `swapins`) × `hw.pagesize` per second |
| `Disks` | IOKit `IOBlockStorageDriver` `Statistics`: busy = Δ Total Time ÷ elapsed, capped at 100%; response = Δ Total Time ÷ Δ Operations |
| `NetUp`, `NetDown` | `getifaddrs` `if_data` bytes of the Followed Adapter, the first interface `NWPathMonitor` lists |

- **Disk busy is the mean number of requests in flight**, capped at 100%: macOS has no idle-time counter. It reads at least as high as true busy time, so the disk Finding fires at least as readily as on Windows.
- **The pressure sysctl is undocumented.** If it disappears, `DISPATCH_SOURCE_TYPE_MEMORYPRESSURE` gives the same three levels as events.
- The Memory Meter shows memory in use (app, wired and compressed pages ÷ physical); the Verdict reads only pressure.

## Unverified

Whether 4 MB/s of page-ins is the right bar on an SSD Mac: an app launch pages in its executable. Trace it on hardware before trusting the paging Finding.
