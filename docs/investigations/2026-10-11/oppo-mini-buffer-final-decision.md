# Final buffer-helper decision: disabled

2026-10-11. At the user's request, the optional Punktfunk buffer helper was disabled now and for future boots by creating /data/adb/punktfunk-buffer/disable. The helper exited, its PID file disappeared, and the live Punktfunk graphics-client callback confirmed frtcRate2→0. The test's delayed re-enable safety process was cancelled so it cannot undo this decision. Helper files remain installed but inactive; the boot entry honours the disable marker.

Reason: [the installed-helper on/off comparison](oppo-mini-buffer-installed-helper-results.md) showed tighter compositor-side ready-to-present timing, but no proven full latency gain or consistent frame-gap improvement. Recovery requests were higher in both enabled windows; they are not confirmed losses or a classified discard count. On balance, no sufficiently established practical benefit warrants retaining this extra runtime control. This is a decision under uncertainty, not proof that the control never helps any workload.

Pre-existing Wi-Fi/root helpers remain unchanged. No further OPPO tuning or OS-port work is planned. Earlier installation and experiment reports describe historical states and are superseded by this final state. Re-enable instructions remain in [the installation report](oppo-mini-buffer-permanent.md) for deliberate future use.
