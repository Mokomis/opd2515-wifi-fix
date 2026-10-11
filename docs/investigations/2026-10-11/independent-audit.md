# Independent audit of the 2026-10-11 investigation

> Historical independent review. Subsequent reboot and installed-helper tests are reconciled in [final recommendations](final-recommendations.md). The buffer helper is now persistently disabled. The original audit below is preserved with its original scope.

Audited at commit `49176a5` on `claude/oppo-game-thread-scheduling-b2qx8b`. Scope: every report indexed in [README](README.md), the four `metrics/` files, [artifact identities](oppo-mini-artifact-identities.json), both [diagnostic patches](diagnostic-patches/), the [buffer helper](buffer-helper/), and the earlier [source-only report](../../scheduler-and-latency-findings.md) and root README section it fed.

No device was touched. Raw traces, `work/` files and REA evidence IDs are not in the repository, so every runtime number below was checked only for internal consistency with the published tables and JSON. It could not be re-derived.

## Summary

- **One retained change, and it measurably changes something.** The OPPO buffer control (value 2, alignment on) visibly alters frame pacing. The same pattern repeats in three sessions.
- **What it improves is a compositor-side interval, not the stutter.** The improvement is real in that interval and consistent, but its user-visible benefit is unproven. Part or all of the 1.1–1.3 ms may be waiting moved earlier, out of view of the metric. The rate of long presentation gaps, which is the reported stutter, did not change in any comparison.
- **Every other experiment ended without a retained change, and those negative results are well supported.**
- **The strongest lead for the stutter is not OPPO.** The best-evidenced explanation in the published material is delivery and assembly: about 1 Gbps PyroWave traffic, incomplete frame assemblies, bunched deliveries, and decode-fence stalls. No OPPO scheduling, service or policy finding is supported.

## 1. Findings ranked by confidence and practical benefit

Confidence is in the finding as stated. Benefit is the practical value to the stutter problem.

| # | Finding | Evidence type | Confidence | Benefit |
|---|---|---|---|---|
| 1 | The version-4 request reaches Punktfunk's graphics client and resets to type 0 / rate 0 | Observed runtime (client callbacks, several sessions) | High | Enabling only |
| 2 | Value 2 with alignment pins ready-to-present delay at about 13.4–13.5 ms. Disabled windows wander from about 12.6 to 19 ms per second | Measured (`metrics/buffer-value2.json`, `buffer-comparison.json`, `buffer-alignment.json`) | High for the metric | Low to unknown, see 2.1 |
| 3 | The alignment step, not the pending-frame threshold, produces the change. Strict mode (threshold only) measures about the same as disabled | Measured (`metrics/buffer-alignment.json`) against the disabled windows in other sessions | Medium-high | Clarifies mechanism |
| 4 | With value 2, about 0.85 ms of extra time is spent inside `QueuePresentKHR` | Measured trace (`metrics/buffer-producer-wait.json`) | High | Indirect evidence that the pacing branch executes |
| 5 | Presented fps (~135) and the share of gaps over 10.4 ms (5.3–6.4 %) are the same with and without the control | Measured, all buffer comparisons | High | **Negative for stutter** |
| 6 | Most frame-recovery requests are deliberate newest-frame queue discards, not network loss. A smaller group of assembly expirations is real | Measured with a diagnostic build ([frame ledger](oppo-mini-frame-ledger-results.md), [frame wait](oppo-mini-frame-wait-findings.md)) | Medium-high | Highest remaining lead |
| 7 | CPU scheduling wait for decode, demux and audio is sub-millisecond at p99, and was unchanged by the exemption and UX rule tests | Measured traces ([scheduling](oppo-mini-scheduling-test.md), [correlation](oppo-mini-correlation-findings.md)) | Medium-high | Rules out a scheduling fix |
| 8 | Punktfunk holds two type-4 low-latency Wi-Fi locks and power save reports off during streaming | Observed runtime ([service findings](oppo-mini-service-findings.md), [Wi-Fi/thermal](oppo-mini-wifi-thermal-presentation.md)) | High | Already in effect |
| 9 | Faster touch selector raises delivered touch reports from about 151 to 275 per second | Measured, one capture per condition ([touch](oppo-mini-touch-and-buffer-options.md)) | Medium | None for controller play |
| 10 | Cosa performance profile, background services, memory policy and DroidDeck event logging show no actionable effect | Measured or observed, short windows | Medium for "no large effect" | None; correctly not retained |
| 11 | OPPO receiver, client and policy semantics (thresholds 1–2, value 3 rejected, 360-sample gate, alignment target) | Static reverse engineering, not reproducible from the repository | Medium; unverifiable here | Explanatory |

