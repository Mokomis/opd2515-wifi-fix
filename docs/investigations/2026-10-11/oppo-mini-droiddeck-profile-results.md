# Risk of Rain 2 / DroidDeck Cosa profile test

2026-10-11. DroidDeck session visible and measurable through Android despite its userspace sandbox. Cosa standard→performance→standard comparison produced no clear profile benefit. Original standard restored.

| Profile/run | Presented fps | Ready-to-present median ms | p95 ms | Median sampled GPU MHz | Battery temperature °C |
|---|---:|---:|---:|---:|---|
| Standard / 1 | 80.2 | 13.15 | 21.27 | 1112.5 | 35.1–35.8 |
| Performance / 2 | 74.7 | 13.12 | 21.24 | 1150.0 | 35.8–35.8 |
| Standard / 3 | 71.6 | 13.14 | 21.23 | 1075.0 | 35.8–36.9 |

Frame rate declined monotonically across the run, rather than reversing with profile. Scene complexity, startup, ongoing warming and other variation are unresolved. Do not conclude performance mode caused a slowdown or provided a boost. GPU clocks were already around1.1GHz in standard. Presentation median13.12–13.15ms and frame-interval p95 around25ms were almost unchanged. Sampled clocks are instantaneous observations, not residency. Battery temperature is not die temperature; no thermal-throttling causal claim.

## Scope and restore

User ran Risk of Rain2 through DroidDeck. Active package com.droiddeck.launcher, SessionActivity SurfaceView BLAST layer1732. Roughly29sec fresh presentation measurement per mode,5sec warm-up after setters. Android SurfaceFlinger presented-frame rate is not an independently measured game-engine frame counter. Resolution and game settings were requested unchanged; benchmark was live gameplay, not a fixed replay.

Supported Cosa exported setter accepted mode2 with resolution_mode1/touch_mode1. Both saved Cosa profile fields changed2 and were restored0; both resolution/touch selections remain1. Cosa records show accepted selection; exact native resource requests for this translated game were not traced. System high-performance mode already enabled and unchanged. Vendor touch-node182 parcel readback identical before/after. No app restart, install, firmware or driver edits.

Permanent Punktfunk-only buffer helper remained installed; its status was disabled while DroidDeck was foreground, as intended. No buffer request was applied to DroidDeck. Device watchdog repeats original profile0 after200sec; finally reset and saved-field readback verified.

Evidence: work/droiddeck-profile/epochs.json, metrics.json, telemetry-metrics.json, profile setter/readback snapshots, logs, touch-before/after.txt and buffer-state.txt. Raw logs and private Cosa database snapshots remain local.
