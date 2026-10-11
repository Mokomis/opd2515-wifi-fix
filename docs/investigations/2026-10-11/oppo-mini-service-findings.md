# OPPO Pad Mini: service and scheduling investigation

Investigated October 10, 2026 on connected OPD2515, ColorOS OPD2515_16.0.10.500(CN01). Device collection was read-only. User started the game stream; no tablet settings, files, drivers, service configuration or root modules were changed. REA/Ghidra analysis used existing local installations through per-command environment variables; Codex configuration was unchanged.

## Main findings

- Punktfunk is already registered with game_opt: foreground PID 21202 equals game_pid 21202, child_num=20. Idle snapshot was -1. Registration by itself does not establish useful boosting.
- Punktfunk holds two type-4 low-latency Wi-Fi locks; a live iw query reports Power save: off. Both are attributed to package io.unom.punktfunk.mokomis, UID10317, even though one lock tag ends in stream-hp.
- Normal app frame group 6 contains the main thread and Android RenderThread. The game frame group is empty. Group membership does not establish the native video pipeline is optimized.
- Live ui_first_black includes Punktfunk and Moonlight variants. KeyThreadManager skips its key-thread UX machinery for members. These additions are absent from the pulled built-in filter file; origin is unresolved.
- Current key_thread defaults match Chromium/WebView threads, not the native Punktfunk decode/demux names. Removing blacklist membership alone would not establish the desired native-thread treatment.
- Actual UAh/URCC resource configuration was decrypted and decoded locally. GPU nap-disable requests also force clock/rail on. Avoid treating that as equivalent to a modest frequency floor.
- Installed ODM Wi-Fi INI ultralow flags are 0x180c83, differing from the public source default. The loader-selected INI is unresolved. SLA/game marking was off during the captured stream.

## Measured live scheduler snapshot

Main/render/native key threads had CPU affinity mask 0-7. Native client/demux/data/Tokio worker threads had ordinary scheduler policy 0 and prio112; Android main/render prio110. The AAudio callback had policy1/prio97. Affinity masks alone do not prove a requested affinity was rejected. Per-thread UX bits remain unresolved.

Game CPU minima were zero and maxima INT_MAX across CPUs; heavy and critical task boost switches were zero. Critical task names remained UnityMain and UnityGfxDevice. These are snapshots, not a trace of transient boosts or stutter causation.

## Best next experiments

1. Trace and temporarily test a narrow native-thread rule for the measured bottleneck, comparing package blacklist membership and exact thread rules as separate variables. Verify actual UX/frame group membership before evaluating latency.
2. Map UAh numeric resource events to callers before using a URCC request. Test the lowest GPU floor that holds the decode budget; preserve thermal and power management.
3. Establish the loaded Wi-Fi config and successful HAL latency request before testing a flag change. The low-latency lock is already present, so an additional lock is unnecessary.
4. Keep Routerboost/SLA lower priority until app flow ownership and AP support are established. Current disabled marking does not prove a missing performance benefit.

No A/B tuning trial was performed and no performance improvement is claimed.

## Framework evidence



# Framework scheduling findings (read-only)

Device fingerprint: OPPO/OPD2515/OP6548L1:16/BP2A.250605.015/B.c211d9_18fbf06_18beffd:user/release-keys.
Current oplus-services.jar sha256 bca5f72c4daf7a5aaacd78e5b8f82431cc371169dee6cc7ab42f87170bce2180; oplus-framework.jar 3b47a02bec547b3218f8a9ff94e11bb443e985b9b980314a9e0bedd82df8af78. Both exactly match saved Sept22 artifacts. services.jar freshly pulled (sha256 live 7aae9691a99870a4f20b2ca72b0fd5810770acc9a635ad184f5663025bf0132b). Decompiled with existing jadx 1.5.6; no installation/config changes.

## Confirmed blacklist consumer
KeyThreadManager.java:533-538 createOriginalStat tests membership in ui_first_black and returns DISABLED_UX_STAT immediately. It never examines the text ShutdownGameUIFirst in this path. Lines173-176 and192-193 prevent UX updates when the sentinel is present. Lines409-414 also stop process-start processing for disabled stats. This blocks that manager's key-thread UX machinery, not all game registration or all normal frame groups.

The current live filter has Punktfunk and several Moonlight variants in ui_first_black, values ShutdownGameUIFirst and status4. Parent found no such entries in stock /system_ext/etc/sys_filter_list.json; provenance of the runtime additions is not established. Status4 encoding was not traced, so do not assert who added them.

