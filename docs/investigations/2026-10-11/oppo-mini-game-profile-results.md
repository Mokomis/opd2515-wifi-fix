# OPPO Cosa performance-profile stream test

2026-10-11. No clear stream improvement from changing Cosa standard to performance. Original standard profile restored.

| Run | Profile | Presented fps | Median ready-to-present ms | p95 ms | Gaps >10.4ms % |
|---|---|---:|---:|---:|---:|
| 1 | Standard | 117.7 | 13.77 | 20.29 | 9.96 |
| 2 | Performance | 132.8 | 13.56 | 17.87 | 6.26 |
| 3 | Standard | 133.9 | 13.46 | 16.33 | 6.15 |

The first standard window began shortly after streaming reconnected. Performance improved compared with that initial window, but the subsequent restored standard window was slightly better still. This does not establish a causal performance benefit. Median sampled GPU clocks increased500→589→500MHz; CPU policy0 medians2188.8→2707.2→2419.2MHz, policy6 stayed1651.2MHz. Sparse instantaneous clock samples are not residency or energy measurements. Battery temperature28.5→28.8°C is not a GPU/SoC thermal reading and the short run cannot establish sustained thermal behavior.

## Method and restoration

Same original Punktfunk stream, permanent value2/non-strict buffer helper left active. Supported Cosa exported-provider set_performance_value called with resolution_mode1/touch_mode1 and performance_mode2, then0. Both old/new saved profile fields changed to2; live Cosa logs confirmed GPA PERF_MODE_TYPE2 notification. Both were restored0, resolution/touch selections remain1. System high-performance mode was already enabled and was not toggled. Vendor touch node182 parcel readback is identical before/after. No app reinstall or restart.

Approximately29sec fresh presentation measurement per profile, with5sec warm-up after setter. Rolling SurfaceFlinger records deduplicated and restricted to timestamps newer than the start cutoff. Independent160sec device watchdog repeated restoration to standard. Finally reset and readback verified. Original live touch readback was recorded rather than assuming the older experiment’s value12. No touch HAL writes were made by this experiment; Cosa itself may change touch policy during a mode change.

Results concern this streamed workload only, not a demanding local game. No profile change retained. Evidence: work/game-profile/epochs.json, metrics.json, per-window telemetry/logs, setter results, selections snapshots, touch-before/after.txt and buffer-state.txt. Private Cosa snapshots remain local.
