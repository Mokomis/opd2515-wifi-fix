# OPPO Mini investigation findings — 2026-10-11

Device: OPPO Pad Mini OPD2515. This publishes the current session reports, including negative results and limitations, alongside the earlier source-only scheduling report. Read the current conclusions below before the historical investigation stages.

## Current conclusions and installed state

| Topic | Current result | Report |
|---|---|---|
| Buffer control | Per-app value2 with alignment on is installed for Punktfunk. Typical completed-frame waiting improved about1.1–1.3ms in repeated trials; total input-to-screen latency remains unmeasured. | [Value2 repeats](oppo-mini-buffer-value2-results.md), [installed helper](oppo-mini-buffer-permanent.md) |
| Alignment | Turning alignment off worsened the measured delay. Original alignment-on setting restored. | [Comparison](oppo-mini-buffer-alignment-results.md) |
| Earlier producer waits | About0.85ms extra queueing wait, while the same frames reached compositor latch0.7–1.6ms sooner. This covers acquisition-to-latch, not complete decode-to-display. | [Trace results](oppo-mini-buffer-producer-wait-results.md) |
| Touch reporting | Temporary selector increased delivered touch events about151→275/sec. Original selector restored; faster mode parked for later. | [Touch test](oppo-mini-touch-and-buffer-options.md), [follow-ups](oppo-mini-follow-up-notes.md) |
| Background/memory policy | No demonstrated unwanted failure warranting a new exemption. o-stop(40) maps to Recents cleanup. Existing AdrenoFloor protection retained. | [Live check](oppo-mini-memory-policy-runtime.md), [policy explanation](oppo-background-freezing-explained.md) |
| Streaming diagnostics | Scheduling, GPU, network/audio and frame-ledger findings retained below. Diagnostic app builds were reverted; original app restored. Host cap trial was skipped. | Individual reports below |

Pre-existing Wi-Fi/root helpers were retained. The buffer helper is the persistent change introduced by the buffer trials; it waits for boot, checks firmware identity, limits requests to the exact foreground app and resets when that app leaves. Runtime activation/off-switch verified; reboot and actual foreground-switch testing were not performed during gameplay. Charging investigation was skipped.

## Reports and supporting analysis

- [Athena protection and keep-alive rules](athena-keepalive-findings.md)
- [Battery UI to background protection — static REA findings](battery-findings.md)
- [Mini OGFR producer control, 2026-10-11](buffer-client-followup.md)
- [Mini Cosa display-buffer follow-up](buffer-followup.md)
- [Fresh Hans freezer exception precedence](hans-findings.md)
- [OPPO background freezing: what the controls actually do](oppo-background-freezing-explained.md)
- [OPPO app and exception lists](oppo-mini-app-exception-lists.md)
- [OPPO Mini background activity during streaming](oppo-mini-background-activity.md)
- [Value2 alignment comparison](oppo-mini-buffer-alignment-results.md)
- [OPPO Mini buffer latency comparison](oppo-mini-buffer-latency-results.md)
- [Permanent Punktfunk buffer value2](oppo-mini-buffer-permanent.md)
- [OPPO buffer control: earlier producer waiting](oppo-mini-buffer-producer-wait-results.md)
- [Mini OPPO buffer-control test](oppo-mini-buffer-test.md)
- [OPPO Mini value-2 repeat test](oppo-mini-buffer-value2-results.md)
- [OPPO Mini: presentation and scheduling correlation](oppo-mini-correlation-findings.md)
- [Cosa performance controls — OPPO Mini](oppo-mini-cosa-performance.md)
- [OPPO Mini follow-up notes](oppo-mini-follow-up-notes.md)
- [Punktfunk diagnostic frame ledger](oppo-mini-frame-ledger-results.md)
- [Punktfunk frame-recovery investigation](oppo-mini-frame-recovery-findings.md)
- [OPPO Mini decode-to-presentation wait capture](oppo-mini-frame-wait-findings.md)
- [OPPO Mini PyroWave GPU timing capture](oppo-mini-gpu-timing-findings.md)
- [OPPO memory-policy runtime check](oppo-mini-memory-policy-runtime.md)
- [OPPO Mini network and audio observation](oppo-mini-network-audio-findings.md)
- [OPPO Mini scheduling experiment](oppo-mini-scheduling-test.md)
- [OPPO Pad Mini: service and scheduling investigation](oppo-mini-service-findings.md)
- [Mini touch-rate and display-buffer investigation](oppo-mini-touch-and-buffer-options.md)
- [OPPO Mini follow-up: Wi-Fi, presentation, thermal callbacks](oppo-mini-wifi-thermal-presentation.md)
- [REA Android bridge repair](rea-android-bridge-repair.md)

## Reproducibility and evidence boundaries

- [Artifact SHA256 identities](oppo-mini-artifact-identities.json) identify analyzed firmware components.
- [Compact measurement summaries](metrics/) retain aggregate buffer metrics; bool `value` in alignment metrics means strict flag (false=alignment on), not buffer count.
- [Installed buffer helper source](buffer-helper/) is provided for review. Paths in the install report are device paths. To reproduce, capture your own build fingerprint; the device-specific fingerprint file is not included. These are exact tested-device scripts, not a universal installer.
- [Diagnostic patches](diagnostic-patches/) are temporary instrumentation, not installed fixes or recommended production app changes.
- Raw traces, logs, private databases, copied APKs/firmware and full decompiled vendor source remain local. References to `work/` identify the retained local evidence layout; they are not repository files. REA IDs are provenance references to that local evidence.
- Earlier read-only reports describe their original stage. Later test results supersede statements that the buffer control had not yet been tested. Static behavior, observed execution and measured benefits are distinguished in each report.

Original source-only research: [scheduler-and-latency-findings](../../scheduler-and-latency-findings.md).
