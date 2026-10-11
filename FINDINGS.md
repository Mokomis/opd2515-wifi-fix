# OPPO Pad Mini OPD2515: public research findings

Public findings on ColorOS / Android16, Wi-Fi WCN7750, graphics frame pacing, touch reporting, controller input, scheduling, battery policies, Hans freezing and Athena process protection. Experiments used one OPPO Pad Mini and its tested firmware; do not generalize results to other devices or firmware builds.

Start with [final recommendations](docs/investigations/2026-10-11/final-recommendations.md), then the [full investigation index](docs/investigations/2026-10-11/README.md) and [independent audit](docs/investigations/2026-10-11/independent-audit.md).

New inventory-first research: [fresh device file inventory and Claude handoff](docs/device-inventory/2026-10-11/README.md). This read-only scan expands the earlier targeted inventory; it does not reactivate tuning.

## Final conclusions

- Existing Wi-Fi/root setup was retained. Its original Wi-Fi fixes are documented in [README](README.md); later experiments did not comprehensively revalidate them.
- The optional Punktfunk buffer helper is disabled now and on future boots. It changed compositor-side timing, but no full latency improvement or consistent stutter benefit was established. Recovery requests increased in enabled windows; these are not proved network losses.
- Faster touch reporting increased delivered reports about151→275/sec. The original selector was restored. Touch-to-screen latency and battery cost were not measured.
- Scheduling exceptions and Cosa performance-profile tests showed no convincing practical gain. Original settings were restored.
- No demonstrated background-policy failure justified new blanket exemptions. DroidDeck and alternate-OS work are shelved.

## Browse by topic

| Topic | Start here |
|---|---|
| Final retained state and audit reconciliation | [Final recommendations](docs/investigations/2026-10-11/final-recommendations.md) |
| Wi-Fi and vendor services | [Runtime service findings](docs/investigations/2026-10-11/oppo-mini-service-findings.md), [Wi-Fi follow-up](docs/investigations/2026-10-11/oppo-mini-wifi-thermal-presentation.md) |
| OPPO buffer / OGFR / graphics control | [Installed-helper test](docs/investigations/2026-10-11/oppo-mini-buffer-installed-helper-results.md), [receiver](docs/investigations/2026-10-11/buffer-followup.md), [producer](docs/investigations/2026-10-11/buffer-client-followup.md) |
| Touch and USB controller timing | [Touch findings](docs/investigations/2026-10-11/oppo-mini-touch-and-buffer-options.md), [Kishi timing](docs/investigations/2026-10-11/oppo-mini-controller-timing.md) |
| App lists, battery, Hans / Athena | [Config inventory](docs/investigations/2026-10-11/oppo-mini-app-exception-lists.md), [policy explanation](docs/investigations/2026-10-11/oppo-background-freezing-explained.md) |
| Streaming delivery and scheduling | [Frame ledger](docs/investigations/2026-10-11/oppo-mini-frame-ledger-results.md), [scheduling test](docs/investigations/2026-10-11/oppo-mini-scheduling-test.md) |
| Cosa profiles and DroidDeck | [Streaming profiles](docs/investigations/2026-10-11/oppo-mini-game-profile-results.md), [DroidDeck profiles](docs/investigations/2026-10-11/oppo-mini-droiddeck-profile-results.md) |

## Access and evidence

No login is required to read these public GitHub documents. The [machine-readable catalog](findings-index.json) lists published research documents and supporting files, with paths, titles, sizes and SHA256 checksums. [llms.txt](llms.txt) provides a plain-text entry point; it is a navigation aid, not a guarantee of crawler support or search-engine indexing.

All completed findings reports are public. Raw traces/logs, private databases, copied firmware/APKs and full decompiled vendor source are not included. Local work/ paths and REA IDs are provenance references rather than downloadable evidence. Read each report's scope and limitations; the config inventory is targeted, not exhaustive. The independent audit is preserved as a dated review; final recommendations reconcile later tests.

## Complete published research catalog