### 1.1 What the block data shows

Each metrics window carries per-second median delays (`block_medians`). Recomputed from the published JSON:

| Session | Control on: per-second medians | Disabled: per-second medians |
|---|---|---|
| Value 2 repeats | 12.80–13.82 ms, all 57 seconds | 12.63–16.68 ms; 17 of 86 seconds below the highest "on" second |
| First comparison (values 1 and 2) | 12.70–13.77 ms | 13.10–18.99 ms |
| Alignment on vs off | On: 12.99–13.93 ms | Off: 13.30–17.95 ms |

So the control mostly removes variance above about 13.5 ms. It does not move the whole distribution down; some disabled seconds are faster than any enabled second.

The adjacent-window differences in medians for the retained setting are 1.04, 1.09, 1.22 and 1.30 ms. "About 1.1–1.3 ms" is a fair summary of the median; the p95 drop (about 20 → 15 ms) is larger and is the clearer effect.

## 2. Contradictions, measurement weaknesses and overstated claims

### 2.1 The headline metric cannot separate real gain from moved waiting (most important)

**The metric only starts when a frame is ready.** Ready-to-present is `actualPresentTime − frameReadyTime`. The alignment step deliberately delays the producer to a fixed phase (latest timestamp plus half a display period, per [buffer-client-followup.md](buffer-client-followup.md)). Delay inserted before `frameReadyTime` disappears from this metric. The reports acknowledge this ([buffer-value2-results](oppo-mini-buffer-value2-results.md) line 17, [alignment results](oppo-mini-buffer-alignment-results.md) line 16).

**The tighter, phase-locked distribution in 1.1 is what pure phase alignment would produce.** It is also compatible with a real improvement. Nothing published distinguishes the two.

### 2.2 The "same frames reach latch sooner" result has a cross-frame confound

[oppo-mini-buffer-producer-wait-results.md](oppo-mini-buffer-producer-wait-results.md) line 7 says the extra wait sits inside `QueuePresentKHR`, but "the same frames still reach compositor latch sooner from image acquisition". It takes this as supporting a real benefit rather than an artificial one.

**Why the interval can shrink without any real gain:**
- In Punktfunk, decode and present for every frame run sequentially on the one `pf-decode` thread. The [frame-wait patch](diagnostic-patches/punktfunk-frame-wait-diagnostic.patch) (`pyro/mod.rs`, `present.rs`) shows the order: decode, wait for the decode fence, acquire, draw, submit, `queue_present`.
- A wait in frame N's present therefore pushes frame N+1's decode and acquisition later.
- Acquisition-to-latch is measured from acquisition. It shrinks whenever acquisition starts later while the latch stays on the same vsync, even if nothing reaches the screen earlier.

**Two more weaknesses in the same data:**
- The two disabled runs differ by 0.86 ms (5.61 vs 6.47 ms). That is the same size as the claimed effect (0.70 and 1.60 ms).
- At p95, value 2 run 1 is worse than its neighbour (11.42 vs 10.88 ms). The report does not mention p95.

**What it would take:** the interval has to start before the wait, for example at frame arrival or decode completion, and end at present. That was never measured.

### 2.3 The retained configuration itself was never measured

