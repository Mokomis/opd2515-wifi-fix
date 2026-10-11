#!/system/bin/sh
# Scoped OPPO version-4 queue pacing; no global display or Cosa policy edits.
DIR=/data/adb/punktfunk-buffer
PKG=io.unom.punktfunk.mokomis
DESC=version-4-punktfunk-buffer-permanent
exec 0>"$DIR/lock"
flock -n 0 || exit 0
[ -e "$DIR/disable" ] && exit 0
echo $$ > "$DIR/pid"
ACTIVE_PID=0
ACTIVE_UID=0
TICKS=0
say() { echo "$(date '+%F %T') $*" >> "$DIR/log"; }
request() { dumpsys oplus_vrr_service frtc "$1" "$PKG" false "$DESC" "$2" "$3" >/dev/null 2>&1; }
reset() {
    if [ "$ACTIVE_PID" != 0 ]; then
        request 0 "$ACTIVE_PID" "$ACTIVE_UID"
        say "reset pid=$ACTIVE_PID"
    fi
    ACTIVE_PID=0
    ACTIVE_UID=0
    echo disabled > "$DIR/status"
}
cleanup() { reset; rm -f "$DIR/pid"; }
trap 'exit 0' TERM INT HUP
trap cleanup EXIT
until [ "$(getprop sys.boot_completed)" = 1 ]; do
    [ -e "$DIR/disable" ] && exit 0
    sleep 2
done
if [ "$(getprop ro.build.fingerprint)" != "$(cat "$DIR/firmware-fingerprint")" ]; then
    say 'firmware changed; skip pending compatibility review'
    exit 0
fi
say 'started; value2 non-strict; foreground only'
while [ ! -e "$DIR/disable" ]; do
    FRONT=$(dumpsys oplus_vrr_service 2>/dev/null | sed -n 's/^    CurrPkgName: //p' | head -n 1)
    PID=0
    UID_VALUE=0
    if [ "$FRONT" = "$PKG" ]; then
        PID=$(pidof "$PKG" 2>/dev/null)
        case "$PID" in ''|*[!0-9]*) PID=0 ;; esac
        if [ "$PID" != 0 ]; then
            UID_VALUE=$(sed -n 's/^Uid:[[:space:]]*\([0-9]*\).*/\1/p' "/proc/$PID/status")
            case "$UID_VALUE" in ''|*[!0-9]*) PID=0 ;; esac
        fi
    fi
    if [ "$PID" = 0 ]; then
        [ "$ACTIVE_PID" != 0 ] && reset
        TICKS=0
    elif [ "$PID" != "$ACTIVE_PID" ]; then
        reset
        if request 2 "$PID" "$UID_VALUE"; then
            ACTIVE_PID=$PID
            ACTIVE_UID=$UID_VALUE
            echo "value2 pid=$PID" > "$DIR/status"
            say "applied value2 pid=$PID uid=$UID_VALUE"
        fi
        TICKS=0
    else
        TICKS=$((TICKS + 1))
        # Refresh this same request if compositor/service state was recreated.
        if [ "$TICKS" -ge 6 ]; then request 2 "$PID" "$UID_VALUE"; TICKS=0; fi
    fi
    sleep 5
done
