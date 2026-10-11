# Battery UI to background protection — static REA findings

## Artifact identity

Current `work/freeze-rea/Battery.apk` and cached `local project/oppo-re/battery/Battery.apk` both SHA256 `a665dd0f7eaf04dd81fa18e124511c4faf8a3e129617852d05d78aaf9157f5d3`. Therefore cached JADX sources correspond byte-for-byte to current APK. Analysis is static, read-only; no settings or app installations performed by this worker.

## The background UI controls multiple mechanisms

| Choice (code label) | UI internal value | Athena policy | App-info background_value | List action | Doze action |
|---|---:|---:|---:|---|---|
| ALLOW BACKGROUND RUN | 0 | 1 | 2 | Add allow, remove prohibit | Add power-save whitelist |
| INTELLIGENT LIMIT BACKGROUND RUN | 1 | 3 | 0 | Remove both | Restore default/auth-scope membership |
| PROHIBIT BACKGROUND RUN | 2 | 2 | 1 | Add prohibit, remove allow | Remove power-save whitelist |

UI selection keys are `background_act_switch`, `intelligent_act_switch`, `prohibit_act_switch`: PowerControlFragment (local analysis reference: `r7/g0.java:261`). Allow confirmation calls presenter.g (source (local analysis reference: `r7/g0.java:350`)); prohibit confirmation calls presenter.a (source (local analysis reference: `r7/g0.java:366`)); Intelligent calls presenter.f (source (local analysis reference: `r7/g0.java:641`)). UI values: Allow line 408 (local analysis reference: `r7/g0.java:408`), Intelligent line 463 (local analysis reference: `r7/g0.java:463`), Prohibit line 497 (local analysis reference: `r7/g0.java:497`).

The definitive side effects are handler messages1005/1006/1007 in PowerControlPresenter (local analysis reference: `o7/h.java:178`). All three publish the allow list to AMS as `background_protect_list` through `OplusCommonConfig.putConfigInfo(...,1)` (PowerUtils (local analysis reference: `g8/c.java:218`)). Allow and Intelligent also reset AppOps operation70 mode0, plus63 if targetSDK<26 (source (local analysis reference: `g8/c.java:196`)); the numeric operations are observed statically, their platform names were not verified against this firmware in this worker.

Battery UI binds action `com.oplus.athena.RemoteGuardElfService` in package `com.oplus.athena` (Utils (local analysis reference: `r5/g.java:1284`)); presenter sends package and policy (source (local analysis reference: `o7/h.java:335`)) over descriptor `com.oplus.athena.policy.battery.IRemoteGuardElfInterface`, transaction8 (Binder proxy (local analysis reference: `r4/a.java:48`)). Athena receiver tracing is a separate worker scope.

Allow is thus a meaningful combined setting, not just a cosmetic list entry. This establishes intended configuration behavior; it does not prove unrestricted survival under every freeze/kill path or successful calls on the live device.

## Persistent files have different purposes

`battery/allow_prohibit_app.xml` carries explicit `<allow>` and `<prohibit>` entries (writer (local analysis reference: `r5/g.java:177`), read (local analysis reference: `r5/g.java:2266`), write/notify (local analysis reference: `r5/g.java:2320`)). Read/write uses `OplusSettings.readConfig/writeConfig`, type0 (storage wrapper (local analysis reference: `l5/b.java:32`), writer (local analysis reference: `l5/b.java:177`)); physical paths need framework/runtime resolution, not assumed from these API-relative names. Intelligent is inferred by absence from both lists in presenter.b (source (local analysis reference: `o7/h.java:395`)).

`battery/power_consum_opt_status.xml` is **not the background survival list**. Allow calls g3(package,context,1), which updates a packed integer preserving old low2 bits in higher bits then writes package tags (source (local analysis reference: `r5/g.java:1657`), writer (local analysis reference: `r5/g.java:2508`)). k2 extracts bits2–3 and resolves `pco_bottom_dialog_items` (source (local analysis reference: `r5/g.java:1837`)). Exact full packed-value semantics remain unresolved; do not interpret raw integers here as Athena background policy values.

`startup/fixedRecord.txt` is **not an allow list by itself**. In legacy-to-v3 startup migration it is imported into associate-start `userCare`, while `associate_startup_whitelist.txt` is imported into `switch`; boot equivalents are `bootfixed.txt` and `bootallow.txt`. A userCare entry is retained as user-selected state, but only added to enabled array when also in switch/hidden-allowed list (parser (local analysis reference: `f9/g.java:198`)). Thus it can represent an explicit decision with startup disabled. This migration runs only when parser sees `emptyKey`; current startup v3 state is outside this worker scope.

## Limits and next cross-checks

No settings toggled, no Binder writes issued, no live behavior experiment. Need Athena receive path to establish exact policy-to-freezer mapping, and live config/runtime dumps to distinguish UI intention, effective exemption, startup permission, and exclusions that still kill apps. A Doze whitelist alone cannot be assumed to exempt all OPPO freezing.