**No published window had the helper running as installed:**
- the value 1/2 comparison and the value 2 repeats were run before installation, with per-test requests;
- the producer-wait and alignment tests paused the helper with its disable marker;
- the Cosa profile tests ran with the helper active, but they were not on/off comparisons of the helper.

**What the helper does that the tests did not:**
- It runs a full `dumpsys oplus_vrr_service` every 5 seconds during play.
- It re-sends the request every 30 seconds.

**Neither effect has been measured:**
- whether the 5-second dump causes periodic hitches;
- whether a re-send restarts the 360-sample producer history the extension needs before pacing (static, [buffer-client-followup.md](buffer-client-followup.md) line 15). If it does, pacing would be off for about 2.7 s of every 30 s at 135 fps.

### 2.4 "App-side presentation blocking is eliminated" predates the retained change

[oppo-mini-frame-wait-findings.md](oppo-mini-frame-wait-findings.md) concludes that presentation calls are too short to explain queue skips (queue-present mean 0.283 ms, maximum 1.438 ms).

**The capture looks like the control was not active.** Its queue-present times match the trace's disabled state (mean 0.35 ms), not value 2 (mean about 1.1 ms, p95 about 2.2 ms). So either the capture predates the helper, or the helper was not effective on the reinstalled diagnostic app. The published order of events does not say which. Either way, the conclusion does not describe the current state.

**The current state carries more risk than that capture showed:**
- With value 2, about 1 ms is added on the same thread that must decode and present each frame inside 6.94 ms.
- The capture already had 1.31 % of frames over budget at a mean of 5.4 ms.
- Moving the mean towards 6.3 ms plausibly raises that share. Over-budget frames are what lead to newest-frame discards.

This is an unmeasured risk, not a demonstrated regression.

### 2.5 The stutter metric did not move

Gaps over 10.4 ms stayed at 5.3–6.4 % in every enabled and disabled window. Presented fps stayed around 135. The index row "Buffer control" reports only the waiting improvement. It should say plainly that the long-gap rate, the closest published proxy for the reported stutter, was unchanged. A correction has been made in [README](README.md).

### 2.6 Smaller issues

- **Non-random order.** All comparisons are ABAB in one sitting with live gameplay, so treat the block-level counts as descriptive, not statistics. The reports say this.
- **Sampling may perturb what it measures.** The measurement polled `dumpsys SurfaceFlinger --latency` every 0.65 s, so the compositor was being dumped while being measured. It was the same in every window, but it is not the user's normal state.
- **First comparison window.** Run 1 of [buffer-latency-results](oppo-mini-buffer-latency-results.md) has lower fps (128) and more gaps (8.3 %) than every later window. It reads as start-up, not a baseline.
- **Artifact identities are incomplete.** [oppo-mini-artifact-identities.json](oppo-mini-artifact-identities.json) lists eight binaries. It omits the ones the retained change depends on: SurfaceFlinger `cf485097…`, libgui `4064189e…`, libguiextimpl `9e1bd646…`, COSA.apk `19c50073…` and oplus-services.jar `bca5f72c…`. Those hashes exist only in report prose. A note was added to the index.
- **The firmware fingerprint is published after all.** The index says the device fingerprint file is not included, but the fingerprint appears in [service findings](oppo-mini-service-findings.md): `OPPO/OPD2515/OP6548L1:16/BP2A.250605.015/B.c211d9_18fbf06_18beffd:user/release-keys`. Whether it equals the helper's guard file cannot be checked.
- **Diagnostic patches are instrumentation only.** They add timing marks and a bounded ledger. The one code edit inside `FrameChannel` (`pop_front` now records what it removes) does not change behaviour. However, they also replace several design comments in `frame_channel.rs`, `pyro/mod.rs`, `present.rs` and `video_pyrowave.rs` with shorter text, and the `present.rs` replacement adds "acquisition timeout", which the original did not mention. They must not be applied as-is to a production tree.

### 2.7 Contradictions with the earlier source-only report (corrected)

