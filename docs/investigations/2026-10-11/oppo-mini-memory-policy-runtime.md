# OPPO memory-policy runtime check

2026-10-11. Read-only; no app launches, settings, exceptions, process kills or freezes changed.

## Result

No demonstrated unwanted background failure or justified exception change identified in this snapshot. Most historical stop records for user apps carry o-stop(40); matching Athena code maps action40 to com.oplus.recents and names the associated action swipeup_forcestop_clear. These are Recents cleanup records, not evidence of arbitrary memory-pressure termination. The record alone does not prove whether a human gesture or another authorized Recents caller triggered it.

Tailscale, Termux, RumbleBridge, YouTube, refresh manager and Punktfunk histories contain these records. Do not treat them as proof their battery policy needs changing. Chrome isolated-not-needed child exits are also ordinary lifecycle records, not whole-app failures. History has bounded per-package retention (often16 entries); counts are not complete kill totals or comparable rates. Package updates and earlier diagnostic restarts are separate reasons.

## Live state

- MemAvailable5,400,928kB, approximately5.15GiB. Recent memory PSI some/full averages0.00 at10/60/300sec. This shows no current pressure, not the pressure when older exits occurred.
- Foreground Punktfunk PID26251 isFrozen=false and isPendingFreeze=false in ActivityManager.
- Notes, Calendar and Theme Store processes have isPendingFreeze=true; these are queued freezer states, not observed suspended failures. File Manager and Gboard are neither frozen nor pending in this snapshot.
- AdrenoFloor remains in live Athena background protection and explicit battery allow list. No AdrenoFloor app PID returned from pidof at collection; list membership does not establish a currently running helper, nor does absent PID establish an unintended stop.
- ActivityManager freezer flags do not establish every Hans or package-freeze state. Filtered log buffers yielded no usable event/freezer history; empty output is not proof those events never happened.

## Code provenance and interpretation

Reuse exact previously verified Athena6.0.1 artifact SHA256 de1f6bef173e5d21eadecc4db3056448c9303811a6a4d1c5775d2d7fcb9d60b8 and existing JADX/REA evidence in work/freeze-rea. Static decompilation is distinct from execution; no new native session opened.

- systemservice/action/prockill/clear/d.java149 maps com.oplus.recents to40.
- systemservice/action/prockill/clear/v.java722 identifies swipeup_forcestop_clear with40;727 labels SwipeUpClearAction.
- systemservice/utils/p.java112–132 constructs o-stop(action), invokes stop interface with exit reason13/subreason action+2000. That matches live reason OTHER KILLS BY SYSTEM / subreason2040.
- d2/a.java319–334 treats exit reason13/subreason2040 alongside task removal for its classifier. This corroborates cleanup origin but does not determine a user gesture for each historical exit.

## Next useful trigger

If a specific app misses notifications, loses a live background connection or reloads unexpectedly without being cleared from Recents, capture that event and compare its actual exit/freezer state with current user policy. Then use a targeted supported background allowance if evidence supports it. Broad never-kill exemptions are not warranted by this pass.

Evidence: work/memory-runtime/exit-info.txt, exit-summary.json, processes.txt, live-states.json, memory.txt, background-protection.txt, analysis.txt. These contain local package/process history and remain local.
