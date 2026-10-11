#!/system/bin/sh
# KernelSU boot script (/data/adb/service.d/): keeps two Wi-Fi fixes on the OPPO Pad Mini (OPD2515)
# across reboots. Both live in memory only; the stock driver file is never touched.
#
#  1. Loads a patched copy of the Wi-Fi driver in place of the stock one. The patch (two
#     instructions) makes wlan0 connect as Wi-Fi 7 without multi-link, which stops the firmware
#     narrowing the channel from 320 MHz at light load.
#  2. Raises the Wi-Fi firmware's thermal throttle thresholds from 90/105 C to 118/125 C. One
#     chip sensor returns false single readings of 60-112 C, and at the stock thresholds each one
#     pauses all transmission for ~100 ms. The firmware forgets the setting whenever it restarts,
#     so it is sent again each time Wi-Fi comes up.
#  3. Optional, off unless /data/adb/wifi-fix/ull-flags exists: replaces the driver's flags for
#     Android's low-latency Wi-Fi mode (latency level 4, "ultralow") with the hex value in that
#     file. A patched copy of the driver's ini file is bind-mounted over the original before the
#     driver swap, because the driver reads the ini only when it loads.
#
# Off switch: touch /data/adb/wifi-fix/disable and reboot. Uninstall: delete this file and
# /data/adb/wifi-fix, then reboot.
#
# The driver swap turns Wi-Fi off and on, and Android switches wireless debugging off when
# that happens. To have it switched back on afterwards: touch /data/adb/wifi-fix/keep-adb-wifi
DIR=/data/adb/wifi-fix
LOG=$DIR/log
STOCK=/vendor_dlkm/lib/modules/qca_cld3_wcn7750.ko
PATCHED=$DIR/qca_cld3_wcn7750.nomlo.ko
# The patch offsets belong to this exact stock build; a system update that changes the driver
# must not get the old patched copy.
STOCK_SHA=cf48075da65d6b10e47ddff230807270f522b0358253db8d183c608cdf495a54
PATCHED_SHA=916d50a02c076f33f62cb181487542ab0bb1021f0063f051b6938bbc8b85a6a4
# module 42 = thermal manager, 9 = reconfigure, then Temp1 Temp2 kp ki kd. All five values are
# required: sent without them the firmware takes 0/50 C and holds the radio off until reboot.
THERMAL="42 6 9 118 125 100 20 0"
ULL_FLAGS=$DIR/ull-flags
ULL_KEY=wlm_latency_flags_ultralow

say() { echo "$(date '+%F %T') $*" >> "$LOG"; }
sha() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

# Copies ini $1 to $2 with $ULL_KEY set to $3. The driver stops reading at the line "END", so the
# key goes in just before it, and any existing $ULL_KEY lines are dropped.
make_ini() {
  awk -v line="$ULL_KEY=$3" -v key="$ULL_KEY" '
    { s = $0; sub(/^[ \t]+/, "", s) }
    index(s, key) == 1 && substr(s, length(key) + 1) ~ /^[ \t]*=/ { next }
    !done && s ~ /^END[ \t\r]*$/ { print line; done = 1 }
    { print }
    END { if (!done) print line }' "$1" > "$2"
}

# tests/make-ini-test.sh sources this file to check make_ini
[ -n "$WIFI_FIX_TEST" ] && return 0

mkdir -p "$DIR"
: > "$LOG"
if [ -e "$DIR/disable" ]; then say "disabled by $DIR/disable"; exit 0; fi
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sleep 8

swap_driver() {
  if [ "$(sha "$STOCK")" != "$STOCK_SHA" ]; then
    say "stock driver has changed (system update?) - leaving it in place"; return
  fi
  if [ "$(sha "$PATCHED")" != "$PATCHED_SHA" ]; then
    say "patched driver file missing or altered - leaving stock in place"; return
  fi
  # A crash while loading would reboot the tablet with this marker still here; skip next time
  # rather than loop.
  if [ -e "$DIR/pending" ]; then
    say "the last swap did not finish - skipping it; delete $DIR/pending to try again"; return
  fi
  : > "$DIR/pending"; sync
  was_on=$(settings get global wifi_on)
  svc wifi disable; sleep 6
  if ! rmmod qca_cld3_wcn7750; then
    say "could not unload the stock driver - leaving it in place"
  else
    reloaded=1
    if insmod "$PATCHED" prealloc_disabled=1; then
      say "patched driver loaded"
    else
      say "patched driver refused - reloading stock"
      insmod "$STOCK" prealloc_disabled=1
    fi
  fi
  sleep 3
  [ "$was_on" != 0 ] && svc wifi enable
  rm -f "$DIR/pending"
}

# The ini is a firmware file, read through the firmware search path. Every copy found is covered,
# so it does not matter which directory the loader reaches first.
override_ull_flags() {
  [ -e "$ULL_FLAGS" ] || return
  flags=$(tr -d ' \t\r\n' < "$ULL_FLAGS")
  if ! echo "$flags" | grep -Eq '^0x[0-9A-Fa-f]{1,16}$'; then
    say "ull-flags must hold one hex value such as 0x180D83 - ignoring it"; return
  fi
  found=0
  done_list=" "
  for d in $(tr ',' ' ' < /sys/module/firmware_class/parameters/path 2>/dev/null) \
      /etc/firmware /odm/firmware /vendor/firmware /vendor/firmware_mnt/image /firmware/image; do
    [ -f "$d/wlan/WCNSS_qcom_cfg.ini" ] || continue
    ini=$(readlink -f "$d/wlan/WCNSS_qcom_cfg.ini")
    case $done_list in *" $ini "*) continue ;; esac
    done_list="$done_list$ini "
    copy=$DIR/ini/$(echo "$ini" | tr / _)
    mkdir -p "$DIR/ini"
    if ! make_ini "$ini" "$copy.new" "$flags" || ! [ -s "$copy.new" ]; then
      say "could not write a copy of $ini"; rm -f "$copy.new"; continue
    fi
    mv "$copy.new" "$copy"
    # The copy needs the original's SELinux label, or the firmware loader may not read it.
    chcon "$(ls -Z "$ini" | awk '{print $1}')" "$copy" || say "could not copy the label of $ini"
    if mount -o bind "$copy" "$ini"; then
      say "$ULL_KEY=$flags set in $ini"; found=1
    else
      say "could not mount over $ini"
    fi
  done
  [ "$found" = 1 ] || say "found no Wi-Fi ini to change - low-latency flags left stock"
  ull_set=$found
}

reloaded=0
ull_set=0
override_ull_flags
swap_driver
if [ "$ull_set" = 1 ] && [ "$reloaded" != 1 ]; then
  say "the driver was not reloaded, so the low-latency flags apply from the next driver load"
fi

# Wi-Fi only connects after the first unlock. From then on, send the thresholds each time the
# link comes up.
last=down
first=1
while true; do
  state=$(cat /sys/class/net/wlan0/operstate 2>/dev/null)
  if [ "$state" = up ] && [ "$last" != up ]; then
    sleep 3
    if echo "$THERMAL" > /sys/class/net/wlan0/unit_test_target 2>/dev/null; then
      say "thermal thresholds sent"
    else
      say "thermal thresholds not accepted"
    fi
    if [ "$first" = 1 ]; then
      first=0
      if [ -e "$DIR/keep-adb-wifi" ]; then
        [ "$(settings get global adb_wifi_enabled)" = 1 ] || settings put global adb_wifi_enabled 1
      fi
    fi
  fi
  last=$state
  sleep 5
done
