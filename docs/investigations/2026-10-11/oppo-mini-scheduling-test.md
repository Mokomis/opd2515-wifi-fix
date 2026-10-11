# OPPO Mini scheduling experiment

Temporary live tests completed with Punktfunk streaming. Original OPPO filter policy is restored and verified. No permanent tuning was applied.

## Result

Neither removing the package’s `ui_first_black` exemption nor adding the narrow decode UX rule demonstrated a reliable benefit. The decode thread already had effective light UX (`0x00000001`) before and during both changes. The main and Android RenderThread had `0x06000003`. The explicit decode rule did not change its effective UX priority.

| Thread | Restored baseline p99 scheduling wait | Exemption + decode rule p99 scheduling wait |
|---|---:|---:|
| Decode | 0.242 ms | 0.257 ms |
| Demux | 0.103 ms | 0.179 ms |
| Audio | 0.458 ms | 0.536 ms |

These are short observations, not statistically established regressions or improvements. Baseline retained 10.010 seconds; the targeted trace retained a complete shared 12.603-second interval after ring-buffer overwrite. Larger waits inferred from the initial broad captures were artifacts of truncated CPU streams and are excluded. The initial baseline’s independently validated 3.841-second interval also had decode p99 0.242 ms.

The exemption-only scheduler capture was incomplete and does not support a quantitative comparison. Its kernel UX checks still showed the same light decode boost. Audio underrun counters did not increase during the recorded windows in any phase. Audio concealment counters increased in the original baseline, targeted stage, and restored baseline; none of these short, unequal windows establishes network or audio improvement. Logged A/V and ingress values are application diagnostics, not measured end-to-end input latency or frame presentation latency.

## Temporary changes and rollback

1. Removed `ui_first_black` tag `io.unom.punktfunk.mokomis`, originally `ShutdownGameUIFirst`, then restarted the app.
2. Added `gl_thread_ux` rule `[{"op":"ux","pattern":"^pf-decode$","event":"start_p","mode":"always"}]`, then restarted the app.
3. Removed the temporary `gl_thread_ux` tag, restored the original blacklist value, and restarted the app to clear cached policy. Binder verification confirms blacklist membership 1 with the exact original value and gl rule membership 0.

A device watchdog was prepared before changes. Manual rollback completed before finishing. Trace marker/overwrite options were restored after the narrow captures.

## Next useful investigation

Keep the original scheduling settings. Longer repeated tests with actual frame presentation and network timing measurements are needed before adopting a tweak. The audio concealment activity warrants investigation of packet loss, burst arrival, and buffering; these observations do not identify a particular OPPO service as its cause. Do not add a per-package `key_thread` configuration: the examined framework path can disable the relevant machinery for nonempty per-package entries.

Raw evidence and capture validation are in `work/scheduling-test/`, including `rollback-verification.txt`, `targeted-validation.txt`, `restored-baseline-validation.txt`, and corrected metrics. Unvalidated broad-trace scheduler metrics are explicitly marked invalid.
