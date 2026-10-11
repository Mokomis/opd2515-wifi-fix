# OPPO Mini value-2 repeat test

2026-10-11. Result: repeatable reduction of approximately 1.1–1.3 ms in completed-frame waiting with non-strict version-4 value2. It remains comparable to value1 in the prior session; no evidence that2 is superior.

| Run | Setting | Median ready-to-present ms | p95 ms | Presented fps | Gaps >10.4 ms % |
|---|---|---:|---:|---:|---:|
| 1 | Disabled | 14.79 | 20.57 | 135.0 | 5.61 |
| 2 | Value 2 | 13.48 | 15.41 | 134.7 | 5.85 |
| 3 | Disabled | 14.52 | 19.86 | 135.4 | 5.31 |
| 4 | Value 2 | 13.43 | 15.29 | 135.0 | 5.46 |
| 5 | Disabled | 14.64 | 20.10 | 135.1 | 5.55 |

Both enabled runs measured approximately13.4–13.5ms median and15.3–15.4ms p95. All three disabled runs measured14.5–14.8ms median and19.9–20.6ms p95. Frame rate stayed roughly135fps; no consistent smoothness improvement or penalty was observed.

Method: disabled/2/disabled/2/disabled;5sec warmup and approximately28sec measurement per window. User kept the same game running. Fresh video SurfaceView presentation records were collected every0.65sec, deduplicated and restricted to timestamps after each window boundary. Matching process, layer and original app were preserved. No code or global feature changes.

Latency definition: actualPresentTime minus frameReadyTime, following the [Android FrameTracker source](https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/services/surfaceflinger/FrameTracker.cpp). This is completed-frame waiting at the display compositor, not input-to-photon latency. Producer waits before the ready fence are outside this measure. Native helper waits/pending depth were not measured, so total latency benefit remains unproven. Test order was not randomized; game variation and one session limit causality and generalization.

Restoration: each enabled request used a unique version-4-rea-value2 description, current PID/UID, finally reset0 and independent60sec watchdog. Client callbacks confirmed rate2 and subsequent rate0. Last reset observed00:46:25.941; final disabled capture collected fresh frames. Original disabled state restored.

Evidence: work/cosa-rea/buffer-value2/epochs.json, metrics.json, identity.json, per-window logs, request/reset responses, final logs and VRR dump.
