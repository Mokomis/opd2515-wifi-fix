# OPPO game scheduling and Wi-Fi latency level 4 on the OPD2515: source findings

> Device follow-up: [current investigation findings, tests and installed state](investigations/2026-10-11/README.md). This original report remains source-only.

Read-only research on public source code, done without the tablet. Nothing here was measured on a device. The question was how two OPPO and Qualcomm features treat a game-streaming client (package `io.unom.punktfunk.mokomis`) that streams smoothly most of the time but stutters now and then.

## Sources

| Source | Version | How it was read |
|---|---|---|
| [oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845](https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845), branch `oppo/sm8845_b_16.0_pad_mini` | Commit `ffca906`, "Synchronize code for OPPO OPD2515_16.0.6.103(CN01)". Qualcomm WLAN tag `AU_TECHPACK_WLAN.LA.2.0.R3.00.00.00.000.053` | Direct clone. Contains OPPO's CPU modules and Qualcomm's `qcacld-3.0`, `qca-wifi-host-cmn` and `fw-api` with OPPO's changes |
| Qualcomm Wi-Fi HAL (`hardware/qcom/wlan`) | [LineageOS/android_hardware_qcom_wlan](https://github.com/LineageOS/android_hardware_qcom_wlan), branch `lineage-23.2-caf`, merge of `WLAN.LA.1.0.r1-09600-pakala.0` | GitHub mirror. CodeLinaro was blocked by the session's network policy. OPPO's vendor copy may differ |
| Android Wi-Fi service | [LineageOS/android_packages_modules_Wifi](https://github.com/LineageOS/android_packages_modules_Wifi), branch `lineage-23.2` | GitHub mirror. android.googlesource.com was blocked. ColorOS may change it |

The tablet runs `OPD2515_16.0.10.500(CN01)`, which is newer than the kernel source snapshot (`16.0.6.103`). Defaults may have changed in between.

Paths below are relative to the root of the OPPO repository unless a different source is named. Line numbers are for the versions in the table.

## 1. OPPO's game thread scheduling (`game_opt`)

Module: `vendor/oplus/kernel/cpu/game_opt/`, built as `oplus_bsp_game_opt` and shipped for Qualcomm targets (`vendor/oplus/kernel/cpu/oplus_local_modules.bzl`, the `ddk_copy_to_dist_dir` list for `qcom`).

### The kernel does not choose the game

- A userspace service writes the game's process ID to `/proc/game_opt/game_pid` (`game_opt/task_util.c:35`). It must be a process (thread-group leader) ID.
- It writes the render thread IDs to `/proc/game_opt/rt_info` (`game_opt/rt_info.c:453`). All of them must belong to one process.
- Almost every hook returns early unless `have_valid_game_pid` or `have_valid_render_pid` is set by those writes.
- The service is not in the kernel source. Nothing in the source shows whether it would ever register the streaming client. Likely it does not, unless the app is in OPPO's game list.
- Check on the tablet: `cat /proc/game_opt/game_pid` (mode 0664) prints `game_pid=-1 ...` when no game is registered.

### What the kernel measures once a game is registered

The kernel measures and ranks; the userspace service reads the results back and decides.

- **Heavy threads** (`task_util.c`, `heavy_task_info`): CPU run time of each thread in the game process, scaled by current frequency and CPU capacity, sorted, top entries returned with a 0-1024 utilisation.
- **Render-related threads** (`rt_info.c`, `try_to_wake_up_success_hook`, about line 147): a wake-up graph inside the game process. A thread is added when it wakes a render thread or is woken by one (or by a thread named `UnityMain`). Wake-ups from SurfaceFlinger's `app` thread into the game are counted too.
- **UI assist threads** (`task_util.c`, `ui_assist_threads_wake_stat`): threads named `Thread-*` that wake the main thread and are woken by it.
- Reading `rt_info` makes the top-ranked thread the "logic thread" for frame detection and adds tracked threads to a frame-load group. Threads named `binder:`, `HwBinder:`, `AudioTrack` or `NativeThread` are left out of that group (`rt_info.c`, `need_tracked_task`).

### What the kernel boosts by itself

Mostly CPU frequency floors through `freq_qos`, not thread priority (`cpufreq_limits.c:343`, `ch_freq_boost_request`).

- **Heavy task boost** (`task_boost/heavy_task_boost.c`): render thread names are hard-coded to `UnityMain` and `UnityGfx`. A thread that keeps running longer than a frame interval while the render thread is idle gets its cluster's minimum frequency raised. `GC Marker` threads are an exception.
- **Critical task boost** (`critical_task_boost.c`): default thread names `UnityMain` and `UnityGfxDevice`, which userspace can change through `/proc/game_opt/task_boost/critical_task_name`.
- The same module can also cap CPU frequencies (`/proc/game_opt/cpu_max_freq`), so a registered game can be limited as well as boosted.

## 2. OPPO's general scheduler (`sched_assist`), which applies to every app

Module: `vendor/oplus/kernel/cpu/sched/sched_assist/`. Build options for this platform (`canoe`): `vendor/oplus/kernel/cpu/build/defconfig/canoe/sched/sched_configs`.

- **Foreground app threads.** The foreground app's main thread and threads named `RenderThread` count as heavy-load top-app tasks (`sa_common.c:218`, `is_heavy_load_top_task`).
- **Priority inheritance.** A thread blocking an important thread through binder, rwsem, mutex, futex or PI futex inherits its status (`sa_common.h:163`, `enum INHERIT_UX_TYPE`).
- **Affinity calls can be silently skipped.** `CONFIG_OPLUS_FEATURE_BAN_APP_SET_AFFINITY=y` is set. If the system sets `IM_FLAG_FORBID_SET_CPU_AFFINITY` on an app's main thread, that app's `sched_setaffinity` calls are skipped (`sa_common.c:1952`). This matters if the client pins its decode or network threads.
- **Apps may be able to mark their own threads.** `/proc/oplus_scheduler/sched_assist/ux_task_app` (mode 0666, ioctl only) lets a caller with an app UID (10000-19999) set the UX state of threads in its own process (`sa_sysfs.c:477`). Whether SELinux lets a third-party app open the file is not in the kernel source and was not checked.
- **Frame boost** groups are fed by frame start and end calls naming the UI and render threads (`vendor/oplus/kernel/cpu/uad/ua_ioctl/frame_ioctl.c`, `set_ui_thread` and `set_render_thread`). These are presumably made from Android's UI rendering path; the caller is not in the kernel source. A client that sends decoded video straight to a surface may produce few such frames. That is an inference, not traced.

## 3. OPPO's network game modules

- **`vendor/oplus/kernel/wifi/oplus_connectivity_routerboost`**: a netfilter output hook that watches IPv4 UDP traffic from one UID set by a userspace service, and reports new flows and the first 32 packets back to that service. It does not change packets or priorities in the kernel.
- **`vendor/oplus/kernel/wifi/oplus_connectivity_sla`**: marks packets of apps on lists sent from userspace, to steer them between Wi-Fi, a second Wi-Fi link and mobile data. Its built-in game list is seven specific titles (`oplus_connectivity_sla.c:173`).
- Neither acts on an app unless OPPO's closed services list it.

## 4. What Wi-Fi latency level 4 does

### How the level is requested

1. An app holds `WifiManager.WIFI_MODE_FULL_LOW_LATENCY`. Android activates low-latency mode only while the app is in the foreground and the screen is on, unless the app has one of two companion-device exemptions (`WifiLockManager.java:291`, `:539`, `:557`).
2. On activation Android does two things (`WifiLockManager.java:946`, `setLowLatencyMode`):
   - it asks the HAL for low-latency mode;
   - it switches 802.11 power save off (`setPowerSave(..., false)`).
3. Qualcomm's HAL maps `WIFI_LATENCY_MODE_LOW` to `QCA_WLAN_VENDOR_ATTR_CONFIG_LATENCY_LEVEL_ULTRALOW`, which is 4 (`qcwcn/wifi_hal/wificonfig.cpp:1475` in the HAL mirror).
4. The driver honours the power save request (`vendor/qcom/opensource/wlan/qcacld-3.0/core/hdd/src/wlan_hdd_power.c:3085`). It refuses only when "LPC" has disabled power save, and has no OPPO change there.

### Driver path

The paths in this subsection are under `vendor/qcom/opensource/wlan/`.

- `qcacld-3.0/core/hdd/src/wlan_hdd_cfg80211.c:12564`, `hdd_config_latency_level`: accepts levels 1-4 plus two OPPO levels (5 and 6). It subtracts one, so level 4 becomes host level 3, `ULTRALOW`.
- `qcacld-3.0/core/sme/src/common/sme_api.c:7883`, `sme_set_wlm_latency_level`: sends `WMI_WLM_CONFIG_CMDID` with flags `latency_flags[3]`. That is the low 32 bits of the ini setting `wlm_latency_flags_ultralow`.
- The high 32 bits become host-side flags (`qcacld-3.0/components/mlme/core/src/wlan_mlme_main.c`, `mlme_init_fe_wlm_in_cfg`). They are applied in `wlan_hdd_cfg80211.c`, `hdd_set_wlm_host_latency_level`.
- WCN7750 build options are in `qcacld-3.0/configs/canoe_gki_wcn7750_defconfig`:
  - `CONFIG_MULTI_CLIENT_LL_SUPPORT=y` (line 117). The runtime switch `wlm_multi_client_ll` defaults to 0. Either path ends at the same flags for level 4.
  - `CONFIG_DP_SWLM=y` (line 39).
  - `CONFIG_WLAN_CLD_DEV_PM_QOS=y` (line 180).
  - `WLAN_FEATURE_LL_MODE` is not set. So `wlan_hdd_set_wlm_mode`, which compares a host level against the userspace value 4, does nothing in this build.

### OPPO's default flags and what they mean

`qcacld-3.0/components/mlme/dispatcher/inc/cfg_mlme_fe_wlm.h:389`: `CFG_DEFAULT_ULTLOW_FLAGS "0x180D83"`. The comment above it still says Qualcomm's documented default, `0xc83`. The tablet's ini file can override the value; that file is not in the kernel source.

Bit meanings come from the comment block in that header and from `fw-api/fw/wmi_unified.h` (layout comment at about line 42207, macros at 42305-42337).

| Bits | Value in `0x180D83` | Meaning |
|---|---|---|
| 0 | 1 | Firmware suppresses scan requests from Android |
| 1 | 1 | Scans skip DFS channels |
| 2-3 | 0 | Default scan dwell time |
| 6-7 | `10` (value 2) | Roam only on final beacon miss; no signal-based roaming |
| 8 | 1 | With multi-link, final-beacon-miss roaming only when all links report it |
| 9 | 0 | Firmware power save (BMPS) not disabled by this flag. Android disables power save separately, see above |
| 10 | 1 | CSS power collapse disabled |
| 11 | 1 | System sleep disabled |
| 19 | 1 | `WLM_FLAGS_PS_IS_PCIE_L11_ENABLED`: PCIe L1.1 allowed, going by the macro name |
| 20 | 1 | `WLM_FLAGS_PS_IS_PHYRF_PS_ENABLED`: PHY/RF power save allowed, going by the macro name |
| 32-63 | 0 | No host-side change: no CPU wake-up latency vote (48), no high bus bandwidth vote (49), receive thread kept (32), no low-latency receive queue routing (33), receive aggregation (FISA) kept (34), transmit batching (SWLM) kept (40) |

What the firmware does when bits 19 and 20 are clear is not in the source.

### Other effects

- The receive-aggregation disable request for the latency manager (`CTRL_RX_AGGR_ID_WLM`) only takes effect if `dp_wlm_rx_aggr_control` is set, which defaults to off (`qcacld-3.0/components/dp/dispatcher/inc/wlan_dp_cfg.h:1482`).
- At connection setup the driver gives the firmware per-level latency targets of 100 / 60 / 40 / 20 ms for normal / XR / low / ultralow (`qcacld-3.0/core/wma/src/wma_dev_if.c:3118`).
- The level is kept across disconnects, because `wlm_latency_reset_on_disconnect` defaults to 0. It is re-applied when the interface is recreated.
- OPPO's extra levels 5 and 6 use `wlm_latency_flags_low_ext` (`0x184c03`) and `wlm_latency_flags_ultralow_ext` (`0x180c03`). Level 6 is like 4 but allows normal roaming. Only the legacy (non-multi-client) path reads these extended flags.
- Setting level 3 (or OPPO's level 5) also sends an OPPO uevent `forcestbc=...enable=True` (`wlan_hdd_cfg80211.c`, end of `hdd_config_latency_level`).

### Where the driver reads the ini

- OPPO changed the path to `wlan/WCNSS_qcom_cfg.ini` (`qcacld-3.0/core/hdd/inc/wlan_hdd_misc.h:45-50`).
- It is loaded with `request_firmware` once per driver load, in `hdd_context_create`.
- The parser stops at a line `END` (`qca-wifi-host-cmn/qdf/src/qdf_parse.c:116`).
- A key that appears again later overrides the earlier value.

## 5. What this repository does with it

`wifi-fix.sh` has an optional override, off unless `/data/adb/wifi-fix/ull-flags` exists. It writes a copy of every `wlan/WCNSS_qcom_cfg.ini` found on the firmware search path with `wlm_latency_flags_ultralow` set to the file's value, and bind-mounts it over the original before the driver reload. The README suggests `0x3010000180F83`: OPPO's value plus bits 9, 40, 48 and 49. `tests/make-ini-test.sh` checks the ini rewrite. See the README section "Optional: stronger low-latency mode".

## Not verified

- Whether OPPO's game service registers the client, and whether ColorOS changes Android's or Qualcomm's low-latency path.
- Whether the streaming client holds `WIFI_MODE_FULL_LOW_LATENCY`. The client's source was not read.
- SELinux access to `/proc/oplus_scheduler/sched_assist/ux_task_app` and `/proc/game_opt`.
- Which CPUs the PM QoS vote covers in the `CLD_DEV_PM_QOS` variant this build compiles (`hdd_pm_qos_update_cpu_mask` in `qcacld-3.0/core/hdd/src/wlan_hdd_main.c`).
- The tablet's actual ini values, and whether the firmware loader reads the bind-mounted copy.
- Firmware behaviour behind each flag; the firmware is closed source.

## Questions for a reviewer

1. Is the reading of bits 19 and 20 right, or does setting them mean something other than "allowed"?
2. Does anything in ColorOS or the vendor HAL override Android's power save request while the low-latency lock is held?
3. Is the bind mount in `wifi-fix.sh` reached by `request_firmware` on a GKI kernel with Android's ueventd firmware fallback?
4. Are bits 40, 48 and 49 a sensible addition for a 60-144 fps game stream over UDP, given the tablet's thermal problems?