Live key_thread filter (dynamic-filter.txt:432-447) has only wildcard, Antutu and Dianping. Wildcard rules match Chromium/WebView Chrome_InProcGp, Chrome_IOThread, CrRendererMain, Chrome_ChildIOT; member rules match Compositor/VizWebView/VizCompositor/VizCompositorTh/CrGpuMain/VizVSync. No Punktfunk-specific rule. Removing blacklist membership alone cannot imply dedicated native network/decode treatment: default group patterns are Chromium-focused.

## Normal frame group already works
Live /proc/oplus_frame_boost/info during foreground stream: MULTI FRAME GROUP[6] contains main PID21202 and RenderThread TID2319, both tgid21202 state0x81 depth0. GAME FRAME GROUP empty. No state bits were independently decoded.
FBAppManager.java:1424-1429 registers main and RenderThread in moveToTop using nativeOfbCfgFrameTask. Lines1645-1649 handleThreadAdded can add extra threads to its group. Package extra-thread rules come from ofb (line620), presets ofb_app_para(line766). Normal registration survives the KeyThreadManager blacklist in this live stream.
GlThreadManager.java:973-977 loads gl_thread_ux per-app rules. Lines359-371 apply Utils.ctrlThreadUx but explicitly omit main and main render threads in that function. OplusUIFirstManager legacy setUxThreadValue and setUxThreadValueByFile are empty; active ctrlUxThreadValueByFile calls nativeCtrlThreadUx.

## Other callers
OplusGameOptManager wrapper routes notifyGameInfo, setKeyThread, notifySchedFrameTime etc to vendor.oplus.hardware.gameopt.IGameOptHalService/default. No actual app registration caller proven in framework wrappers; native gameopt service traced separately.
GameOifaceManager and OifaceManager route bindGameTask(type,tid) and game list access to oplusoiface. android.media.OifaceBindUtils sends one-way Binder transaction7 for task binding; demonstrated framework caller RingtoneManagerExtImpl, not video decoder proof.
OplusCpuKeyThreadSch uses Process.setThreadAffinity but only selects system_server threads; property ro.config.cpukeyset.enable read empty. It is not evidence of streaming client affinity enforcement.

## Limitations and next useful experiment
Direct per-task ux_state/im_flag proc nodes do not exist on this build; actual per-thread UX bits remain unknown. No writes, no reboot, no settings changes, no reads of /proc/game_opt/rt_info. Compare package exemption and targeted native thread rules only as controlled benchmark after tracing relevant rule interpretation. Compare latency/jitter and power/thermals, because boosting/capping effects cannot be inferred from registration alone.



# URCC/UAh native investigation

Read-only connected-tablet collection from OPD2515 ([local ADB endpoint omitted]); no tablet settings or files changed.

## Observed identity
- `/odm/bin/hw/vendor.oplus.hardware.urcc-service`, running PID 2084; AIDL `vendor.oplus.hardware.urcc.IUrcc/default`, vendor.oplus.urcc.started=1.
- Executable routes resource request/release to URCC and also resolves `uahResCtlRequestBypass`.
- `/odm/lib64/liburcccore.so` SHA256 6f2cfb4b43f832a9fb90432ea9995d9ebd0adda3f4cd8980989722fa689f3009.
- `/odm/lib64/libuahcore.so` SHA256 8853da1beaedefff70aea1c46f5c3f9e6007c958cdd61fdafad5c6c43ae0cf78.
- Actual stock config `/odm/etc/uah/uahconfig.pb`; `/odm/etc/urcc` absent; `/data/vendor/uah/SavedData.pb` present; library references `/data/vendor/uah/uahconfig.pb` override path (precedence not yet traced).

## REA findings
1. `UrccCpu::schedBoostApply` at 0x17787c; Evidence `ev_c19e48fb57ded4f4a9eb21381c04cf5c533fd6949baaeaa8856434a937ab3668`. Request-selected node receives requested value. For nonzero request with prior nonzero release value, writes negative previous value before new request. This is arbitration, not evidence of a specific app boost.
2. `decode_aes` at 0x1d1664; Evidence `ev_d22d722bde04376a8fbee6fd3303e8b9e2b787c36b44aeb3e5708efecc4ade62`. AES-128-OFB with embedded constants. Offline decrypted stock config and successfully decoded its protobuf wire representation with protoc. Local files `uahconfig-decoded.pb` and `uahconfig-decoded.txt`.
3. `UrccGpu::gpuDisableGpuNapApplyFunc` at 0x178668; Evidence `ev_23ad9afe40a76904783b1f26ab9d1edaf978aac1c364ce2e2b08b9976cfbd7fa`. Writes value 1 to resource IDs 0x1020010 (force_clk_on), 0x1020040 (force_rail_on), and 0x1020000 (force_no_nap). Raises resource 0x1020030 (idle_timer) only when requested integer exceeds current integer. Does not write force_bus_on in this function. Generic nap request therefore also forces clock/rail, increasing power scope beyond a frequency floor.

