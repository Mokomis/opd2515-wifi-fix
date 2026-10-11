#!/bin/sh
# Checks make_ini from wifi-fix.sh, the step that writes the low-latency flags into a copy of the
# driver's ini. Runs on any computer with sh and awk:
#   sh tests/make-ini-test.sh
# Set AWK_CMD to try another awk, for example AWK_CMD="busybox awk".
cd "$(dirname "$0")/.." || exit 1
WIFI_FIX_TEST=1 . ./wifi-fix.sh
if [ -n "$AWK_CMD" ]; then awk() { $AWK_CMD "$@"; }; fi

T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT
fails=0

check() { # name, input, expected
  printf '%b' "$2" > "$T/in"
  printf '%b' "$3" > "$T/want"
  make_ini "$T/in" "$T/out" 0x3010000180F83
  if cmp -s "$T/out" "$T/want"; then
    echo "ok   $1"
  else
    echo "FAIL $1"; diff "$T/want" "$T/out"; fails=$((fails + 1))
  fi
}

L=wlm_latency_flags_ultralow=0x3010000180F83

check "inserted before END" \
  "gEnableBmps=1\nEND\n\n# notes after END\n" \
  "gEnableBmps=1\n$L\nEND\n\n# notes after END\n"

check "old values dropped, wherever they are" \
  "wlm_latency_flags_ultralow=0x180D83\n  wlm_latency_flags_ultralow =0xc83\nEND\nwlm_latency_flags_ultralow=0x1\n" \
  "$L\nEND\n"

check "similar keys and comments kept" \
  "wlm_latency_flags_ultralow_ext=0x180c03\n# wlm_latency_flags_ultralow=0x0\nEND\n" \
  "wlm_latency_flags_ultralow_ext=0x180c03\n# wlm_latency_flags_ultralow=0x0\n$L\nEND\n"

check "appended when there is no END" \
  "gEnableBmps=1\n" \
  "gEnableBmps=1\n$L\n"

check "Windows line endings" \
  "gEnableBmps=1\r\nwlm_latency_flags_ultralow=0x180D83\r\nEND\r\n" \
  "gEnableBmps=1\r\n$L\nEND\r\n"

check "only the first END counts" \
  "a=1\nEND\nb=2\nEND\n" \
  "a=1\n$L\nEND\nb=2\nEND\n"

[ "$fails" = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
