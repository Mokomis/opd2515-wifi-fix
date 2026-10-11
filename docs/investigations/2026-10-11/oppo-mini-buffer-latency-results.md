# OPPO Mini buffer latency comparison

2026-10-11. Existing original Punktfunk app, same foreground process and video SurfaceView; 144 Hz display. User continued the same game during tests.

## Result

Both non-strict buffer controls were associated with a small, repeatable reduction in display-side frame delay. Value 1 measured medians 13.49 and 13.27 ms, compared with disabled medians 14.62–15.11 ms. Final disabled capture returned to 15.06 ms. This supports roughly 1–2 ms less ready-to-presentation delay in this session. It does not establish input-to-photon, host/network/decode latency, or benefits in other applications.

| Run | Buffer request | Ready-to-present median (ms) | p95 (ms) | Presented fps | Gaps >10.4 ms (%) |
|---|---:|---:|---:|---:|---:|
| 1 | 0 | 14.67 | 21.05 | 128.2 | 8.30 |
| 2 | 1 | 13.49 | 14.94 | 134.6 | 5.63 |
| 3 | 0 | 15.11 | 19.87 | 135.8 | 5.34 |
| 4 | 2 | 13.52 | 15.63 | 132.6 | 6.39 |
| 5 | 0 | 14.62 | 20.04 | 135.5 | 5.45 |
| 6 | 1 | 13.27 | 15.08 | 133.4 | 6.85 |
| 7 | 0 | 15.06 | 20.66 | 135.4 | 5.45 |

Value 2 was similar (13.52 ms median), with only one tested window. Value 1 has no demonstrated advantage over 2 at the median; its two runs support repeatability. Both reduce the p95 delay by approximately 5 ms compared with neighboring disabled windows. Presentation gaps remain and no reliable FPS or smoothness gain is established.

## Method and limits

Sequence: disabled, 1, disabled, 2, disabled, 1, disabled. Each window had 5 seconds of warm-up, then about 14 seconds of measurements. Repeated rolling SurfaceFlinger --latency samples were deduplicated, and every measurement discarded frames whose presentation timestamps preceded the window boundary. A 0.65-second sampling interval kept successive 128-frame histories overlapping so new frames could be collected. No app restart, code change, stream-setting change or input automation.

Delay is actualPresentTime minus frameReadyTime, interpreted using [Android FrameTracker source](https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/services/surfaceflinger/FrameTracker.cpp). Presentation is a compositor fence measurement, not an external camera or panel-photon timestamp. It measures completed-frame waiting, not total frame age: earlier producer waiting can move time before frameReadyTime. Thus these numbers alone cannot prove the full response gets faster by the same amount.

Static REA evidence establishes pending-threshold pacing and optional alignment. Runtime logs confirm type4/rate2 and the repeated type4/rate1 reached the intended process and reset to type0/rate0. The first enabled window is not retained in the final ring-buffer log. No debug-gated helper trace was collected for this comparison, so the exact waits and pending depth remain unmeasured.

Normal game variability, nonrandom test order and short single-session windows limit causal certainty. All disabled windows had higher median and p95 delays than both enabled values; the final reversal strengthens the association. Frame-level counts are not independent statistical replications.

## Restoration and evidence

Unique version-4-rea-latency descriptions, current PID/UID, finally reset to0 plus independent40-second device watchdog per enabled window. Resets occur before the next disabled window. Watchdogs use distinct descriptions so an old watchdog cannot cancel a newer experiment. Last active request reset at00:41:39.430, observed in client log; final disabled capture then collected fresh frames. Original persistent settings, global feature flags and original app remain unchanged. No graphics tracing started for this comparison.

Total valid fresh frames: 12,964. Evidence: work/cosa-rea/buffer-comparison/epochs.json, metrics.json, identity.json, request/reset responses, logs.txt, final-logs.txt and final-vrr.txt. Native semantics: work/cosa-rea/buffer-client-followup.md.
