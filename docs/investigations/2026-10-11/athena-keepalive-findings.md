# Athena protection and keep-alive rules

Read-only reverse engineering of the pulled Athena APK. No device changes or tablet commands were made in this scope. Source paths below are relative to `work/freeze-rea/athena/sources`, except the explicitly identified default-mode file.

## Practical result

The three names “locked”, “background protected”, and “always alive” describe different controls. None establishes a universal guarantee that a process remains running or cannot be suspended by Hans.

| Control | Verified effect | Boundary |
|---|---|---|
| Recents lock | Added to candidate exclusion sets when the clear action enables `cc_skip_recent_lock`; separately excludes a package from AppFrozenService package freezing. | Clear action configuration controls the killer exemption. Other mechanisms are separate. |
| Background protect | Added to candidate exclusion sets when `cc_skip_background_protect` is enabled; otherwise commonly downgrades force-stop to process kill. | Ordinary process killing remains possible. Not automatically a Hans exemption. |
| Startup allowed | Auto-start and associate-start lists exclude packages from AppFrozenService; auto-start allowance can change force-stop to kill, or keep a listed process. | High-temperature safety, super power save, permission restrictions and action-specific branches can change treatment. |
| AlwaysAlive | Replaces force-stop clean type 2 with special clean type 3 if eligibility passes. | It is a cleanup strategy, not “never kill this app.” Its debug command explicitly kills eligible app processes. |

## Candidate exclusions and Recents lock

`common/parser/athena/d2.java:525–526` parses `cc_skip_recent_lock` into builder H. `u0/a.java:319–322` writes `f3756j`, copied to `f3737q` at line 250. `systemservice/action/prockill/clear/h.java:149–157` adds matching Recents apps to exclusion group 9 only when that flag is enabled. `r0/g.java:219–252` assembles per-user locked app entries, skips managed profiles and checks user matching. This demonstrates conditional clear-action protection, not a global lock on the process.

Swipe-up cleanup has an additional lock check: `systemservice/action/prockill/clear/v.java:122–157` checks O0 before the ordinary force-stop branch; `v.java:366–376` matches current-user locked entries. Passing the lock check moves the process into another cleanup branch, not a universal unconditional return. Do not simplify this to “locked apps cannot be killed.”

## Background protect

`common/parser/athena/FilterHelper.java:767–769,815–817` retrieves `background_protect_list` from OplusCommonConfig through `z0/m.java:14–99`; the current list selects the current user. `e1/c.java:36–69` matches the user, package name or package list.

`common/parser/athena/d2.java:597–598` parses `cc_skip_background_protect` into builder o; `u0/a.java:442–445,269` maps it to D. `systemservice/action/prockill/clear/h.java:231–232` adds all-user background-protect entries to exclusion group 42 if D is enabled.

Independently, `r0/a.java:87–101` matches current-user background protected apps. `FilterHelper.getStopTypeInner`, `common/parser/athena/FilterHelper.java:2607–2617`, returns 1 (ordinary kill) for that match. In contrast, type 2 reaches package force-stop in `systemservice/action/prockill/clear/b.java:591–623`; type 1 reaches its process kill handler. Thus a background-protect list entry can preserve restart eligibility without keeping the present process alive.

## Startup allowance is consumed through a provider

`FilterHelper.java:38–47` names `content://com.oplus.startup.provider/auto_start`, call `getAutoStartList`, result key `autoStartAllowList`; associate-start uses `/associate_start` and `getAssociateStartList`. `FilterHelper.java:3318–3382` refreshes these lists through ContentProviderClient. It does not directly open either `fixedRecord.txt` or `bpm/fixedRecord.xml` in this APK.

`FilterHelper.java:2578–2604` changes auto-start-allowed cleanup: normally to type 1; for a remove-task filter process it can return 0 unless safety high-temperature cleanup, super power save, or permission restriction overrides. The multi-app user 999 special case is also present. This is useful cross-policy interaction, not proof that startup permission alone guarantees residency.

The root investigation found `bpm.xml` and `fixedRecord.xml` consumers in this same Athena APK, obfuscated class `x/e.java` (HansAppManager). This is separate from `FilterHelper`'s startup-provider query. `x/e.java:340,918,1036–1037,2341` reads/writes the BPM list; `543–625` reads/writes `<p pkg=... isClick=...>` fixed records, and `S` at `2317–2336` sets `isClick=true` for mode 4 and removes the record for mode 8. It is not the startup `fixedRecord.txt` found by the battery worker. `x/e.java:1890–1908` constructs the app-class/config bundle for the Hans framework. These observed writes and classifications do not establish universal freeze exemption.

