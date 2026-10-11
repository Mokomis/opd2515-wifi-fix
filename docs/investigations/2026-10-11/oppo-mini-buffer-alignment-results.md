# Value2 alignment comparison

2026-10-11. Keeping alignment enabled is favored by this display-side measure. Disabling it increased ready-to-present delay by about1.5–1.7ms in both repeats. Permanent value2/non-strict (alignment on) restored and active.

| Run | Alignment | Median ready-to-present ms | p95 ms | Presented fps | Gaps >10.4ms % |
|---|---|---:|---:|---:|---:|
| 1 | On | 13.46 | 15.05 | 135.2 | 5.26 |
| 2 | Off | 15.15 | 20.70 | 135.6 | 5.29 |
| 3 | On | 13.50 | 16.69 | 134.7 | 5.67 |
| 4 | Off | 15.03 | 20.89 | 135.6 | 5.29 |

Method: original stream/app/PID/video SurfaceView retained; value2 in every window, strict=false/on versus strict=true/off.5sec warmup then approximately28sec fresh-frame measurement per window. Sampling0.65sec, rolling frame records deduplicated and restricted to timestamps newer than the start cutoff. No app restart or stream setting change. Logs show type4/rate2/info true for alignment on, info false for off.

The permanent helper was temporarily stopped using its disable marker, so its periodic non-strict requests could not override the comparison. Each test used a unique description and60sec independent reset watchdog; overall200sec recovery watchdog would reset test requests and re-enable the helper if interrupted. Finally reset the experimental request, removed the disable marker, restarted the unchanged boot entry and verified value2 status plus client info=true callback. Recovery pending marker cleared.

Interpretation: alignment appears to account for the measured completed-frame waiting benefit; this does not independently prove the pending-throttle contribution or total input-to-photon improvement. Deliberate producer alignment can move waiting before frameReadyTime, which this metric omits. Native helper wait duration was not measured. Frame rate and longer gaps were similar, with no consistent pacing gain. Nonrandom order, changing game content and one session limit causality.

The timestamp metric is actualPresentTime minus frameReadyTime, as documented by [Android FrameTracker](https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/services/surfaceflinger/FrameTracker.cpp). This is compositor presentation fencing, not a camera measurement.

Evidence: work/cosa-rea/buffer-alignment/epochs.json, metrics.json, identity.json, per-window request/reset responses and logs, restored-status.txt, final-vrr.txt. Bool value in raw JSON means strict flag: false=alignment on, true=alignment off, not buffer count.
