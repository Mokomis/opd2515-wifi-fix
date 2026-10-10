#!/system/bin/sh
# KernelSU boot script (/data/adb/service.d/): turns wireless debugging back on after a reboot.
# Android switches it off at every boot. This waits for the system and for Wi-Fi (so in practice
# for the first unlock), then sets the
# same switch as Developer options > Wireless debugging. Android still only honours it on a Wi-Fi
# network that was approved for debugging, and only for computers already paired.
LOG=/data/adb/wireless-debugging.log
: > "$LOG"
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
# Wi-Fi only connects once the tablet has been unlocked after the reboot, which may be much
# later, so wait for an address for as long as it takes.
until ip -4 addr show wlan0 2>/dev/null | grep -q inet; do sleep 3; done
# The setting does not always stick on the first try this early in boot, so check and repeat.
for try in 1 2 3 4 5; do
  settings put global adb_wifi_enabled 1
  sleep 5
  if [ "$(settings get global adb_wifi_enabled)" = 1 ]; then
    echo "$(date '+%F %T') wireless debugging on (try $try)" >> "$LOG"
    exit 0
  fi
done
echo "$(date '+%F %T') the setting would not stay on" >> "$LOG"
