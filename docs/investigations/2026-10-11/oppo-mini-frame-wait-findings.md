# OPPO Mini decode-to-presentation wait capture

## Finding

> Audit note: the queue-present times here (mean 0.283 ms) match the disabled state of the [producer-wait trace](oppo-mini-buffer-producer-wait-results.md), not value 2 (about 1.1 ms). This capture therefore does not describe the retained buffer helper, which adds about 1 ms on the same thread. See [independent audit 2.4](independent-audit.md#24-app-side-presentation-blocking-is-eliminated-predates-the-retained-change).

The sampled presentation calls do not block long enough to explain the major queue skips. The capture instead shows a long first-frame preparation step, occasional decode-fence stalls, and complete frames reaching the queue close together even during ordinary decode times. This narrows future work to codec startup and delivery pacing; it provides no evidence for another OPPO service adjustment.

## Method and validation

Temporary native-only diagnostic APK, built from the source matching the original 0.43.1-mokomis.3 installation. Android native release build passed. The signing certificate matches the original; packaging verification confirmed only `lib/arm64-v8a/libpunktfunk_android.so` changed. No playback policy, quality, codec path, UI setting, scheduling rule, or service setting changed.

Added monotonic timestamps around frame processing, decode submission/fence wait, previous presentation fence, swapchain acquisition, draw recording/submission, and queue-present. Kept the earlier bounded frame ledger to identify which requested frames were actually discarded or expired. One timing line per processed frame can perturb timing; this is a diagnostic capture, not a benchmark against the original APK.

Observed 8,903 completed frame-processing calls spanning 65.62 seconds. Every recorded call reported `shown=true`; this means the app submitted presentation successfully, not that every frame physically reached the panel.

| Measured interval | Mean | 99th percentile | Maximum |
|---|---:|---:|---:|
| Frame preparation through decode command recording | 0.633 ms | 1.193 ms | 135.166 ms |
| Decode submission completion to fence completion | 4.309 ms | 5.818 ms | 18.553 ms |
| Previous draw fence wait | 0.003 ms | 0.006 ms | 0.135 ms |
| Acquire display buffer (includes optional timer collection) | 0.025 ms | 0.075 ms | 0.566 ms |
| Queue-present call | 0.283 ms | 0.682 ms | 1.438 ms |
| Full timed processing interval | 5.399 ms | 7.100 ms | 144.863 ms |

117 of 8,903 processing calls exceeded the 6.944 ms 144 Hz interval (1.31%); 7 exceeded 10 ms. Processing time does not include waiting for the next assembled frame, time spent in `next_frame`, recovery logging before the timer starts, physical display latch, or completion of the newly submitted draw. The decode fence can include prior work on the shared Vulkan queue and thread wakeup delay, so it is not pure codec GPU execution time.

## Queue evidence

- First observed processed frame, 574: 144.863 ms total; 135.166 ms before the decode submit. Complete frames 575–593 accumulated during that interval and were discarded when frame 594 was selected. Their ledger queue-push timestamps fall between the handoff of 574 and 594. This is an initial-frame preparation stall, but the coarse interval does not identify whether parsing, allocation, lazy shader setup, or CPU preemption caused it.
- Frame 690: 19.397 ms total, including 17.517 ms waiting for decode completion. Frames 691 and 692 assembled during this interval and were skipped in favor of 693.
- Frame 2068: 5.195 ms total, within the refresh interval. Frame 2069 entered the queue 2.257 ms after 2068's handoff; frame 2070 was selected 5.225 ms after that handoff. Thus a queue skip also occurs without a slow decode when assembled deliveries bunch together.
- Largest later decode-fence wait: 18.553 ms at frame 4765. The same region includes incomplete frame assemblies and audio concealment. These observations do not establish whether host sending, network delivery, socket processing, or GPU/system pressure triggered the episode.

The 25 recovery groups requested 95 frame indices: 44 intentional newest-frame discards, 25 assembly expirations, 16 indices already handed to the decoder, 3 first-packet-only records, and 7 without retained records. No ledger group reached the 96-record output limit. Assembly-expired does not necessarily mean the entire frame was never decoded: some were later delivered partially. Recovery warnings alone remain an unreliable loss counter.

## What is actionable

1. For a client code fix, instrument and move expensive first-frame setup before live frame consumption where safe. The 135 ms interval must be split further before naming or changing a specific operation. The existing steady-state decoder is fence-synchronous; removing that fence would require correct resource lifetime and synchronization changes, not a simple setting tweak.
2. For ongoing stream stability, a controlled reduction of host PyroWave traffic is a useful experiment because the logs still show about 1.0–1.07 Gbps and real incomplete assemblies alongside audio concealment. The user previously skipped that host test; no host setting was changed or revisited here.
3. Stop broad OPPO service/scheduler experimentation unless new evidence points to a specific control. Presentation buffer acquisition and prior draw fences are tiny in this sample. This does not rule out downstream compositor/display issues outside the timed calls.

No performance fix is claimed from this capture. The strongest result is eliminating app-side display-buffer blocking as an explanation for the observed major skips and locating specific decode/startup and delivery episodes.

## Restoration

Reinstalled the original APK and verified its installed SHA-256 matches the saved original exactly: `d7c8c9f44e327885c88c824e70d222b9167a19ab99ee775cf30d35c18639f84a`. Restarted Punktfunk. The GPU stats property remains empty. The restore watchdog is disarmed, and the staged diagnostic/original APK files were removed from the tablet after checksum verification. Reconnect for normal play.

Evidence: `work/frame-waits/live-log.txt`, `frames.json`, `metrics.json`, `package-verification.json`, `restore-verification.json`, and `build.log`. The diagnostic patch is saved separately for review; the source checkout in Projects was untouched.