- [scheduler-and-latency-findings.md](../../scheduler-and-latency-findings.md) said Punktfunk was likely not registered with `game_opt`. Runtime showed it is (`game_pid` equal to the app PID, [service findings](oppo-mini-service-findings.md)). The registration did not translate into boosts: heavy and critical task boost were off, and CPU minima were zero.
- That report and the root [README](../../../README.md) gave `0x180D83` as the ultralow Wi-Fi flags. The device's ODM ini has `0x180c83` (bit 8 clear), although which ini the driver loads is unresolved. The README's suggested override `0x3010000180F83` was derived from the source value and therefore also sets bit 8.

Both documents now carry correction notes.

## 3. Reliability issues in the permanent buffer helper

Source: [buffer-helper/daemon.sh](buffer-helper/daemon.sh) and [boot.sh](buffer-helper/boot.sh). Ordered by practical risk.

1. **Requests are never confirmed.**
   - `request` (daemon line 14) returns the exit status of `dumpsys`, which is normally 0 whether or not the VRR service accepted the arguments. Output goes to `/dev/null`.
   - The helper writes `value2 pid=…` (line 56) without reading back the VRR dump or the client log, and never logs a failure.
   - A silent rejection, for example after a policy change, would look identical to success in `status`.
2. **Its own cost is unmeasured.** It runs a full `dumpsys oplus_vrr_service` every 5 s (line 37) and re-sends the request every 30 s (line 63), as 2.3 describes. This is the main reason the retained configuration's benefit cannot be assumed from the tests.
3. **No watchdog for an unclean exit.**
   - Cleanup relies on the shell `EXIT` trap. `SIGKILL`, a crash of `sh`, or a hang in `dumpsys` leaves the request active with no timed reset.
   - The trials each had independent 25–60 s watchdogs; the permanent helper has none.
   - Impact is limited to Punktfunk's process, and SurfaceFlinger stores requests by description, so the next helper run overwrites it.
4. **`status` is ambiguous.**
   - `reset` writes `disabled` both when the helper is turned off and whenever Punktfunk is merely not in front (lines 22 and 49).
   - Line 8 exits on the disable marker before the traps are set, so a stale status from a killed run is left as it was.
   - Only the `pid` file tells "running but idle" from "stopped". [oppo-mini-buffer-permanent.md](oppo-mini-buffer-permanent.md) relies on `status` for removal; a correction note was added.
5. **The lock can outlive the daemon.**
   - The lock is held on fd 0 (lines 6–7), which every child inherits (`sleep`, `dumpsys`, `pidof`, `sed`).
   - If the daemon is killed, a running `sleep 5` keeps the lock for up to 5 s, and a relaunch in that window exits silently on `flock -n`.
6. **Foreground means whatever the VRR service reports.**
   - `CurrPkgName` (line 37) is OPPO's own notion of the current app. Its behaviour with split screen, floating windows, a locked screen or picture-in-picture on this tablet was not tested.
   - Leaving foreground is detected only by polling, with up to 5 s delay.
   - An actual app switch and a reboot were never exercised, as the report says.
7. **More than one process gives no request.** If `pidof` returns two PIDs, for example while an old process is dying after a restart, the value fails the numeric check and the helper resets until one remains. That is safe, but there is no request during the overlap.
8. **What works well:**
   - The firmware guard fails safe: a missing or different fingerprint means exit without requests, logged, and the `EXIT` trap writes `disabled`.
   - The disable marker is honoured in the boot wait, at start and in the loop.
   - Requests carry an exact package name, PID, UID and a unique description.
   - No global property, Cosa database or firmware file is touched.

### Proposed behavioural changes (for review, not applied)

