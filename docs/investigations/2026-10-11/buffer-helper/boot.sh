#!/system/bin/sh
DIR=/data/adb/punktfunk-buffer
[ -e "$DIR/disable" ] && exit 0
exec /system/bin/sh "$DIR/daemon.sh"