## Actual configuration controls
Decoded config maps:
- 16846992 -> `/proc/sys/walt/sched_boost`, `UrccResOptManager::applyAnyway, UrccCpu::schedBoostApply`.
- 16848512 -> `/proc/game_opt/disable_cpufreq_limit`, default string 0; several config actions request 1 (event interpretation unresolved).
- 16908480 -> `/sys/class/kgsl/kgsl-3d0/min_clock_mhz`, `UrccResOptManager::applyAnyway, UrccGpu::resApplyDirectly`. GPU event IDs 31, 32, 56 request 301; event 84 requests 500. These numeric event IDs need enum/framework caller mapping before trigger claims.
- Other scheduler nodes include `sched_assist_enabled`, `ux_task`, frame_boost_stage_enabled, WALT migration/RTG/utilization governors, core_ctl, CPU min/max frequencies.
- Stock decoded config contains no literal `punkt`, `limelight`, or `moonlight` (bounded literal search only; this does not establish no default/dynamic policy applies).

## Passive snapshot and limits
- disable_cpufreq_limit=0, sched_assist_enabled=`enabled=3`, top-app cpu.uclamp.min=0.00.
- min_clock_mhz=195, max_clock_mhz=1225; min_pwrlevel=16, max_pwrlevel=0; force_no_nap/force_clk_on/force_bus_on/force_rail_on all 0; idle_timer=80.
- Config's old `/sys/class/kgsl/kgsl-3d0/devfreq/min_freq` and max_freq absent. `/sys/class/devfreq/3d00000.qcom,kgsl-3d0` exists but requested min/max/cur attributes absent. Effective `min_clock_mhz` path exists.
- Snapshot is no proof of streaming-session latency or dynamic ownership. Stock config can explain URI/resource arbitration but event-trigger mapping and current policy requests remain unresolved.

Recommendation: preserve per-app resource ownership and investigate event dispatch before changing floors; avoid generic disable-nap boosts. Read the existing GPU-floor module's relationship to UAh requests; smallest measured per-app floor remains a better controlled experiment than forcing rail/clock indefinitely.



# OPPO Wi-Fi and network runtime findings

Read-only capture from adb [local ADB endpoint omitted]. No configuration, app launch, or driver changes.

## Observed
- `dumpsys-wifi.txt` lines 477-481: empty held Wi-Fi locks; 50 low-latency acquisitions, 50 releases. Lines 984-998: 2,738,357 ms historical low-latency active time (~45.6 min). History does not identify owning application.
- Wi-Fi feature list advertises LOW_LATENCY. Device snapshot in idle mode.
- `/proc/sys/net/oplus_sla/oplus_sla_enable`=0, `game_mark`=0; `/proc/sys/net/oplus_game_first/s_game_uid`=0, rx_first=1, tx_first=1. No writes performed.
- Native OPPO Wi-Fi AIDL service running PID 2088; Qualcomm Android Wi-Fi service PID 1980. wifi_qos_daemon init service exists but is stopped.
- Properties: ro.oplus.wifi.llm.media_boost=true; ro.oplus.wifi.routerboost.mscs=true; ro.oplus.wifi.ull.tx_bw20=true. These establish configured capability, not runtime activation.
- ODM config `odm-wcnss.ini` lines 155 and 158: ultralow=0x180c83, low=0x184c83. XR flag occurs twice, line 112=0x200080083 and line 161=0x3. Vendor wcn7750 INI lacks latency flag declarations. No INI/driver bind mount found in captured mount listing.
- `network-config.txt` contains live OplusNetworkStack dpiconfig version 2026021301. Its OPLUS_DPI_APPS allowlist does not contain Punktfunk or Moonlight. SLA runtime disabled, so lack of list membership alone does not show a current lost optimization.
- Pulled `/odm/bin/hw/vendor.oplus.hardware.wifi-aidl-service` as `oplus-wifi-service.elf`. Strings identify handleLowLatencyModeCmd, build_qcom_low_latency_mode_msg, build_qcom_mcc_low_latency_quota_msg, and WIFI_LOW_LATENCY. This establishes code candidates; it does not prove a call happened.
- Qualcomm HAL `libwifi-hal-qcom.so` exports/string-references wifi_set_latency_mode and driver unsupported response.

