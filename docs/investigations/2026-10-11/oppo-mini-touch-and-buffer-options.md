# Mini touch-rate and display-buffer investigation

> Historical investigation stage. Later runtime results and the current installed state are indexed in [README](README.md).

2026-10-11. Continued from the Cosa performance report using matching shipped artifacts, REA/JADX and REA/Ghidra, and the connected Mini. Touch was tested temporarily; every write was restored. No Cosa database, app performance profile, APK, persistent property, or display-buffer configuration was changed.

## Touch: faster delivered events confirmed

The Mini's vendor touch HAL supports node182 on device0. Legacy nodes26/180 and device1 were unsupported in the bounded capability queries. Nodes183/245/246 on device0 were also supported. The matching shipped Java interface establishes Binder transaction2 as support query,3 as read,4 as write. Framework support means a positive integer result, not merely a successful Binder response.

The running service is `/odm/bin/hw/vendor-oplus-hardware-touch-V2-hbp5-service`; its process maps load Goodix GT9966 panel libraries under `/odm/firmware/tp/ivy` and use `/dev/hbp0`. This explains why generic `/proc/touchpanel` recipes do not match this device.

Cosa's verified performance policy at display144 selects level9, which its enum converter translates to RATE288 ordinal5 and writes to node182 when supported. Standard automatic policy selects level14, translated to RATE144 ordinal 12. The panel's actual custom configuration maps ordinal 12 to value 15 and ordinal5 to28. XML comments are generic and inconsistent with actual array values; they were not used to claim a hardware frequency.

Two continuous physical-finger captures demonstrate the delivered difference:

| Condition | HAL readback | Touch frames | Median interval | Mean delivered rate |
|---|---|---:|---:|---:|
| Original | `12,15` | 2,256 | 6.630 ms | 150.83 Hz |
| Temporary RATE288 selection | `5,28` | 4,111 | 3.639 ms | 274.83 Hz |

Each capture window was 15 seconds. The higher-rate capture's p5/p95 intervals were 3.632/3.646 ms; readback remained 5,28 after the capture. Intervals are kernel `SYN_REPORT` timestamps from physical finger movement on touchpanel `/dev/input/event3`, filtered to positive intervals under 30 ms. They measure delivered touch reports, not raw controller scans or end-to-end app latency. The screen's foreground app remained the existing Punktfunk app; its code or rendering was not changed or investigated.

The first attempted higher-rate capture had zero events and was inconclusive. It was restored before asking the user to begin dragging explicitly; the repeated capture yielded the 4,111-frame measurement above. A subsequent 5-second restored capture also had no finger events; restoration is confirmed by HAL readback, not by a third cadence measurement.

Test method: a brief direct HAL write using the exact Cosa selection, with a 25-second automatic restore plus a `finally` restore. Both tests restored ordinal 12, and post-watchdog/final reads returned 12,15. Touch activity mode and idle-hold settings were not changed. No permanent helper or background script was installed; the watchdogs expired.

### What can be used

The faster path is available now, without changing firmware. A normal Cosa performance selection with active touch control can request this same rate. The tested direct write proves the hardware path, but not that every Game Assistant UI/profile combination selects it; app transitions and policy can overwrite a direct request. A lasting per-app solution should use Cosa's profile or a foreground-aware mechanism that restores the previous value on exit. A global boot-time forced rate was not applied.

The interval shrank by about 3 ms, which can reduce the wait until the next input report. Actual app responsiveness, controller input, power use, and thermal effects were not measured. In particular this does not speed up an external gamepad's own polling.

There is no basis for forcing a bigger advertised rate: the shipped mapping sends RATE360 and RATE720 ordinals 6/7 to hardware value 12, while the tested RATE288 selection uses 28. Those other settings were not tested; their labels are not proof of higher hardware capability. Cosa's performance and X-mode touch mappings are identical at 144 Hz, so X-mode is not shown to offer a further touch increase.

## Display-buffer control

