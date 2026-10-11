# Installed buffer helper on/off comparison

2026-10-11. Four approximately180-second windows during the same stock Punktfunk game stream, ON/OFF/ON/OFF, without app restart. Tested the actual permanent helper including its five-second foreground polling and thirty-second request refresh. The helper was restored enabled after capture; value2 active for the current app PID was confirmed in status.

## Results

| Window | Helper | Presented fps | Ready-to-present median / p95 ms | Gaps >10.4ms % | Gaps >20ms % | Recovery requests/min |
|---|---|---:|---|---:|---:|---:|
| 1 | ON | 135.16 | 13.43 / 15.44 | 5.39 | 1.19 | 35.09 |
| 2 | OFF | 135.14 | 14.84 / 20.13 | 5.37 | 1.19 | 9.36 |
| 3 | ON | 135.06 | 13.40 / 15.62 | 5.25 | 1.32 | 21.72 |
| 4 | OFF | 132.64 | 13.79 / 18.23 | 7.69 | 0.84 | 6.01 |

The ready-to-present interval tightens again with the installed helper. Adjacent-window median differences are about1.40ms and0.39ms; these are compositor-side intervals, not measured total latency. Waiting moved earlier remains a possible explanation.

Frame-gap results are mixed. The first ON/OFF pair has nearly identical fps and gap rates. The final OFF window has lower fps and more >10.4ms gaps, but fewer >20ms gaps. This live, non-randomized run does not establish a consistent stutter improvement or regression.

Recovery requests were higher in both ON windows (105 and65 requests) than OFF (28 and18). Requested ranges contain106,65,28,18 frame indices respectively; they are not counts of proved losses or measured queue discards. Earlier diagnostic evidence showed requests can reflect intentional newest-frame discards and other cases. This stock capture cannot classify their cause. All71 sampled wire-ingress lines reported frames_dropped=0. Those interval counters do not exclude every missing frame or other loss mechanism. The repeat direction is a caution signal, not proof the helper causes network loss or a specified discard rate.

Twelve refresh callbacks were observed inside enabled measurement windows. Within±0.5sec of refresh, >20ms gaps were0.86% and0.62%, versus1.21% and1.35% away from refresh. This small coincident sample does not support excess refresh-associated hitches; it does not independently measure polling CPU cost, prove the 360-sample history is preserved, or exclude effects at other offsets. Polling every5sec and request refresh were tested together, not separately.

## Method and limits

Ten seconds settling per state, then180sec of rolling SurfaceFlinger latency reads at a nominal0.65sec cadence. Valid timestamps were deduplicated and restricted to presentations after each window's initial history cutoff. About24,000 frames per window. Maximum measurement call duration119–276ms; no call exceeded800ms. The same measurement load was applied in all conditions, but normal unmeasured gameplay has no such polling. Long scheduling gaps between calls were not independently excluded solely by call duration.

App logs were streamed continuously with monotonic timestamps and filtered into each frame window using first/last presentation timestamps. Recovery counts represent emitted log lines, not a full frame ledger. SurfaceFlinger presentation and logcat monotonic times were used for alignment; saved uptime fields are provenance only. Gameplay was requested similar, not a fixed replay, and window order was not randomized. No diagnostic build, profile change, touch write, or firmware change was applied.

## Recommendation and state

No proven end-to-end latency gain or consistent stutter benefit. The increased recovery-request rate merits caution. Given the user's preference to stop low-return tuning, disabling this optional helper is reasonable; retaining it is provisional rather than an established latency fix. It was restored enabled after the test, then persistently disabled at the user's request; see [final decision](oppo-mini-buffer-final-decision.md). No further broad OPPO experiments are recommended.

The reboot/foreground-switch test separately passed. Claude's audit at49176a5 predates that verification and this installed-helper comparison. This addresses its two proposed device checks without establishing full input-to-screen latency.

Compact results: [metrics](metrics/buffer-installed-helper.json). Raw app logs, frame epochs, polling timings and final-state snapshots remain local under work/cosa-rea/buffer-installed-test/.