## Live streaming follow-up
- User confirmed stream running. `dumpsys-wifi-streaming.txt` lines 484-485 show two held type=4 locks attributed by WorkSource to UID 10317, io.unom.punktfunk.mokomis: punktfunk:stream-ll and punktfunk:stream-hp. The hp tag still uses low-latency type=4. Acquired/released=56/54. Thus app lock acquisition is directly confirmed.
- SLA enable/game_mark/game_first UID remain 0 during stream. No explicit latency-mode log was found in last 5000 log lines.
- REA trace Evidence ev_d6b6bb1b810d4b9e44dbdc5485ce5924fa772fdf349356c76b7cd81d8a9140c2 maps handleLowLatencyModeCmd literals to OplusWifiService::executeDriverCommand at 0x13fda0. Native helper decompilation underway.

## Unresolved
- Historical acquisitions remain unattributed; current Punktfunk low-latency lock ownership is confirmed. Actual HAL/driver mode and power-save consequence require trace.
- Which INI the loaded driver actually consumed and duplicate XR parse precedence.
- Framework caller and flags passed to OPPO native low-latency helper; requires focused disassembly/framework tracing.
- Routerboost activation and MSCS/AP compatibility. Enabled property does not show requests or successful router negotiation.
- Latency/power/heat effect of candidate flags: no A/B runtime experiment performed.

## Follow-up targets
Trace handleLowLatencyModeCmd in native Wi-Fi executable and framework calls in Oplus Wi-Fi/network service code. Record a passive Wi-Fi dump while user has an existing Punktfunk stream running; do not force global low-latency mode based on this idle sample.

## Native command decompilation
REA Evidence ev_1cf15aa0bf830da94702f9873eb519ec2c7feca5aab003a8d13cce95dc43546a (`rea-driver-command.json`, readable `driver-command.c`): OplusWifiService::executeDriverCommand recognizes WIFI_LOW_LATENCY, parses exactly three space-separated tokens, initializes nl80211, takes token 2 as interface and atoi(token 3) narrowed to unsigned byte as mode, builds and sends Qualcomm netlink message. No separate power-save override is present in that branch. Caller-selected level is not hardcoded there. Ghidra warns type propagation did not settle; data-flow around parse/build/send is explicit.

## Native low-latency builder
REA Evidence ev_4bf050671cb5e0a26ffef496857916dd2281ed45af0d287f3c25dc8b97a22e2c (`rea-low-latency-builder.json`, `low-latency-builder.c`): builder accepts numeric modes 1 through 6 (unsigned range check), packages supplied value unchanged as u16 attribute 0x37 in vendor-data attribute 0xc5, vendor ID 0x1374, vendor subcommand 0x4a via nl80211 vendor command 0x67. It does not map everything to standard level 4 and does not set latency-flags or a separate power-save attribute. Thus vendor controller can request levels 5 or 6 in addition to level 4. The request in the observed stream is not established by this static path. Power-save changes that the driver/firmware interprets from a selected level and INI bits remain unresolved.

Investigation state: current lock ownership answered, static native command/build path answered, current SLA/game-first registration answered. Exact caller mode, selected INI, routerboost negotiation and measured latency/power consequence remain unresolved; no tuning performed.


## Capture index

Key local investigation files: stream-state.txt, stream-thread-state.txt, stream-game-policy.txt, stream-gpu-thermal.txt, dynamic-filter.txt, stock-sys-filter.json, services.txt, processes.txt and native-maps.txt. Detailed intermediate evidence remains in the chat workspace under work/oppo-investigation. REA Evidence IDs and binary identities appear in the sections above.


## Additional direct capture

stream-power-save.txt: `iw dev wlan0 get power_save` reported `Power save: off` during the user-started stream. This proves reported interface power-save state at capture time, not all chip/PCIe/PHY sleep states. stream-gpu-thermal.txt: GMU floor -1, ordinary GPU floor195MHz, gpuclk589MHz, kgsl temp48400 and Android thermal status0. Cached thermal sensor readings differ and are not treated as synchronized physical measurements.


## Game controller: REA native trace

The installed /odm/bin/hw/vendor.oplus.hardware.gameopt-service SHA256 is 64452d2b2fad6820b7f3d508ffd2c57ab160ae672dfc49e96162fee7866345f3. REA/Ghidra literal trace of /proc/game_opt/game_pid returned complete matches/references without truncation, Evidence ev_810dd179020b0c3bd151131090a93b202de68aa5ae9464f461cc1871bb25ff15. Referencing native functions include DataWriter::writeProcessId (0x43ff38), SceneSchedulerCenter::sceneSchedulerOn (0x388870), SceneSchedulerCenter::handleMessage (0x38bb74), TaskManager::monitorTaskLoad (0x1a9dc0), and TaskManager::stopGameZone (0x1a1580). This connects the dedicated shipped gameopt service to the kernel registration interface. Exact upstream application notification/authorization chain and transient thread selection remain untraced.

The current stream already registers successfully, so manual writes to game_pid are not a justified next fix.
