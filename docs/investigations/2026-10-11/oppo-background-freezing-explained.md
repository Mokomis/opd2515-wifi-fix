# OPPO background freezing: what the controls actually do

Investigated October 11, 2026, on OPD2515. This was read-only: no battery choice, exception list, diagnostic property, app installation or service state was changed.

## Practical answer

**Allow background activity is a meaningful combined exemption. Recents lock is conditional cleanup protection. Neither is a universal promise that an app never freezes or dies.** OPPO has separate policies for idle restrictions, process suspension, package freezing, and process cleanup.

| Control | Code-backed effect | Limit |
|---|---|---|
| Allow background activity | Adds Android power-save/Doze exemption, writes OPPO's explicit allow list, sends Athena its allow policy, publishes an AMS background-protection list, and adjusts background AppOps. | Other cleanup and freezer scenes retain their own rules. Successful execution of every setter was not tested in this investigation. |
| Intelligent background control | Removes explicit allow/prohibit membership, restores default/auth-scope idle membership, and sends Athena its automatic policy. | Returns the app to policy decisions; does not mean “always allowed.” |
| Prohibit background activity | Adds explicit prohibit membership, removes allow and idle-whitelist membership, and sends Athena its prohibit policy. | This is an explicit restriction, separate from whether startup is permitted. |
| Lock in Recents | Participates in cleanup exclusions when that cleanup action enables the lock exception; also excludes apps from the separate package-freezing service's candidates. | Does not exempt every kill action or Hans scene. |
| Allow auto/associate start | Permits specific launch paths and participates in some cleanup/package-freeze exceptions. | Launch permission is distinct from continued execution. Temperature, power-save and permission branches can override treatment. |
| Athena “AlwaysAlive” | Eligible force-stop actions change from cleanup type 2 to special type 3. | It is a different cleanup strategy, not guaranteed process residency. The precise type-3 downstream behavior remains unresolved. |

Battery UI controls were traced from PowerControlFragment to PowerControlPresenter, storage, Athena Binder calls and OplusCommonConfig. UI numeric values, Athena policy values and app-database values use different encodings; they must not be copied between interfaces.

## Why an exception can still freeze

The fresh framework implementation classifies ordinary third-party apps separately from third-party and OPPO whitelisted apps. Normal screen-on/off scenes omit the whitelist target bit. FastFreezer and night-deep-doze scenes include it; deep-sleep inclusion depends on a configuration switch.

Inclusion means **eligible for consideration**, not automatically frozen. The actual normal freeze path checks current app importance before suspending its cgroup and applying network restrictions. Foreground activity is excluded from normal state-machine entry. Audio, recording, foreground-service and traffic protections depend on their effective flags and additional checks; silent audio or merely receiving packets is not a guaranteed exemption.

When scenes combine, protective importance flags are intersected, while target and restriction flags are combined. Usage-based logic can also remove an unused class-2 app from the effective whitelist managed set. These mechanisms explain why list membership alone cannot answer “will this app remain active?”

One specific precedence rule is confirmed: importance-bit configuration applies app-type rules, then exact-package rules, then wildcard `*` rules. Each step adds bits and then removes bits. The wildcard can therefore override an earlier package rule. This is **not** a universal precedence order for all OPPO lists.

## What is already configured on this tablet

AdrenoFloor (`dev.mokomis.adrenofloor`, UID10318) appears in:

- The current explicit `<allow>` list in `/data/oplus/os/battery/allow_prohibit_app.xml`.
- Android's live DeviceIdle user whitelist from the preceding inventory.
- `/data/oplus/os/bpm/bpm.xml` and the Hans `fixedRecord.xml` with `isClick=true`.
- Athena's **live background-protection list**, verified using a source-checked read-only dump.

Thus it already has the main observed background allowances. Adding it blindly to more files is not justified. We did not decode a current Hans per-package managed map, so this does not establish immunity in every scene.

Live Athena reports AlwaysAlive enabled, ready and API available, with whitelist-only mode disabled and cleanup type 3. This corroborates the subsystem's live configuration; it does not prove a particular app meets all eligibility tests or has been treated by it.

## Two misleading file names clarified

- Hans `/data/oplus/os/bpm/fixedRecord.xml` records package/isClick state and is read and written by Athena's HansAppManager (`x/e.java`). It is distinct from startup `fixedRecord.txt`, which records startup decisions and may include disabled decisions.
- Battery `power_consum_opt_status.xml` carries packed optimization/dialog state. A value of `1` is not, by itself, a background-survival whitelist entry.

## What to do with this finding

For an app with missed notifications or a background helper that stops, the useful first controls are **Allow background activity** and the relevant **auto-start/associated-start permission**. Recents lock may provide additional cleanup protection. If that is insufficient, identify the actual stop mechanism before choosing another exemption: force-stop, ordinary process kill, Hans suspension, and package freezing require different remedies.

This investigation did not reproduce an app failure or test a settings change. No specific improvement or never-kill guarantee is claimed. The useful result is knowing which controls have real consumers and where their protection ends.

## Evidence, tool use and coverage

Artifact identities:

- Athena 6.0.1: `de1f6bef173e5d21eadecc4db3056448c9303811a6a4d1c5775d2d7fcb9d60b8`.
- Battery 1.2.9: `a665dd0f7eaf04dd81fa18e124511c4faf8a3e129617852d05d78aaf9157f5d3`.
- `oplus-services.jar`: `bca5f72c4daf7a5aaacd78e5b8f82431cc371169dee6cc7ab42f87170bce2180`.

REA inspected Athena's shipped package graph: Evidence `ev_8fc2761b02e336a0cb07fe9a01e8d0b787b2721ef2efcfa760cb717d38ae862f`, inventory `ev_fc4e482586ba6a1fc1e605e59be69f176272aa04f838d9ecc3b8d5bc9ed55ee6`. Graph inspection does not establish code behavior.

REA's Android method provider was unavailable because its caller-supplied JADX MCP bridge is not configured. Code tracing used the existing JADX installation: fresh Athena decompilation and targeted framework classes; Battery reused cached decompilation after byte-for-byte APK identity verification. No tools were installed. Battery's REA archive inspection rejected case-colliding resource paths; the original APK was preserved and this result was recorded, not bypassed or represented as successful inspection.

Some JADX methods are partial or goto-labelled; exact references and limitations are in the companion findings. Static code describes paths, not observed execution. Source-verified runtime dumps only read background-protection and AlwaysAlive config/state. Hans history is explicitly encrypted; its captured payload was not treated as plaintext current state, and the diagnostic property was left unchanged. Opened REA sessions were closed.

Checklist: battery-choice effects **answered statically**; cleanup/lock differences **answered within traced paths**; Hans scene and importance precedence **answered within traced normal paths**; AdrenoFloor's current major allowance membership **corroborated live**; current Hans per-app effectiveness, every cleanup path, and type-3 downstream semantics **unresolved**.

Detailed sources and line references:

- [Battery policy chain](battery-findings.md)
- [Athena cleanup and keep-alive rules](athena-keepalive-findings.md)
- [Hans scene and exception precedence](hans-findings.md)

Raw evidence and artifact identities are retained in `work/freeze-rea/`.

Provider follow-up: [REA Android bridge repaired and verified](rea-android-bridge-repair.md). The older provider limitation above describes that investigation stage.
