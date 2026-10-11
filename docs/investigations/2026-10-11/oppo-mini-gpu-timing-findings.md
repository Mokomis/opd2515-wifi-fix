# OPPO Mini PyroWave GPU timing capture

Temporary diagnostic property `debug.punktfunk.pyro_stats=1` on the original 0.43.1-mokomis.3 APK. No codec path, service, scheduling, network, or quality setting changed. Stream: 2520×1680, 10-bit 4:2:0; Adreno 829; fragment inverse wavelet; MAILBOX presentation.

## Results

- iDWT fragment: 2.592 ms average of 12 600-frame windows; window averages 2.572–2.627 ms.
- Dequant: 1.257 ms average of 12 600-frame windows; window averages 1.236–1.273 ms.
- Colour-conversion/presentation draw: 1.127 ms average across 12 600-frame windows; highest individual draw 2.889 ms.
- Sum of stage averages: 4.976 ms versus 6.944 ms for a 144 Hz frame interval. This sum is an estimate of GPU work, not measured end-to-end frame latency.
- Recovery requests still occurred: 22 groups. The separate frame-ledger capture showed many such requests correspond to deliberate newest-frame queue skips.

## Interpretation and limits

The measured average GPU stages fit inside a 144 Hz interval with limited headroom. This does not demonstrate that the GPU causes occasional queue skips. Codec reports provide window averages, not worst-case per-frame decode timings. Draw maximum does not include fence waits, swapchain image acquisition, CPU processing, delivery jitter, or actual display latch time. Instrumentation can itself add overhead.

The source waits for the decoder GPU fence before returning a decoded picture, then the presenter can wait for a previous draw fence and an available swapchain image. Those CPU wait intervals are the next useful measurement: timestamp frame handoff, decode submit/fence completion, presenter fence/acquire, and submit, correlated by frame index with queue discards. Any such diagnostic build should preserve behavior and be restored afterward.

## Restoration

Cleared the diagnostic property back to its original empty value and restarted Punktfunk to destroy the timing-enabled decoder/presenter. Verified the property is empty and the rollback watchdog is disarmed. Original APK was retained throughout this test. Reconnect to resume normal play.

Evidence: `work/gpu-timing/live-log.txt`, `metrics.json`, `restore-verification.txt`. Host cap experiment remains skipped as requested.
