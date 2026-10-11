# Punktfunk diagnostic frame ledger

Temporary native diagnostic build compiled, tested, installed, measured and removed. Original installed APK restored byte-for-byte: SHA256 `d7c8c9f44e327885c88c824e70d222b9167a19ab99ee775cf30d35c18639f84a`. App settings and pairing were retained; no uninstall or data wipe occurred. Reconnect normally after the rollback restart.

## Direct runtime result

A65-second app-log capture contains25 recovery groups covering49 distinct requested frame indices. The bounded ledger retained first accepted frame packets, assembly delivery/expiration, queue insertion/discard and decoder handoff. No recovery group reached the96-record output limit.

| Requested frame classification | Count |
|---|---:|
| Complete frame intentionally discarded by newest-frame queue policy |26|
| Complete frame already handed to decoder |10|
| Incomplete frame expired from assembly |7|
| First accepted packet recorded, no later boundary retained |1|
| No matching boundary retained |5|

Classification prioritizes explicit queue-discard/expiration evidence when multiple boundaries exist. Two expired frames were subsequently handed off as partial (`complete=false`) frames. The ten already-handed-off frames had complete assembly and complete handoff records. Recovery ranges can include intervening frames while pending requests combine ranges, so the requested range is not a list of49 proved network losses.

The queue discards are directly observed: for example frame1047 has first packet, complete assembly and queue insertion, followed by `queue_newest_discard`; frame1048 is then handed to the decoder and the app asks recovery for1047. That frame was delivered successfully over the network and intentionally superseded locally.

Seven assembly expirations are a separate failure mode. Their ledger records show first packets, but the frame did not finish before the assembly policy expired it. This establishes incomplete/late assembly, not whether the cause was RF loss, host timing, socket delivery, reordering or resource pressure. Missing records cannot be treated as proof that no packet arrived; ledger history and logging are bounded.

## Source path and implications

The installed APK and cached APK for0.43.1-mokomis.3 match exactly. The original checkout's packaged JNI library also exactly matches the extracted installed library (`50804d0e84ada4a916453914f9b2924d8351aadd67cd7c5aea7091ad95f8d664`). Its working source was copied into an isolated checkout, including existing local changes, before instrumentation.

`FrameChannel::pop` deliberately drains all-intra PyroWave queues to the newest frame and counts skipped frames separately from losses. PyroWave then calls the generic `note_frame_index`, which can request reference recovery for that deliberate gap. The generic recovery range can also span complete frames consumed between gaps. Thus raw RFI request/range counts overstate actual missing-frame counts.

The examined local host source explicitly ignores PyroWave recovery requests because the codec is intra-only, so a request is not evidence that the host forces a new reference frame or that the request itself causes stutter. The host control handler does record the request in link/recovery accounting before its encode loop ignores it. The deployed host binary/version and performance consequence were not verified, and no host change was made.

The7 expirations remain worth investigating. Default assembly windows in this source are120ms for ordinary frames and30ms for chunk-aligned partial delivery, with a64-frame hard index window. Expiration compares newer frame timestamps/indices; it is not simply a timer started at the first packet of each frame. No deadline was changed.

## Validation and rollback

- Native arm64 release build passed. One pre-existing unused constant warning remains.
- Existing frame-channel tests:9 passed, including FIFO order, hard-cap eviction, all-intra newest-frame selection, skip accounting and timeout/closure behavior.
- APK signing certificate matches the original. Non-signature APK content comparison confirms only the native library changed; Android code/resources and settings UI were unchanged.
- The diagnostic ring held4096 records, stored no packet payload, stopped recording after180seconds, and emitted at most96 nearby records per recovery request. Logging and mutex work add overhead; this was a causal bookkeeping probe, not a performance benchmark.
- The device rollback watchdog was armed before installation. Manual rollback succeeded, and the restored APK checksum matches the original. No permanent diagnostics or tuning remains installed.

## Next useful step

Use GPU/decode/present timings to explain why the queue occasionally accumulates frames, and separately investigate the assembly expirations. Do not use RFI count as a loss-rate metric. A small code cleanup can avoid reference-recovery requests for intra-only intentional skips, but these measurements do not establish that cleanup would improve frame pacing.

Artifacts: diagnostic patch in `work/frame-recovery/frame-ledger.patch`; original local-change snapshot in `original-working-tree.patch`; native build and queue test logs, `diagnostic-live-log.txt`, `ledger-metrics.json`, `rollback-verification.json`. Isolated source is `work/frame-diagnostic-source`. No issue, PR or upstream publication was created.