## AlwaysAlive eligibility and semantics

`systemservice/action/alwaysalive/AlwaysAliveManager.java:165–198` requires: config/API readiness; whitelist membership when whitelist-only mode is enabled; a launcher-icon package; no disable-list match; system/low UID packages must have an OPPO family prefix; configured clean type must equal 3; no Athena force-stop marker. OPPO prefixes checked at lines 135–148 are com.oplus, com.coloros, com.oppo, com.nearme and com.heytap.

`AlwaysAliveManager.java:244–257` only converts original clean type 2 to configured type 3. `systemservice/action/prockill/clear/b.java:573–583` skips this conversion for configured excepted action types. `common/parser/alwaysalive/d.java:140–179,220–230` combines feature availability, config and API availability; defaults alone cannot prove the live mode. Its dump config/state branches report those prerequisites.

`AlwaysAliveManager.java:62–96` shows that `aa_kill_app` actually collects app processes and invokes killer R with the special boolean true. It is not a safe inspection command. The exact type-3 kernel/framework implementation requires following that downstream killer and platform API; this scope establishes conversion and eligibility, not a precise restart guarantee.

## A separate package-freeze mechanism

`client/action/appfrozen/services/AppFrozenService.java:118–144` combines plugin apps, Recents-locked apps, startup apps, feature filter entries, stage-protected apps, default/guard app, device owner and active administrators. `g/c.java:297–329` reads locked apps from OplusCommonConfig’s recent-lock list with current-user checks; `g/c.java:332–341` combines auto-start and associate-start allowances.

`AppFrozenService.java:147–165` excludes the combined list and OPPO family prefixes, plus two additional helper predicates. `AppFrozenService.java:389–415` unfreezes already-frozen exempt packages and only calls `OplusPackageManager.oplusFreezePackage(..., 2, ...)` after additional timing/prediction and running-package checks. This is package-state freezing via OplusPackageManager; do not conflate it with Hans process suspension or ordinary process termination. The startup and Recents controls therefore really interact with *this* freeze subsystem, but the live enabled/trigger state must be checked before claiming this tablet currently uses it.

## Verified read-only dumps

Default JADX restored synthetic dispatch wrappers in `work/freeze-rea/AthenaKillerDumpManager-default.java`:

- `dumpsys athenaservice get_background_protect`: dispatch 672–676 -> n0 369–372, prints the current background-protect list only.
- `dumpsys athenaservice aam config` and `aam state`: dispatch 786–790 -> e0 263–264 -> `AlwaysAliveManager.d` 201–215 -> config dump `common/parser/alwaysalive/d.java:231–252` or state dump 256–260. Printing only.
- `dumpsys athenaservice aam getpid UID` and `aam pkgstate PACKAGE UID`: same dispatcher -> `AlwaysAliveManager.java:216–222`; PID enumeration and package eligibility printing.
- `dumpsys athenaservice recently_used_locked_apps config`: dispatch 948–953 -> T0 195–198 -> `systemservice/state/h0.java:200–207`, prints configured priority ranges/limit.

Avoid `aam aa_kill_app`, `aam force_aa_kill_app`, all `aam debug` subcommands, and broad unknown dump actions. No dump command was run by this scope.

## Evidence limits

The initial simple-mode JADX output reportedly had 10 errors. Methods cited here contain explicit branch bodies, but simple mode renders labels/gotos and some catch paths awkwardly. AthenaKillerDumpManager was re-decompiled in default mode successfully to verify synthetic command dispatch instead of guessing from registration names. No tablet mutation, runtime freeze experiment, or external upload occurred. Configuration names and source defaults must be paired with current live dumps before practical advice.

## Live corroboration supplied by root

Root read the verified dump branches. `get_background_protect` contained only `dev.mokomis.adrenofloor`, UID 10318. AlwaysAlive config reported enabled true, whitelist-only false, clean type 3; runtime state reported ready true and API available true. These observations prove the feature is available now, not that any arbitrary package passes every eligibility gate. Raw capture paths should be linked by the final consolidated report.
