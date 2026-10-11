# OPPO app and exception lists

Read-only inventory on OPD2515, October 10, 2026. Collected live dynamic-filter, device-idle, game and screen-mode state, and 25 configuration files (one empty). No settings, lists, services, or app files were changed. Punktfunk's current package is `io.unom.punktfunk.mokomis`.

## Findings that matter

- Screen-mode currently recognizes Punktfunk as a game (`mIsGame:true`). The selected mode is 144.00002 Hz, and a `PRIORITY_GAME_REQUEST` vote requests minimum/target 144 Hz from `com.oplus.cosa10209`. Its absence from static refresh XML does not prevent this live game recognition. `mNonHighRefreshRatePackages` and `mAudioLowRefreshRatePackages` are empty in the dump.
- The known `ui_first_black` entry is still present with `ShutdownGameUIFirst`. Previous isolated testing found no demonstrated benefit from removing that entry; this inventory does not change that result.
- Punktfunk has no explicit match in the collected startup, battery, process-protection, Hans/ELSA, CPU-limit, OGuard, or refresh-rate files, nor in the live DeviceIdle whitelist. This does not mean it is restricted while foreground: generic rules and current app state also control behavior.
- `dev.mokomis.adrenofloor` already appears in the live DeviceIdle user whitelist, `bpm.xml`, `fixedRecord.xml` (`isClick=true`), and `power_consum_opt_status.xml` (value `1`). These are pre-existing records; neither their author nor the precise semantics of the numeric power status was established here. No helper setting was changed.

## What the lists control

| List or mechanism | Observation | Meaning and confidence |
|---|---|---|
| `dynamic_filter / ui_first_black` | Punktfunk and several Moonlight variants present | Confirmed framework consumer bypasses KeyThreadManager's key-thread UX machinery. Existing test gave no demonstrated gain from removing it. |
| `key_thread`, `gl_thread_ux`, `ofb`, `ofb_app_para`, `tpd`, `uag`, `loadbalance` | No additional exact Punktfunk matches in this live dump | Scheduling and frame-policy families; wildcard/package/thread rules must be traced individually. Membership is not a universal boost. |
| DeviceIdle user whitelist | AdrenoFloor present; Punktfunk absent | Android idle exemption, primarily relevant to idle/background operation. It does not directly grant higher foreground GPU performance. |
| `sys_ams_processfilter_list.xml` | Three `p` protected-package entries and two `q` authorized-caller entries, all unrelated to streaming | File comments identify kill protection and permission to kill protected processes; saved framework parser confirms `p` and `q` are separate lists. Not a scheduling list. Effective consumer/protection for a proposed new entry needs runtime verification. |
| `startinfo_white.xml`, `notify_whitelist.xml` | 136 entries each, no stream-package match | Saved framework code confirms the startup manager reads `startinfo_white`; the exact decision affected by this list and the notification-list consumer require further tracing. The filenames alone do not prove CPU exemptions. |
| `autostart_white_list.txt`, `associate_white_list.txt`, startup-manager/config lists | No exact stream-package matches | Startup and inter-app launch exception families. Candidate for startup/reconnect problems, not evidence for foreground decode tuning. Exact user-policy precedence is unresolved. |
| `bpm.xml`, `sys_elsa_config_list.xml` | `bpm.xml` has 42 entries including AdrenoFloor; ELSA file declares `isHansConfig=true` and `hansEnable=true`; no Punktfunk match | Background-freezing policy family. ELSA includes package/component exceptions and audio/navigation/traffic checks. Missing a static exception does not establish that a foreground app is frozen. Live freeze dumps returned no usable state. |
| `sys_cpulimit_config.xml` | `cpuSetConfig enable=false`; no stream-package match | That specific configured CPU-set mechanism is disabled in the file. This does not establish that every background CPU limiter is disabled or that the file value is the effective runtime state. |
| `sys_oguard_config_list.xml` | Resource/action policies, no exact stream-package match | Resource/guard policy configuration. Numeric groups and actions need their actual consumer traced before editing. |
| Refresh-rate XML and user override | No Punktfunk entry; user override file is empty | Static configuration is not the complete effective policy. Live game recognition and 144 Hz vote already exist. |
| Android GameManager dump | Punktfunk listed with empty modes map | No listed game-mode interventions. This is separate from OPPO Cosa/game recognition and its display vote. |

## Useful next direction

The unfinished area is **background-freeze and startup policy precedence**: identify how the system combines the user battery choice, `bpm.xml`, ELSA component rules, auto/associate-start lists, and foreground/audio/network exemptions. This could matter for background helpers or reconnect behavior; the current evidence does not justify adding Punktfunk to every list to improve active gameplay.

For any later trial, choose one observed restriction, trace its consumer, capture the original effective membership, change one rule, and verify the intended state changes. No performance benefit is claimed from this inventory.

## Evidence and limits

`work/app-lists/inventory-summary.json` maps each collected path to its local file, tag counts and stream/helper matches. Live state is in `dynamic-filter.txt`, `deviceidle.txt`, `screenmode.txt`, and `game.txt`. The inventory excludes unrelated private app databases and historical logs.

Athena's no-argument dump says `Error, empty arguments`; `-h` says unknown command. Hans and freeze dumps were empty. Do not interpret those as an empty policy. Consumer evidence uses the previously collected framework decompilation, notably `OplusProcessWhiteListUtils.java` and `OplusAamUtils.java`; decompilation and a file snapshot do not prove every rule is active.
