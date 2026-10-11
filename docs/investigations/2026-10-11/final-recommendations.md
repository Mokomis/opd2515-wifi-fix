# Final recommendations — OPPO Pad Mini

Investigation closed2026-10-11. No further device-tuning experiments are planned. This summary supersedes earlier reports' current-state statements; those reports remain historical evidence.

## What to keep and what to leave alone

| Item | Final state and recommendation | Reason / evidence |
|---|---|---|
| Existing Wi-Fi/root helpers, RumbleBridge and AdrenoFloor protection | Keep the pre-existing setup. This investigation made no final changes to it. | These were retained, not comprehensively revalidated here. [Controller timing](oppo-mini-controller-timing.md), [memory runtime](oppo-mini-memory-policy-runtime.md) |
| Punktfunk buffer helper | Disabled now and on future boots. Files retained for deliberate recovery/review. | No proven total latency gain or consistent frame-gap improvement; recovery requests were higher in both enabled windows. [Installed-helper comparison](oppo-mini-buffer-installed-helper-results.md), [disable verification](oppo-mini-buffer-final-decision.md) |
| Faster touch reporting | Original selector restored; leave it alone for controller/streaming use. | Delivered touch reports increased about151→275/sec, but touch-to-screen latency and battery cost were not measured. No benefit established for controller input. [Touch findings](oppo-mini-touch-and-buffer-options.md) |
| Cosa performance profiles | Original profile restored for both tested workloads. Leave restored. | No clear repeatable improvement. [Streaming](oppo-mini-game-profile-results.md), [DroidDeck](oppo-mini-droiddeck-profile-results.md) |
| Scheduler / UX exemptions | Original rules restored; no additional exception recommended. | Measured scheduling waits did not support a useful fix. [Scheduling test](oppo-mini-scheduling-test.md) |
| Background, battery, Hans and Athena policies | No new blanket exemptions or service disabling. | No demonstrated unwanted failure needing a change. [Policy explanation](oppo-background-freezing-explained.md), [memory runtime](oppo-mini-memory-policy-runtime.md) |
| Experimental Wi-Fi ultralow flag override | Leave off. | Not tested on the tablet; source default differs from observed ODM ini and effective loaded configuration is unresolved. [Service findings](oppo-mini-service-findings.md) |
| Diagnostic app builds / patches | Original app restored; patches retained as instrumentation only. | Diagnostics add overhead and are not production fixes. [Frame ledger](oppo-mini-frame-ledger-results.md), [patches](diagnostic-patches/) |
| DroidDeck, charging, host rate-cap and alternate-OS work | Shelved or skipped; do not restart automatically. | No current user request to pursue these. Host delivery/assembly remains a possible streaming lead, not a proved cause or justified OPPO tweak. |

## Reconciliation with the independent audit

Claude's [independent audit](independent-audit.md) reviewed commit49176a5, before the later checks. Its evidence critique remains useful: ready-to-present and acquisition-to-latch intervals cannot establish total input-to-screen latency, because waiting may move earlier. Recovery requests are not proved network losses or directly measured queue discards.

Its two proposed device checks are complete:

1. [Real reboot and foreground switching](oppo-mini-buffer-reboot-verification.md) passed: automatic helper startup, client-confirmed0→2 activation,2→0 reset on going home, and0→2 reactivation. This resolves those specific untested paths, not every failure case.
2. [Installed-helper ON/OFF/ON/OFF test](oppo-mini-buffer-installed-helper-results.md) used four three-minute windows. Ready-to-present timing tightened, frame-gap results were mixed, and recovery requests were22–35/min ON versus6–9/min OFF. This includes the helper's polling and refresh together; it does not isolate each one's cost or prove a user-visible regression. There was no clear excess of >20ms gaps around the12 observed refresh events.

The user chose to disable the helper. The daemon stopped, its PID file disappeared, the persistent disable marker was present, and the live graphics-client callback confirmed rate2→0. The test's delayed re-enable process was also cancelled. Reboot startup had been tested while enabled; a second reboot solely to exercise the disable marker was not performed. The boot script checks that marker before launching.

The audit's proposal to use fd9 for the lock is not adopted: earlier on-device implementation found that descriptor unsuitable with this Android shell. Other helper reliability suggestions are retained for future review, not implemented in an inactive helper. Its original polling, status ambiguity, unconfirmed request status and unclean-exit concerns therefore remain limitations of the historical implementation.

The host rate-cap test remains skipped. This closure does not turn an untested hypothesis into a confirmed diagnosis. Broad OPPO tuning and an Android/Linux port remain shelved.

## Maintenance and evidence boundaries

The inactive helper's state is controlled by /data/adb/punktfunk-buffer/disable. Keep the marker in place. To inspect its disabled state, check that the marker exists, status says disabled, and the helper PID file is absent. A status of disabled by itself can also mean an enabled daemon is simply idle outside Punktfunk. [Installation and removal instructions](oppo-mini-buffer-permanent.md) remain available; do not remove unrelated service.d files.

After an OS update, review any pre-existing root/Wi-Fi modifications against the new firmware before deliberately reusing them. The buffer helper's firmware guard is an extra restriction, not universal compatibility.

Published reports and compact metrics provide the reviewable record. Raw traces, app logs, private databases, firmware/APKs and decompiled vendor source remain local. Static REA claims and runtime measurements cannot all be independently reproduced from this repo. The config inventory covers25 targeted files, not an exhaustive device-wide OPPO configuration catalogue.


User-requested follow-up: [short idle-touch IRQ check](oppo-mini-touch-idle-interrupts.md) found identical0.8Hz idle touch interrupts with original and faster selectors. Original current selector restored; no permanent change. Controller-internal idle scanning and power remain unmeasured.