The Java request path and Mini runtime support are confirmed in `work/cosa-rea/buffer-followup.md`. Global FRTC is enabled, but every string column of the captured Cosa database lacked `ogfr_enable`/`sf_cf_enable`. Cosa's version4 path sends a per-process integer request and strict flag through the VRR service to SurfaceFlinger transaction 22017. Default requested value 1 is reset to 0 outside eligible play. Neither 1 fps nor total single-buffer rendering follows from those numbers.

REA/Ghidra now confirms the exact receiver. SurfaceFlinger `OplusFRTC::setFrameRateTarget` at `0x40912c` accepts positive version4 values 1 or 2 when global FRTC and OGFR stabilization are enabled; 3 and above are explicitly rejected. Value 0 releases the matching request and removes it, provided the feature gates still permit the release path. The Mini's live VRR configuration enables the exact native stabilization gate's sender setting: its second config integer reaches native field offset 0x61 through transaction 22027/subcode 1. Native readback of that flag was not measured.

The active request produces a per-process graphics event type 4 carrying the requested value. Release emits type 0/value 0. Application/monitor matching and other requests can affect activation. Thus the shipped Mini supports this control, but the downstream client's interpretation of value 1 and its total buffer depth remain unresolved. This is a real candidate for a per-app experiment, not an established single-buffer mode.

No buffer request has been issued, and no latency benefit is claimed. Any eventual test must trace the client's event handling, establish accepted active state, and measure queued-frame age, producer waits and missed display deadlines, with an automatic reset to 0 before changing any feature gate. Merely increasing FPS or receiving a Binder success is insufficient. Full source and limits: [buffer follow-up](buffer-followup.md).

## Evidence retained

`work/cosa-rea/touch-comparison.json`, raw touch captures/statistics, HAL capability/readback files and temporary-test logs retain runtime evidence. `touch-post-watchdog.txt` and `touch-final-readback.txt` confirm restoration. Config/library inventories and copies are alongside them.

- Native service SHA256 `9711802e12a9a31cbecdaecf28bbc6966de6b85e56946ab0ed6d38fbeab4edbc`.
- Shipped touch-V2 Java interface SHA256 `c0d7a99d9d8405dd59378c2889df8bc5b14062e20de4c8d9e953f92a4e9bba86`.
- Panel config SHA256 `ed6274af96c3bea1c103864f581d83455934ce3a6847917ce5209acf6053c9c1`.
- Cosa enum conversion REA `ev_9e52d4d722da3654663662ce3c124ef80858f481864c30f18584d01e71870e39`; performance mapping `ev_8ddad703bed67a7930c5a95001be1ea6c25c39aa934e4b815eda0ae18676cdcb`.
- REA/Ghidra native string inventory `ev_4f93ca932bbf20a76763f91c8bdd0679903451ea805ee3734900b8bf4cad4592`; native setter dossier `ev_30e087d3fc16f960ee4d213e28fe65a1d3efe7c6fd546cb2edb2c3939d098222`; AIDL write transport dossier `ev_6ffee0f3bb98339be79827867545b7c8befd376edcf60464ab52006cd3e76e5b`. These are static evidence and do not substitute for the delivered-event capture.
- SurfaceFlinger receiver/constructor/activation semantics: `ev_9f2e8cac8bddf5bf5427937bf627e06f989f959145b373853a17ce73c8145c1f`, `ev_78b0d1779ccc41e6d6b893064269a873e3d3f308e2b369945761edea89aa3536`. Exact native stabilization config parser: `ev_c2ca62840125cef7c7bcaa518c9de11fc395896d9e12e11318a469385109c9a0`. Matching SurfaceFlinger SHA256 `cf485097c8ff5c5d5bebc0456f452f9fb45f03f3af36067b964180f48a78f47e`. The owned native session was closed after preserving its evidence snapshot.

Status: higher touch cadence answered with runtime evidence; permanent per-app UI setup and its power/latency tradeoff remain untested. Buffer route, receiver validation/reset and configured gate answered; downstream client total-buffer semantics and useful effect require further tracing. Exploration produced one tested touch option and one supported but untested buffer candidate; no permanent tweak was applied.
