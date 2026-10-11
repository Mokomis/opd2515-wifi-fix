# Buffer helper reboot and foreground-switch verification

2026-10-11. The existing installed helper passed a real tablet reboot and app-to-launcher-to-app test. No helper or buffer-setting changes were made.

The kernel boot ID changed, boot completion was confirmed, and the helper was alive with a new daemon PID without manually starting it. While the launcher was foreground, helper status was disabled. Launching Punktfunk applied value2 to its current PID. Its GuiUtils callback confirmed frtcRate 0→2. Returning to the home screen disabled helper status and produced callback 2→0. Returning to Punktfunk reapplied value2 and produced callback 0→2. Each state was inspected after 8–9 seconds; exact transition latency was not measured.

Punktfunk was left foreground with value2 active. This verifies boot startup and real foreground-switch reset/reactivation. It does not repeat the stream latency benchmark, measure full input-to-screen latency, or test every failure/recovery scenario. Raw snapshots are retained locally under work/cosa-rea/buffer-reboot/.