- **Confirm requests and log failures.** After each request, confirm it in the VRR dump or client log, and log on failure instead of writing `value2`.
- **Separate the states.** Write distinct status values: `idle-not-foreground`, `disabled`, `firmware-mismatch`, `request-unconfirmed`.
- **Drop the blind 30 s re-send.** Re-send only when the dump no longer shows the request.
- **Reduce or measure the polling cost.** Poll a cheaper foreground source, or poll less often, or keep the current polling but measure it as part of action 1 below.
- **Fix the lock.** Use a dedicated lock descriptor (for example `exec 9>"$DIR/lock"; flock -n 9`) and close it for children.
- **Add an external safety net.** Have a small boot-time check reset the request if the daemon's PID is gone while `status` still claims `value2`.

## 4. Keep, revert or leave alone

| Item | Recommendation | Reason |
|---|---|---|
| Punktfunk buffer helper (value 2, alignment on) | **Keep provisionally**; revert if action 1 shows no gain | Scoped, reversible, no measured harm; the user-visible benefit is unproven and its own polling is unmeasured |
| Faster touch selector | Leave alone (not installed) | Measured on touch reports only; no benefit for controller play |
| Cosa performance profiles | Leave restored | No effect beyond window-to-window variation |
| `ui_first_black` exemption, `gl_thread_ux` rule | Leave original | Scheduling wait already sub-millisecond; no effect |
| Background, Hans, Athena and memory policy | Leave alone | No failure observed that a change would fix |
| Wi-Fi ultralow flag override in `wifi-fix.sh` (off by default) | Leave off | Never run on the device. Its suggested value was based on the source default, not the device ini (now corrected in the README) |
| Diagnostic patches | Do not apply | Instrumentation, and they rewrite unrelated design comments |
| DroidDeck, alternate OS | Leave shelved | Out of scope for the stutter |

## 5. Further actions (at most three)

1. **One helper on/off check in the retained configuration.** This decides keep versus revert.
   - Use the stock app with the helper running as installed, and the disable marker for off.
   - Run about 3 minutes per window, ABAB, during normal play.
   - Count the gap rate (over 10.4 ms and over 20 ms) from the SurfaceFlinger records already used, plus the app's frame-recovery log lines, which the frame ledger showed mostly mark newest-frame discards.
   - If the gap rate and discard rate are not lower with the helper on, revert it.
   - Effort: low; no app build needed.
2. **Exercise the helper's untested paths once.**
   - Reboot, then confirm `status`, `pid` and the client callback.
   - Switch away from Punktfunk and back, and confirm the reset and re-apply in the log and the VRR dump.
   - Effort: about 10 minutes, and needed before calling it a permanent change.
3. **The host PyroWave rate cap test that was skipped.** This is the only remaining experiment that targets the best-supported cause.
   - Observed traffic is about 1 Gbps against a 200 Mbps saved setting.
   - The [frame-wait](oppo-mini-frame-wait-findings.md) and [frame-ledger](oppo-mini-frame-ledger-results.md) results tie skips to assembly expirations, bunched deliveries and decode-fence stalls, with audio concealment in the same episodes.
   - It is reversible on the host.

Stop there. No published result justifies further OPPO service, scheduler, Wi-Fi flag or profile experiments.

## Conclusions that cannot be independently verified from the published material

- All runtime numbers: raw traces, logs and `epochs.json` files are local. The metrics JSON matches the report tables, but the frame selection behind them cannot be re-run.
- All REA and Ghidra findings: the OPPO receiver and client semantics, the 360-sample gate, the alignment target, the value 3 rejection, the Cosa policy defaults, and the Hans, Athena and Battery mappings. Evidence IDs and `work/` paths are not accessible, and the decompiled sources are not published.
- That the helper as installed equals the published `buffer-helper/` scripts, and that its fingerprint file matches the published fingerprint.
- The order of the frame-wait capture relative to the helper's installation (2.4).
- The device's loaded Wi-Fi ini and its effective flags. Even the ODM value `0x180c83` is reported, not shown.
- Which Punktfunk source the diagnostic builds were made from. The [frame-recovery report](oppo-mini-frame-recovery-findings.md) says the installed `0.43.1-mokomis.3` build was not reproduced against the published manifest.
