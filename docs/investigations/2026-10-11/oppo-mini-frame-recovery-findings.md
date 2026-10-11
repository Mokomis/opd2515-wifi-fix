# Punktfunk frame-recovery investigation

Read-only live app logging and artifact/source inspection completed. No app restart, diagnostic property, tablet/host setting, or service state was changed.

## Live evidence

The app emitted 36 reference-frame invalidation requests covering 62 frame numbers during the minute-long logging run. No request included `missing_shards` or `recovery_shards`. Six wire windows reported 2 assembly frame drops, no FEC repairs, and 2,730–2,756 rejected packets per interval. Max socket arrival gaps ranged13–60ms. There were no receive-gap warning lines; their absence is a bounded logging result, not proof of no arrival gaps.

Audio underruns remained65. Cumulative concealment rose1115→1215ms, a 100ms increase. The target buffer remained90ms at both ends. These aggregate audio and transport diagnostics do not locate individual missing frames.

## What the counters mean

Examined source maps `wire ingress.rejected` to packet-drop deltas from the reassembler. That counter includes packets for an already-completed frame, late parity, stale frames, malformed geometry and other rejected assembly inputs. It is not a direct RF-loss count. Thousands of rejected packets cannot be treated as thousands of lost video frames.

Frame-index recovery and assembly drops are different mechanisms. A gap in indices delivered to the consumer can trigger RFI before an incomplete frame is aged out and counted, or when no tracked incomplete frame exists. The observed62 requested indices versus2 assembly drops therefore deserves investigation but is not by itself a contradictory counter or confirmed defect.

`missing_beyond_parity` returns no detail when the frame is absent from the in-flight map or its streamed size is still unpinned. Missing detail does not establish that every packet of that frame was lost. We cannot separate an entirely absent frame, a discarded/expired entry, unknown streamed size or missing producer indices from these logs alone.

## Decode-path finding

The v0.43.1 PyroWave Android loop calls `client.next_frame`, then `client.note_frame_index`, then GPU `decode_frame`. The observed RFI message is consistent with a gap in the frame sequence handed to the decoder, rather than proof that the GPU damaged a reference frame. PyroWave is intra-only in this source and uses its own Vulkan loop; the conventional MediaCodec freeze-gate path should not be assumed to apply to it. The generic observer still emits RFI for PyroWave; whether this adds avoidable host work requires verifying host response and deployed build behavior.

This narrows the investigation to host frame numbering/production, transport/reassembly and consumer delivery. It does not distinguish those stages conclusively and does not justify changing OPPO scheduling or thermal services.

## Identity and evidence limits

Installed Android version:0.43.1-mokomis.3. APK SHA256: `d7c8c9f44e327885c88c824e70d222b9167a19ab99ee775cf30d35c18639f84a`. Native library SHA256: `50804d0e84ada4a916453914f9b2924d8351aadd67cd7c5aea7091ad95f8d664`.

REA archive inspection Evidence `ev_6d186c9383e1c3bb76a62a6f4a19d7ca0f91704a42fd7a54e97127b3423e60d6` establishes installed artifact inventory/identity, not native control flow. Extracted native bytes contain RFI, missing/recovery-shard and receive-gap diagnostic strings, with offsets saved in `native-diagnostic-strings.json`. String presence alone does not prove code executed.

Published Mokomis patch manifest for0.43.1-mokomis.2 names upstream commit `a75ca9f7a09ce93512bcace8c53e2c190c70f012`; selected files were retrieved at that immutable commit. The installed.3 build is newer and has not been reproduced against that manifest. Source conclusions remain qualified where local patches could differ. Sources: upstream `client/mod.rs`, `client/pump/data.rs`, `packet/reassemble.rs`, and Android `pyro/mod.rs`, retained under `work/frame-recovery/upstream-*`.

## Next discriminating measurement

Log a bounded per-frame ledger at three boundaries: host production/send, client assembly completion or eviction (with reason), and decoder consumption. Include frame index, part/complete status and monotonic timestamps. This would distinguish host skips, late/absent assembly and queue discards directly. Existing installed diagnostics do not expose that ledger; adding it would require a verified source checkout and a diagnostic app build. No rebuild or deployment was done in this pass.

Raw evidence: `work/frame-recovery/live-log.txt`, `metrics.json`, installed artifact and native excerpts, published manifest and immutable upstream source files. The REA archive session was closed.
