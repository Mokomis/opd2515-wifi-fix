# Wi-Fi stall and width fixes for the OPPO Pad Mini

Investigation closed: [final recommendations and retained state](docs/investigations/2026-10-11/final-recommendations.md). The optional buffer helper is disabled.

Additional OPPO scheduling, display-buffer, touch and background-policy research: [current findings index](docs/investigations/2026-10-11/README.md).

Two fixes for the Wi-Fi 7 radio of the **OPPO Pad Mini OPD2515** (Qualcomm WCN7750), and a boot script that keeps both across reboots. They remove short transmit pauses that happen about ten times a minute, and stop the link dropping from 320 MHz to 80 MHz whenever traffic is light. Both showed up as audio dropouts, lost video frames and flicker when streaming games to the tablet.

> [!WARNING]
> This needs root. It loads a modified copy of the Wi-Fi driver into the running kernel and raises the temperature at which the Wi-Fi chip protects itself. It was tested on one tablet, on one firmware build. A mistake with the firmware command can take Wi-Fi down until the next reboot. Use it at your own risk.

## The two problems

### 1. A temperature sensor that glitches

The Wi-Fi chip has seven temperature sensors. On this tablet six read a steady 38 to 40 °C. The seventh reads the same, except that a single sample now and then comes back as 60 to 112 °C.

The firmware's thermal manager starts throttling at 90 °C. Each false reading above that makes it pause all transmission until the next sample reads normal, 15 to 100 ms later. That happens about ten times a minute, also when the tablet is idle.

**When you notice it:** anything that needs a steady stream of packets. In a game stream it was audio patched over in 100 ms pieces and bursts of lost video. A fast ping from the tablet shows it without any game: replies stall for about 100 ms three to six times a minute, with nothing lost.

**The fix:** one firmware command raises the throttle thresholds from 90 / 105 °C to 118 / 125 °C, above the false readings. The sensor still glitches; the firmware no longer acts on it.

```sh
echo "42 6 9 118 125 100 20 0" > /sys/class/net/wlan0/unit_test_target
```

`42` is the thermal manager, `9` is "reconfigure", and the five numbers after it are the two thresholds and the controller's three gains (stock: `90 105 100 20 0`). The setting lives in firmware memory, so it is lost when Wi-Fi is switched off, the driver reloads or the tablet reboots.

**This only holds while the tablet is fairly cool.** The false readings ride on top of the chip's real temperature. With the chip at 38 to 40 °C they peaked at 112 °C, under the new threshold. After a long session that heated the chip to 57 to 62 °C, one read 119 °C, crossed 118 °C, and the pauses came back. See [When the tablet is hot](#when-the-tablet-is-hot).

> [!CAUTION]
> Always send all five values. Sent without them, the firmware takes thresholds of 0 and 50 °C and keeps the radio paused until the tablet is rebooted.

### 2. A link that narrows at light load

On a Wi-Fi 7 network the tablet connects as a multi-link device, even when it uses a single link. In that mode the firmware's multi-link power-save module picks the channel width every 100 ms from how busy the tablet's own traffic is. Light traffic gets 80 MHz; heavy traffic gets 320 MHz.

Measured with steady UDP sent to the tablet:

| Traffic | What the link does |
|---|---|
| 0 to 100 Mb/s | Stays at 80 MHz |
| 400 Mb/s | Switches between 80 and 320 MHz about twice a second |
| 1,100 Mb/s | Holds 320 MHz |

**When you notice it:** traffic that is bursty or sits in the middle. A game stream showing a still desktop, a loading screen or a frame-rate-capped game sends little, the link narrows, and the next burst arrives on an 80 MHz link that cannot carry it. That showed as flicker and dropped frames.

No setting turns this off. Power save off (`iw dev wlan0 set power_save off`) did not change it, and neither did the driver's power-save options. Forcing Wi-Fi 6E stops it, but gives up 320 MHz and was too slow for the stream.

**The fix:** connect as Wi-Fi 7 *without* multi-link. The width module belongs to multi-link, so a plain Wi-Fi 7 connection is left at 320 MHz. Newer versions of Qualcomm's driver have a setting for this (`gEnablePrimaryStaMloCap=0`); the build on this tablet does not. Two instructions in the driver are changed to get the same result:

