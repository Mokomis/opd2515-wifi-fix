# Permanent Punktfunk buffer value2

Installed2026-10-11 on the connected OPPO Mini. Value2, non-strict, is currently active for io.unom.punktfunk.mokomis. Existing original app unchanged.

## Installation

KernelSU already runs existing boot helpers in /data/adb/service.d. Added only:

- /data/adb/service.d/punktfunk-buffer.sh — boot entry.
- /data/adb/punktfunk-buffer/daemon.sh — singleton foreground watcher.
- /data/adb/punktfunk-buffer/firmware-fingerprint — exact installed build guard.
- Runtime lock, pid, status and log files inside the same private directory.

The helper waits for boot completion, checks firmware identity, then every5sec checks the VRR service's CurrPkgName. It requests Cosa-style version4 value2 using the current app PID/UID while this exact package is foreground. It resets its own unique request when the app leaves foreground or disappears, on process change, and on orderly helper exit. It reapplies the same scoped request every30sec to handle recreated display-service state. Other app requests and global display switches are not changed. Foreground switching has up to5sec polling delay. Firmware changes cause it to skip rather than apply an unverified interface after an update.

Request description: version-4-punktfunk-buffer-permanent. No Cosa database edits, app replacement, global buffer properties, touch changes or firmware patches made by this installation.

## Verification

Live client callback confirms type4/rate2/info true. Duplicate-launch lock verified. Disable marker stopped the helper and client callback confirmed rate2 to0. Removing the marker and starting the boot entry reapplied2; client callback confirmed rate0 to2. Final status value2 pid26251. Evidence in work/cosa-rea/buffer-permanent/verification.json and verification-logs.txt. Shell syntax checked on device. Reboot persistence uses the existing installed KernelSU boot mechanism; a reboot was not performed during gameplay. Leaving-foreground behavior is implemented but an actual app switch was not forced during gameplay.

## Disable or remove

Run from a root Android shell:

```sh
# Disable now and on future boots; helper resets within about5sec.
touch /data/adb/punktfunk-buffer/disable
```

To re-enable, remove that marker and reboot, or start /data/adb/service.d/punktfunk-buffer.sh in the background.

For removal, create the disable marker, wait at least 7 sec, then verify /data/adb/punktfunk-buffer/status says disabled and its pid file is absent. The status file also says disabled whenever Punktfunk is simply not in front, so the absent pid file is the actual sign that the helper stopped. Remove only /data/adb/service.d/punktfunk-buffer.sh and /data/adb/punktfunk-buffer. Do not remove the whole service.d directory or other modules.

## Benefit boundary

The helper was never measured running as installed: the value 2 tests predate it, and later comparisons paused it. Its 5-second VRR dump polling and 30-second re-requests are unmeasured. See [independent audit](independent-audit.md).

Repeated value2 tests reduced completed-frame display waiting by about1.1–1.3ms in this game stream, with no consistent pacing penalty. This is not a measured input-to-photon improvement or evidence for enabling it in other apps. See oppo-mini-buffer-value2-results.md.
