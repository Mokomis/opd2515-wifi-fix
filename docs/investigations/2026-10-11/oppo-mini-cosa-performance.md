# Cosa performance controls — OPPO Mini

Follow-up: [Mini touch-rate and buffer options](oppo-mini-touch-and-buffer-options.md) now confirms a temporary touch-control test increased delivered reports from about 151 to 275 Hz and was restored. The original read-only pass below predates that experiment.

Inspected 2026-10-11 using the repaired REA Android provider. Read-only investigation; no tablet settings, databases, modes, or apps were changed. One read-only `feature_list` provider query was issued after tracing its implementation.

## Findings

1. **System high-performance mode and Cosa game performance mode are separate controls.** The tablet snapshot has `high_performance_mode_on=1`, while Cosa's database has both `performance_model_kind_new_key=0` and `performance_model_kind_key=0`. Touch and resolution selections are both 1. This establishes saved settings, not the current in-memory game state. Cosa's common feature maps modes 0/1/2 to Android GameManager standard/battery/performance (1/3/2), subject to its compatibility gate. Enabling the system setting alone does not prove Cosa's performance selection is enabled.

2. **Touch speed is a concrete mode-dependent path.** `setPerformanceValue(mode, resolution, touch)` saves separate selections and broadcasts three separate events. PerformanceSetting selects the saved-mode touch level when touch selection is zero; otherwise mode 2 uses perfLevel, mode 3 uses xModeLevel, and other modes use the ordinary level. At display refresh 144, automatic ordinary level is 14 (RATE144); performance and X-mode level are 9 (RATE288). At 120 Hz, performance/X level is RATE240. These are requested settings, not measured sampling rates or guaranteed latency improvements. The device must support the corresponding touch HAL node (182 or legacy 26); Cosa checks each node before writing it. `/proc/touchpanel` is absent, so generic phone proc-node tweaks are not applicable without further tracing. The vendor touch HAL service does exist; its supported nodes and actual sampling rate remain unverified.

3. **Cosa contains a display-buffer control, but the captured model defaults do not enable it.** The parser requires `ogfr_enable` with `sf_cf_enable`; the boolean defaults false. When configured, it sends desired buffer count and strict-mode state through `IOPlusRefreshRate.setFrameRateTargetControl(..., "version-4-cosa")`. It clears the request outside foreground play, during frame insertion, and under some frame-stability conditions. Both model config rows in the snapshot lack that enabling decision. Individual app overrides were not exhaustively checked; this is not proof the feature is globally inactive. There is no measured benefit justifying enabling it.

4. **Advanced options depend on model/app policy, not just the visible button.** The modern performance command uses an OPPO OS-version or policy gate. Automatic performance requires `resv_9.switch=1` in default/common model configuration; neither captured model row supplies it. The default model simple_client explicitly enables automatic touch-rate selection and extra touch handling. Therefore automatic touch selection and automatic performance are different features. Additional LingXi boost code exists, but its configuration and support were not established for this device.

5. **Performance events also reach native GPA and app-specific ADP decisions.** GPA's subscriber forwards the mode to its native bridge; ADP selects a different `ega_config` value for mode 2 but returns early without a game ID/config. These paths do not establish fixed CPU/GPU frequency changes for every app. Exact native resource requests remain unresolved.

## Evidence and reproducibility

Installed APK `/product/app/COSA/COSA.apk` SHA256 was checked on the tablet and matches the existing local `local project/oppo-re/cosa/COSA.apk`: `19c50073113f3b46839970d2ea8c0cf282ff29502ffc8138145eb58f063d704e`. Matching existing decompiled source was reused for navigation; focused methods were independently decompiled through REA with complete Java output and no fallback.

- Exported mode setter: `ev_63ac6e719d82286166732ec8a5348ef62d5a9aa57116576b3152c557db12e06f`.
- Touch mode selection: `ev_d60aa755aaa8ea63c01381c31facacfc753b78f9416de4373bf9efbd0bef95ce`.
- Performance/X refresh mapping: `ev_8ddad703bed67a7930c5a95001be1ea6c25c39aa934e4b815eda0ae18676cdcb`, `ev_cc85655fadeb6c75b7b87edfb65b37bfbaea1227db93b28043a905455a28f7b0`.
- Touch-rate enum conversion: `ev_9e52d4d722da3654663662ce3c124ef80858f481864c30f18584d01e71870e39`.
- Buffer request conditions: `ev_65fb856a6870ef12f1b6a4a7c970f333739489964a570b213c3b2bab07f21152`.
- Supported command gates: `ev_17cd99e14c57e31215f976f99737945263279699a9e9dd3a7db11cf8203c3dac`.
- Model simple_client parser: `ev_5c8fa05f930ad0cfdc729a4d8ad680b5100da9f10452f040916fa76a781c9231`.

Raw REA evidence, model rows, saved settings and local database/WAL snapshot are under `work/cosa-rea`. Database and WAL were copied sequentially while the service stayed running, so this is a best-effort snapshot, not a transactional backup. No relevant LocalLogBean or retained logcat entries were found in the bounded queries. The live feature-list provider returned success, but Android's command-line formatter printed a lazy list placeholder, so its contents were not decoded and are not claimed as verified support.

Source navigation under the matching Cosa decompile: `COSAExportedImpl.setPerformanceValue/getSupportFeature`; `GameOptFeature.onSettingsChange`; `PerformanceSetting.b/c/d/e/f/g/r/v/x/y`; `y8.a` buffer-message handler; `g8.a` compatibility mode mapping; `h8.a` GPA subscriber; `y8.c` ADP decisions; `q6.e.e/g` support gates. Framework touch arbitration appears in `ColorTouchNodeManagerService`: a nonzero Cosa request takes precedence over another caller's report-rate request. Its hardware node capability still needs runtime verification.

## Status and useful next step

Mode-to-policy tracing answered at the Cosa Java layer. Device saved policy verified. Exact Game Assistant visible labels/call site, actual touch sampling, individual app overrides, and native CPU/GPU resource effects remain partially answered or unresolved. No tweak applied.

The strongest next experiment is a reversible comparison of Cosa standard versus performance while keeping the display and touch selections fixed, observing the vendor touch HAL's supported nodes and accepted readback first. This could establish a real touch benefit without pursuing streaming-app timing again. Do not write arbitrary phone touch proc paths or edit the running Cosa database to force the result.
