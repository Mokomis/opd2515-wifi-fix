# OPPO buffer control: earlier producer waiting

2026-10-11. Stock app, no replacement/instrumented app. Disabled/value2/disabled/value2, non-strict alignment enabled.

## Finding

The tweak shifts approximately0.85ms into the traced QueuePresentKHR call, but the same frames still reach compositor latch sooner from image acquisition: median reductions0.70ms and1.60ms in two local comparisons. This supports a small benefit over the observed rendering segment, rather than a wholly artificial reduction of post-ready waiting. Decode, host/network, presentation after latch and input-to-photon timing remain unresolved.

| Run | Setting | QueuePresentKHR median ms | Acquisition to latch median ms | Same-frame mean ms | Matched frames |
|---|---|---:|---:|---:|---:|
| 1 | Disabled | 0.325 | 5.610 | 5.764 | 791 |
| 2 | Value2 | 1.175 | 4.908 | 5.040 | 797 |
| 3 | Disabled | 0.332 | 6.470 | 6.484 | 795 |
| 4 | Value2 | 1.198 | 4.867 | 4.701 | 805 |

Earlier image acquisition itself stayed around0.038–0.039ms median; QueueSubmit around0.045ms. Extra waiting appears predominantly inside QueuePresentKHR. Its longer duration is compatible with native OPPO alignment/pacing, but this trace does not isolate the exact helper wait or pending depth.

## Measurement

Existing gfx atrace exposes AcquireNextImageKHR, QueueSubmit, QueuePresentKHR, acquireNextBufferLocked with explicit frame number, and SurfaceFlinger latchBuffer with the same frame number and target layer. Parser maintains per-thread nested B/E stacks, associates the frame number inside QueuePresentKHR with the most recent image acquisition on that thread, and joins it to the exact same-frame compositor latch. No nearest-timestamp association is used. Measured interval spans image acquisition start through latch, including producer waits. Latch is acceptance of the buffer for composition, not physical presentation. Image acquisition is a swapchain operation, not decode start.

Five-second warm-up per request, then approximately6sec gfx tracing and simultaneous rolling SurfaceFlinger latency reads. Frame-ready to presentation medians: disabled14.26/15.01ms; value2 13.46/13.44ms. These represent another segment and must not be added to acquisition-to-latch medians: the intervals overlap and have different sample selection. Boot-clock ftrace timestamps are used only against one another; they are not subtracted from monotonic fence timestamps.

The original requested complete rendering-to-presentation interval is only partially covered. Exact decoded-frame entry and same-frame physical presentation were not exposed through this bounded stock trace. No claim of complete decode-to-display or button-to-screen improvement. Nonrandom order, short captures, gameplay variability and tracing overhead limit causal certainty.

## Restoration

Permanent helper paused via disable marker during comparison to prevent periodic requests overriding tests. Experimental descriptions version-4-rea-rendertrace-N, reset0 finally plus60sec watchdog per enabled request. Overall200sec recovery watchdog protected permanent helper restoration. Tracing stopped, experimental request reset, disable marker removed, original unchanged boot helper restarted; client callback type4/rate2/info true and restored-status value2 pid26251 verified. Recovery pending marker removed.

Evidence: work/cosa-rea/buffer-render-trace/0–3-trace.txt, per-run matched-frames.json, trace-metrics.json, metrics.json, epochs.json, request/reset logs and restored-status.txt. Local parser parse.py retained for reproducibility.