| Function | Change | Effect |
|---|---|---|
| `hdd_open_adapters_for_mission_mode` | The branch around `params.is_ml_adapter = true` is always taken | `wlan0` is created without multi-link |
| `wlan_vdev_set_dot11mode` | The branch past "MLD address zero, limit to 11AX" is always taken | A connection without multi-link keeps Wi-Fi 7 instead of being held to Wi-Fi 6 |

The first change alone gives a Wi-Fi 6E connection at 160 MHz. Both are needed for 320 MHz.

The driver module on this tablet is not signed and the kernel does not require signatures, so the modified copy loads with `insmod`. The stock file on the vendor partition is never written to.

## Results

Width changes in 30 seconds, sampled five times a second:

| Driver | Traffic | Width changes | Link |
|---|---|---|---|
| Stock | 400 Mb/s | 53 and 59 | 80 ↔ 320 MHz |
| Stock, power save off | 400 Mb/s | 50 | 80 ↔ 320 MHz |
| Patched | 400 Mb/s | 0 and 0 | 320 MHz |
| Patched | 200 Mb/s | 0 | 320 MHz |
| Patched | idle | 0 | 320 MHz |
| Patched, loaded by the boot script after a reboot | 400 Mb/s | 0 | 320 MHz |

Transmit pauses, from a 50-per-second ping on the tablet for one minute:

| Thresholds | Stalls of about 100 ms | Longest reply |
|---|---|---|
| Stock 90 / 105 °C | 3 to 6 | about 106 ms |
| 118 / 125 °C, three runs | 0 | 18 ms |
| 118 / 125 °C, set by the boot script after a reboot | 0 | 31 ms |

One game session with both fixes, about four minutes at 441 to 832 Mb/s, against earlier sessions of the same length without them:

| | Without | With both |
|---|---|---|
| Audio patched over | 510 to 700 ms | 10 ms |
| Video loss events | 13 to 14 | 5 |
| Frames dropped | not recorded | 0 |

A separate temperature sensor on the board next to the Wi-Fi chip stayed at 33.6 to 34.6 °C through every false reading.

### When the tablet is hot

All the results above were taken with the Wi-Fi chip's working sensors at 38 to 40 °C. They do not hold on a hot tablet.

After about 15 minutes of streaming with the GPU held at a high clock, the board sensor read 51 °C and the chip's working sensors 57 to 62 °C. Sensor 6 then gave a false reading of 119 °C. That is above the raised 118 °C threshold, so the firmware throttled transmission again:

| Chip temperature | Highest false reading seen | Stalls in the ping probe |
|---|---|---|
| 38 to 40 °C | 112 °C | 0 in three one-minute runs |
| 57 to 62 °C | 119 °C | 2 of about 290 ms in 30 seconds |

The firmware log showed the same sequence as before the fix: sensor 6 as the hottest sensor, then a mitigation command. In the same log the sensors' own error flags stayed at zero, so the firmware does not recognise the reading as false.

What follows from this:

- The fix depends on how hot the tablet runs. Anything that heats it (a high GPU clock floor, charging while playing, a warm room) narrows the margin.
- Raising the thresholds further would cover a hotter chip, but 125 °C is the stock upper threshold, and going past it leaves the chip without its own heat protection. That was not tried.
- The Wi-Fi board data on the tablet has a field named `invalid_Bits_Mask` beside the thermal thresholds. By its name it would take a faulty sensor out of the list, which would be the proper fix. That reading is a guess from the name, and it has not been tried.

## Install

You need the OPPO Pad Mini OPD2515 on ColorOS `OPD2515_16.0.10.500(CN01)` (Wi-Fi driver `5.2.1.144V`), rooted with KernelSU or another root that runs scripts from `/data/adb/service.d/`.

1. Copy `make-patched-driver.sh` and `wifi-fix.sh` to the tablet.
2. Make the patched driver from the tablet's own stock driver:

   ```sh
   su -c 'sh make-patched-driver.sh'
   ```

   It refuses any driver file other than the one it was written for, and checks the result. The output is `/data/adb/wifi-fix/qca_cld3_wcn7750.nomlo.ko`.
3. Install the boot script and reboot:

   ```sh
   su -c 'cp wifi-fix.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/wifi-fix.sh'
   ```

After the reboot, unlock the tablet; Wi-Fi only connects after the first unlock. `/data/adb/wifi-fix/log` should then show `patched driver loaded` and `thermal thresholds sent`.