- [OPPO game scheduling and Wi-Fi latency level 4 on the OPD2515: source findings](docs/scheduler-and-latency-findings.md)
- [OPPO Mini investigation findings — 2026-10-11](docs/investigations/2026-10-11/README.md)
- [Athena protection and keep-alive rules](docs/investigations/2026-10-11/athena-keepalive-findings.md)
- [Battery UI to background protection — static REA findings](docs/investigations/2026-10-11/battery-findings.md)
- [Mini OGFR producer control, 2026-10-11](docs/investigations/2026-10-11/buffer-client-followup.md)
- [Mini Cosa display-buffer follow-up](docs/investigations/2026-10-11/buffer-followup.md)
- [Final recommendations — OPPO Pad Mini](docs/investigations/2026-10-11/final-recommendations.md)
- [Fresh Hans freezer exception precedence](docs/investigations/2026-10-11/hans-findings.md)
- [Independent audit of the 2026-10-11 investigation](docs/investigations/2026-10-11/independent-audit.md)
- [OPPO background freezing: what the controls actually do](docs/investigations/2026-10-11/oppo-background-freezing-explained.md)
- [OPPO app and exception lists](docs/investigations/2026-10-11/oppo-mini-app-exception-lists.md)
- [OPPO Mini background activity during streaming](docs/investigations/2026-10-11/oppo-mini-background-activity.md)
- [Value2 alignment comparison](docs/investigations/2026-10-11/oppo-mini-buffer-alignment-results.md)
- [Final buffer-helper decision: disabled](docs/investigations/2026-10-11/oppo-mini-buffer-final-decision.md)
- [Installed buffer helper on/off comparison](docs/investigations/2026-10-11/oppo-mini-buffer-installed-helper-results.md)
- [OPPO Mini buffer latency comparison](docs/investigations/2026-10-11/oppo-mini-buffer-latency-results.md)
- [Permanent Punktfunk buffer value2](docs/investigations/2026-10-11/oppo-mini-buffer-permanent.md)
- [OPPO buffer control: earlier producer waiting](docs/investigations/2026-10-11/oppo-mini-buffer-producer-wait-results.md)
- [Buffer helper reboot and foreground-switch verification](docs/investigations/2026-10-11/oppo-mini-buffer-reboot-verification.md)
- [Mini OPPO buffer-control test](docs/investigations/2026-10-11/oppo-mini-buffer-test.md)
- [OPPO Mini value-2 repeat test](docs/investigations/2026-10-11/oppo-mini-buffer-value2-results.md)
- [Kishi controller timing](docs/investigations/2026-10-11/oppo-mini-controller-timing.md)
- [OPPO Mini: presentation and scheduling correlation](docs/investigations/2026-10-11/oppo-mini-correlation-findings.md)
- [Cosa performance controls — OPPO Mini](docs/investigations/2026-10-11/oppo-mini-cosa-performance.md)
- [DroidDeck OPPO event-log overhead check](docs/investigations/2026-10-11/oppo-mini-droiddeck-log-overhead.md)
- [Risk of Rain 2 / DroidDeck Cosa profile test](docs/investigations/2026-10-11/oppo-mini-droiddeck-profile-results.md)
- [OPPO Mini follow-up notes](docs/investigations/2026-10-11/oppo-mini-follow-up-notes.md)
- [Punktfunk diagnostic frame ledger](docs/investigations/2026-10-11/oppo-mini-frame-ledger-results.md)
- [Punktfunk frame-recovery investigation](docs/investigations/2026-10-11/oppo-mini-frame-recovery-findings.md)
- [OPPO Mini decode-to-presentation wait capture](docs/investigations/2026-10-11/oppo-mini-frame-wait-findings.md)
- [OPPO Cosa performance-profile stream test](docs/investigations/2026-10-11/oppo-mini-game-profile-results.md)
- [OPPO Mini PyroWave GPU timing capture](docs/investigations/2026-10-11/oppo-mini-gpu-timing-findings.md)
- [OPPO memory-policy runtime check](docs/investigations/2026-10-11/oppo-mini-memory-policy-runtime.md)
- [OPPO Mini network and audio observation](docs/investigations/2026-10-11/oppo-mini-network-audio-findings.md)
- [OPPO Mini scheduling experiment](docs/investigations/2026-10-11/oppo-mini-scheduling-test.md)
- [OPPO Pad Mini: service and scheduling investigation](docs/investigations/2026-10-11/oppo-mini-service-findings.md)
- [Mini touch-rate and display-buffer investigation](docs/investigations/2026-10-11/oppo-mini-touch-and-buffer-options.md)
- [OPPO Mini follow-up: Wi-Fi, presentation, thermal callbacks](docs/investigations/2026-10-11/oppo-mini-wifi-thermal-presentation.md)
- [REA Android bridge repair](docs/investigations/2026-10-11/rea-android-bridge-repair.md)
