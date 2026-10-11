# Fresh Hans freezer exception precedence

Scope: targeted single-class JADX simple decompilation of fresh `oplus-services.jar`; Athena targeted existing decompilation. No device modification. The goto-labelled simple output is a decompilation, not original source. Paths below are relative to this evidence directory.

## What whitelist actually means

`hans-classes/OplusHansDBConfig.java:10375–10400` assigns appClass 1 to third apps, 2 to third whitelist, 4 to OPPO whitelist, 8 GMS, 16 system blacklist. `isHansWhitelistApp` (9782–9787) checks bits 2/4.

`HansSceneManager.java:2107–2124` maps classes 1/16 to target bit 1 and 2/4 to target bit 2. Ordinary LCD-on and LCD-off scenes (1165–1170) target mask 5, excluding bit 2. FastFreezer (1170) and nightDeepDoze (1787) target mask 7, including bit 2. DeepSleep uses mask 5 unless getDeepSleepFreezeWhite permits inclusion (1849–1854). Thus membership gives ordinary-scene protection but is not universal immunity. A scene target mask means eligibility, not proof of actual freezing.

`HansSceneCombo.java:49–63` intersects importance flags across scenes, unions restriction flags, takes maximum restriction level, and unions target flags. More restrictive extensions can therefore both include whitelist apps and remove protective reasons.

## Actual eligibility guards

State machine entry rejects current resumed UID at `HansSceneManager.java:1293–1298`. `freezeForSceneCombo` (3761–3790) checks isImportantPkg using effective scene importance flags and returns IMPORTANT before cgroup freeze. Only after that guard does it freeze and request network denial. Direct/preload paths have separate gates; do not generalize this normal path to every freeze command.

`OplusHansImportance.java:863–867` passes effective flags through applyImportanceConfig. Relevant reasons are enabled only if their bit survives: traffic bit 1, audio bit 4, FGS bit 1048576. Audio (419–469) uses audio focus/recent audio/video state but can ignore silent/muted audio and configured audio types/packages. Recording has a separate bit 8 guard (406–416). FGS and bound-FGS state check (565–573) protect only when enabled. Traffic (472–477 and 893 onward) uses traffic classification, thresholds, app type, notification/FGS/visible state and thermal exclusions; network packets alone do not guarantee exemption.

## Verified importance configuration precedence

`OplusHansDBConfig.java:14218–14234`: app-type config first, exact package second, wildcard `*` third. Each applies `(flags | add) & ~remove`. Removal wins within a level; a later level can override earlier additions/removals. This is specifically importance-bit precedence, not a universal order for all exception files.

## Whitelist can be invalidated by usage

`HansSceneManager.java:5520–5555` queries recent usage, notification and ongoing notification state. With feature enabled and screen off (5557–5576), unused class-2 apps can be removed from the whitelist managed map. `removedUidFromWhitelistByUsage` (5598–5652) moves them into third managed target bit 1 and mInvalidHansWhitelist; restoration reverses it. Class value can remain 2 even while effective managed protection is invalidated. This is conditional code; live feature state has not been decoded.

## bpm.xml and fixedRecord.xml

Fresh Hans DB contains no literal bpm.xml/fixedRecord.xml consumer; Athena prepares classes/bundles. Athena `sources/x/e.java:543–625` reads/writes `/data/oplus/os/bpm/fixedRecord.xml` as `<freeze><p pkg=... isClick=.../>`. This is not battery startup fixedRecord.txt. `x/e.java:2318–2336` records isClick=true for mode4 and removes record for mode8. `T` at 2339–2390 adds/removes package in bpm.xml-style visible list, updates effective f4027e and dispatches package update; `a0` at 2575–2646 merges config lists with bpm entries and explicit records, removing certain overlaps unless isClick is true. Specific high-level UI label-to-mode binding remains to be traced.

Athena `x/c.java:1167–1257` priority is OPPO whitelist d0 -> third whitelist i0 -> system blacklist g0 -> ordinary third. i0 at 991–998 requires effective list G(pkg) and excludes config OPPO list C(pkg). `x/e.java:1448–1499` plus accessor lines2217/2253 show G uses f4027e and C uses f4029g. This links bpm effective membership to third-whitelist classification while OPPO classification takes precedence; exact UI labels are not established here.

## Runtime limitations and read-only dump

`OplusHansManager.java:3320–3335` accepts `dumpsys activity hans history` before the diagnostic-property gate. History assembles full class/config/scene/status/freeze data (4315 onward), but line4374 explicitly passes it through hansLogEncrypt. Root captured encrypted output; it cannot be treated as a decoded current map. No property was enabled to expose plaintext. Conclusions above are artifact-backed behavior; current configuration and specific package exemption effectiveness need separate runtime confirmation.
