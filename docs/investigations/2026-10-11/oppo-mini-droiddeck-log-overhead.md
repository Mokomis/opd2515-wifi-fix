# DroidDeck OPPO event-log overhead check

2026-10-11. Read-only live gameplay observation; no game/system/profile/driver changes.

## Finding

The repeated libproot-loader security-event entries do not currently show an actionable performance cost. The retained earlier high-frequency burst was not representative of this approximately18.56sec steady-play window.23 loader payload entries were newly observed, roughly1.24/sec, among55 total payload entries. Many other payloads concerned root helper commands invoked during inspection; those are not attributed to the game.

The oplus_kevent process PID2939 accumulated no measurable additional user/system CPU ticks across the window. At100 clock ticks/sec, a zero delta is bounded by counter resolution: less than roughly0.054% of one core, not proof of absolutely zero work. Sampled kevent workers also had zero-tick deltas. Inline kernel work executed on another caller's thread is outside this attribution.

Logd consumed approximately0.97% of one core for all system logging during the window, not specifically these entries. libproot.so consumed approximately1.35% of one core; DroidDeck launcher approximately10.51%. The process selector omitted process names containing spaces, including the main Risk of Rain executable, so these numbers are not a complete game CPU profile and no percentage of total game work is claimed.

## Frame check

Collected rolling SurfaceFlinger latency records for the active DroidDeck SessionActivity video surface. Unique valid presented-frame interval median8.335ms, p95 approximately33.338ms. There were23 loader payload events but only11 distinct inter-presentation gaps containing one or more events: approximately8.33,16.67,25.0 and33.34ms intervals. Most were not long stalls. This small coincident sample does not establish causality or statistically rule out occasional effects; longer gaps naturally have more opportunity to contain an event.

Logcat monotonic event times and monotonic presentation-fence timestamps were compared here; raw trace boot timestamps from earlier investigations were not used. Rolling histories contain frames before the first sample. Counts are retained for reproduction and are not a controlled on/off test. No logging component was disabled to create a comparison.

## Decision

No measured cost justifies a logging/security tweak from this check. Keep existing system behavior. The previous implication that these repeated records could be an important steady-state overhead was a hypothesis; this live window does not support it. The broader translation overhead of the actual game, including emulated CPU work and graphics translation, remains outside this bounded event-daemon check.

Evidence: work/droiddeck-overhead/stats-before.txt, stats-after.txt, cpu-metrics.json, log-before/after.txt, new-logs.txt, latency.json and interval-check.json. Raw logs contain installed-package paths and stay local. No REA native analysis was necessary for this runtime counter check.
