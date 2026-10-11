# OPPO Mini follow-up: Wi-Fi, presentation, thermal callbacks

Tablet-side checks continued automatically after the skipped host bitrate experiment. No device settings, driver commands, service state, app state, or thermal policy were changed.

## Wi-Fi low latency: framework path verified, firmware state unresolved

Live `wifi-current.txt` holds both Punktfunk type-4 locks, 70 acquisitions versus 68 releases, attributed to the app UID through WorkSource. The primary client dump reports `mPowerSaveDisableRequests 2`; `iw` reports power save off.

Decompiled current framework artifacts establish the standard lock path: `WifiLockManager` requires connectivity, screen on, and foreground eligibility, then uses `clientMode.setLowLatencyMode` and a reason-2 power-save disable request. `ClientModeImpl.setPowerSave` maintains a bitmask and disables power save whenever that mask is nonzero. `WifiVendorHal` routes latency control through `WifiChipAidlImpl` to `IWifiChip.setLatencyMode(enabled ? 1 : 0)`. This standard boolean HAL path differs from OPPO's `WIFI_LOW_LATENCY` string command numeric levels 1–6.

OPPO's separate game/media controller has connectivity, default-network, SLA, block/veto and game eligibility gates. Its static Qualcomm game path requests level4, optionally remaps to2 when roaming is permitted and issues level6 separately; media uses2, disable1. These are static possibilities, not observed commands during this stream. Its internal working flag can be set even after command failure, so that flag is not acknowledgement evidence.

The loaded driver is `qca_cld3_wcn7750`, driver5.2.1.144V, firmware1.1.0.0.32767.20. Accessible module/sysfs/proc state and retained logs do not expose current WLM mode or effective flags. Debugfs is not mounted. The exact loaded absolute INI remains unresolved. We did not mount debugfs, force a latency level, reload a driver, or send an unverified vendor query. Conclusion: app request, framework route and power-save consequence corroborated; current firmware latency mode still not directly proved.

## Video presentation: mostly regular, occasional gaps

The actual stream SurfaceView, rather than Android UI rendering statistics, yielded 1872 distinct valid presentation timestamps over 13.697 seconds. Display nominal refresh period was6.944444ms (144Hz). Presentation gap median 6.946ms, p99 13.892ms, maximum 41.675ms; 85 gaps exceeded10ms and 11 exceeded20ms. No buffer-clear command was issued.

These short SurfaceFlinger samples show visible scheduling/presentation irregularity but do not identify host, transport, decode, or composition as its cause. They do not measure input or capture-to-display latency. The app's cumulative `gfxinfo`52.19% janky Android UI frames must not be presented as the video stream's drop rate.

## Thermal: callback incompatibility found; throttling cause not established

Recent logs contain repeated `BadParcelableException: Parcel data not fully consumed, unread size: 12` in `IThermalStatusListener` recipients. Debug source-line mapping narrows the rejected parcel to transaction6, `notifyTsensorTemp(int)`: the stub reads one integer, enforces no remaining data, then would invoke the callback. The remaining12bytes prevent that notification from reaching the callback. This supports a sender/receiver parcel-format mismatch for the sensor notification; sender provenance still requires further evidence.

This is not evidence that the principal thermal-status or broadcast callbacks fail. The examined `OplusHoraeThermalHelper` sensor callback is empty, so the demonstrated impact is repeated exception/log overhead rather than proven loss of a useful policy update or a streaming performance defect.

Android reports thermal status2 and cached shell-skin41C/status2. Live HAL readings differ and report their own status0; do not mix cached and live readings or treat the CPU cache near100C as a simultaneous physical measurement. Read cooling devices report state0, CPU scaling maxima equal hardware maxima, and GPU max remains1.225GHz. These snapshots do not show CPU/GPU frequency caps at capture time, but do not exclude intermittent or vendor-specific thermal actions.

## Outcome and remaining work

No evidence justifies a new OPPO scheduling override, forced Wi-Fi latency level, or disabled thermal service. The next diagnostic improvement is synchronizing actual presentation gaps with host frame timestamps and packet arrival, using a low-overhead recorder. The earlier full-rate packet recorder overflowed, so it cannot establish loss or pinpoint gap origin. The host bitrate-cap experiment remains skipped at the user's request.

Evidence: current artifacts and decompiled framework in `work/oppo-investigation/framework/`; loaded driver follow-up in `work/oppo-investigation/wifi-followup/`; runtime snapshots, presentation summaries, and thermal-interface decompilation in `work/wifi-followup/`. Prior native REA paths: `ev_1cf15aa0bf830da94702f9873eb519ec2c7feca5aab003a8d13cce95dc43546a` and `ev_4bf050671cb5e0a26ffef496857916dd2281ed45af0d287f3c25dc8b97a22e2c` establish the command and builder only, not runtime execution.
