# OPPO Mini: presentation and scheduling correlation

An isolated, thread-filtered scheduler trace ran alongside video SurfaceView timestamp sampling and app logging. No app restart, Wi-Fi command, scheduling policy, thermal policy or stream setting change was made. The temporary trace instance was removed afterward; global tracing remained off. Every CPU reported zero overruns, commit overruns and dropped events.

## Result

The scheduler window spans 18.008 seconds and contains 2478 video presentation timestamps. There were 96 presentation intervals above10ms; the longest was 27.785ms.

| Thread | p99 runnable wait | Maximum runnable wait |
|---|---:|---:|
| punktfunk-demux | 0.132 ms | 0.597 ms |
| pf-decode | 0.193 ms | 0.837 ms |
| pf-audio | 0.486 ms | 3.123 ms |

During the longest presentation gap, decode accumulated only 0.068ms waiting for CPU and 4.638ms running on CPU. The remaining interval cannot be assigned to a cause from this trace: it may include blocked work, GPU/fence waits, upstream frame timing or transport availability. CPU starvation does not explain the duration of that gap in this sample. This is not proof that all gaps have the same cause.

Audio underruns stayed7; cumulative concealment rose160→170ms. App wire interval maxima were16ms and10ms. Those interval aggregates cannot be aligned to individual video gaps, and the recorder did not retain raw packet arrivals. This deliberately avoids the overhead/drop problem of the previous full-rate packet record. Presentation and scheduler timestamps use the monotonic clock; app epoch timestamps are not claimed to provide precise cross-clock correlation here.

## Next check completed: reference-frame recovery messages

There were 7 reference-frame invalidation requests in the app-log window, each describing a single-frame range. The matching local client source describes this message as a recovery request and shows the Android decode feeder observing forward frame-index gaps to request recovery. This supports investigating gaps in delivered/accepted frame order, rather than applying another CPU priority tweak. Local source provenance differs from the installed APK and is explanatory evidence, not a complete installed-build identity match.

Requests do not prove RF packet loss. Possible origins include host production/transport, assembly deadlines, ordering, rejected input or decoder recovery. The wire log's `frames_dropped=0` cannot negate these recovery messages without examining counter definitions. The logged `rejected` field is likewise not assigned a specific cause from its name.

## Outcome

Keep the original tablet settings. No new OPPO service tweak is supported by these measurements. The next discriminating evidence would pair frame identifiers and assembly outcomes with host timestamps; the host-side bitrate experiment remains skipped. A longer tablet-only run can characterize gap frequency, but cannot by itself establish where upstream frames disappear.

Evidence: `work/correlation/metrics.json`, `sched.txt`, `validation.txt`, `presentation.json`, `app-log.txt` and `threads.txt`. Local source examined: Oct3 host-source `crates/punktfunk-core/src/client/mod.rs` and latency-patch-check `clients/android/native/src/decode/async_loop.rs`.