To use only the temperature fix, skip step 2. The script leaves the stock driver in place when the patched file is missing and still sends the thresholds.

## What the boot script does

- Waits for boot, then switches Wi-Fi off, unloads the stock driver, loads the patched copy and switches Wi-Fi back on. That takes about 20 seconds.
- Skips the swap if the stock driver's checksum has changed, if the patched file is missing or altered, or if a previous swap did not finish. A failed load puts the stock driver back.
- Sends the thresholds every time the Wi-Fi link comes up, because the firmware forgets them.
- Android switches wireless debugging off when Wi-Fi goes off. Create `/data/adb/wifi-fix/keep-adb-wifi` if you want the script to switch it back on after the swap. Without that file it does not touch the setting.

- If `/data/adb/wifi-fix/ull-flags` exists, changes what Android's low-latency Wi-Fi mode does before the driver swap. See [Optional: stronger low-latency mode](#optional-stronger-low-latency-mode).

`wireless-debugging.sh` is a separate, optional boot script that switches wireless debugging back on after every reboot. It is not needed for the fixes.

## Optional: stronger low-latency mode

This part is untested on the tablet. It is off unless you create the file below.

An app that holds Android's low-latency Wi-Fi lock (`WifiManager.WIFI_MODE_FULL_LOW_LATENCY`) while it is in the foreground with the screen on gets two things:

- Android switches 802.11 power save off.
- Qualcomm's Wi-Fi HAL asks the driver for latency level 4, "ultralow".

What level 4 does comes from one driver setting, `wlm_latency_flags_ultralow`. OPPO's driver source sets it to `0x180D83`. The tablet's ODM ini sets `0x180c83`, the same except that bit 8 (multi-link beacon-loss roaming) is clear; which ini the loaded driver uses was not resolved. With either value:

- Android's scan requests are suppressed, and scans skip DFS channels.
- The tablet roams only after losing the access point's beacons, not because the signal is weak.
- Two chip-level sleep states are disabled.
- Nothing changes on the tablet side. The CPUs may still enter deep idle, and the driver keeps batching outgoing packets.

The boot script can replace that value. Put a hex value in `/data/adb/wifi-fix/ull-flags` and reboot:

```sh
su -c 'echo 0x3010000180F83 > /data/adb/wifi-fix/ull-flags'
```

`0x3010000180F83` is the source default plus four bits. It was worked out before the device ini was read, so it also sets bit 8. A value preserving that bit would be `0x3010000180E83`, but neither experimental override is recommended or tested on this tablet. The four added bits are:

| Bit | Effect |
|---|---|
| 9 | Firmware power save off. Android already does this when it sets level 4, so this only covers the case where it does not |
| 40 | Stop batching outgoing packets (the driver's "SWLM") |
| 48 | Keep CPUs out of deep idle (a CPU wake-up latency vote; which CPUs it covers was not traced) |
| 49 | Ask for high memory bus bandwidth |

These bits only take effect while an app holds the low-latency lock. The bit meanings come from the comments in `cfg_mlme_fe_wlm.h` and the firmware header `wmi_unified.h` in OPPO's source.

How it works: the driver reads its ini file `wlan/WCNSS_qcom_cfg.ini` only when it loads. The script writes a copy of every such file it finds on the firmware search path, adds the new value before the file's `END` line, and bind-mounts the copy over the original before it reloads the driver. The copies are kept in `/data/adb/wifi-fix/ini/`. If the driver swap is skipped, the driver is not reloaded and the log says the flags apply from the next driver load.

To check that it applies:

- `/data/adb/wifi-fix/log` should show `wlm_latency_flags_ultralow=0x3010000180F83 set in ...`.
- While your app streams, `dumpsys wifi | grep "Current operation mode"` should print `4`, which means the low-latency lock is active. Without it, this setting does nothing.

What it costs: keeping the CPUs out of deep idle uses more battery and makes more heat, and heat is what brings the thermal pauses back (see [When the tablet is hot](#when-the-tablet-is-hot)). Compare stutter and chip temperature with and without the file.

To turn it off, delete `/data/adb/wifi-fix/ull-flags` and reboot.

## Turn off or remove

- Off: `touch /data/adb/wifi-fix/disable`, then reboot.
- Remove: delete `/data/adb/service.d/wifi-fix.sh` and `/data/adb/wifi-fix`, then reboot.

Nothing on a system partition is changed, so a reboot without the script is stock.

## After a system update

If an update replaces the Wi-Fi driver, the script notices the new checksum, leaves the new driver alone and only sends the thresholds. `make-patched-driver.sh` will refuse the new file too, because its offsets no longer apply.

Check the new driver first for the setting that makes the patch unnecessary:

```sh
grep -a -c gEnablePrimaryStaMloCap /vendor_dlkm/lib/modules/qca_cld3_wcn7750.ko
```

If that prints a number above zero, try `gEnablePrimaryStaMloCap=0` in the driver's ini file instead. Otherwise the same two branches have to be found again in the new file. OPPO publishes the driver source at [oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845](https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm8845), branch `oppo/sm8845_b_16.0_pad_mini`.

## Check it yourself

- **Pauses:** on the tablet, `ping -i 0.02 -c 3000 <a wired computer>`. Look for replies near 100 ms among replies of a few milliseconds.
- **Width:** run `tests/sample.sh 30` on the tablet while `tests/udpload.py <tablet> 400 30` runs on a wired computer, and count how often the width changes.
- **Sensors:** `echo "42 1 7" > /sys/class/net/wlan0/unit_test_target` makes the firmware print all seven readings to its own log.

## What was not tested, and what it costs

- **It stops working on a hot tablet.** See [When the tablet is hot](#when-the-tablet-is-hot). The measurements in this README were taken cool.
- **The chip's own protection starts later.** With the thresholds at 118 / 125 °C, a Wi-Fi chip that really overheats is throttled 28 °C later than stock. The board sensor beside it never passed 35 °C here, on one tablet.
- **Battery.** The patched driver keeps the link at 320 MHz when idle, where stock drops to 80 MHz to save power. The cost was not measured.
- **Multi-link is gone.** The tablet no longer uses two bands at once. On the network used here it never did.
- One tablet, one firmware build, one router (a TP-Link Deco mesh on 6 GHz). No other OPPO, OnePlus or realme device was tried. The sensor fault may be a defect of this one unit.
- The firmware command numbers are not documented. Module 42's sub-commands 1 and 9 are the only ones identified; do not try others.
- The low-latency flags override has not been run on the tablet. Its file rewrite is checked by `tests/make-ini-test.sh` on a computer, not with Android's own `awk`. Whether the firmware loader reads the bind-mounted copy is untested. OPPO's source is from build `16.0.6.103`, older than the build above. A device read found `0x180c83` in the ODM ini; whether that file is loaded and overrides the built-in default is unresolved; see [the investigation findings](docs/investigations/2026-10-11/oppo-mini-service-findings.md).
- `wifi-fix.sh` here differs from the tested copy in one way: switching wireless debugging back on is now behind the `keep-adb-wifi` file. `make-patched-driver.sh` was run on a computer against a copy of the stock driver, where it reproduced the tested file's checksum. It was not run on the tablet.

## How it was found

Stream statistics showed audio being patched in 100 ms pieces at a regular rhythm, on a link with no reported loss. A fast ping from the tablet showed the same 100 ms stalls with no stream running, and a wired computer pinging the same target showed none, which put the cause in the tablet. The Wi-Fi firmware's own log then showed a thermal controller line with `max_temp=101degC`, followed by a transmit pause, each time.

The width switching was found first and suspected of causing the stalls. Fixing it removed the flicker at light load and left the stalls unchanged, so they are two separate problems.

## Other tools for this tablet

Separate root utilities for the OPPO Pad Mini OPD2515. Each works by itself.

- [Wi-Fi 7 Toggle](https://github.com/Mokomis/WiFi-7-Toggle): enables or restores the tablet's 6 GHz / Wi-Fi 7 band capability. The width fix assumes Wi-Fi 7 is enabled.
- [Low-latency audio](https://github.com/Mokomis/opd2515-low-latency-audio): lets chosen apps use Android's low-latency audio paths.
- [Refresh Manager](https://github.com/Mokomis/opd2515-refresh-manager): lets any app use 144 Hz, or locks an app to 60, 120 or 144 Hz.
- [GPU Clock Floor](https://github.com/Mokomis/adreno-clock-floor): holds the Adreno GPU clock at a chosen minimum.

## License

GPL-3.0-only. See [LICENSE](LICENSE). The patched driver is made on the device from the device's own file; no OPPO or Qualcomm file is distributed here.
