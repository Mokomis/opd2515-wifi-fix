#!/system/bin/sh
# Makes the patched Wi-Fi driver for the OPPO Pad Mini (OPD2515) from the tablet's own stock
# driver. Run as root on the tablet:  su -c 'sh make-patched-driver.sh'
#
# It copies the stock module, changes two instructions in the copy and checks the result. The
# stock file is only read. No driver file is shipped with this repository.
#
#   sh make-patched-driver.sh [stock.ko] [output.ko]
STOCK=${1:-/vendor_dlkm/lib/modules/qca_cld3_wcn7750.ko}
OUT=${2:-/data/adb/wifi-fix/qca_cld3_wcn7750.nomlo.ko}
# Driver 5.2.1.144V from ColorOS OPD2515_16.0.10.500(CN01). The offsets below are only right
# for this exact file.
STOCK_SHA=cf48075da65d6b10e47ddff230807270f522b0358253db8d183c608cdf495a54
PATCHED_SHA=916d50a02c076f33f62cb181487542ab0bb1021f0063f051b6938bbc8b85a6a4

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
word() { od -A n -t x1 -j "$2" -N 4 "$1" | tr -d ' \n'; }
die() { echo "stopped: $*" >&2; exit 1; }

[ -r "$STOCK" ] || die "cannot read $STOCK"
[ "$(sha "$STOCK")" = "$STOCK_SHA" ] || die "$STOCK is not the driver this patch was made for (see README, After a system update)"

mkdir -p "$(dirname "$OUT")" || die "cannot create the output folder"
cp "$STOCK" "$OUT" || die "cannot write $OUT"

# offset, bytes expected there, bytes to write (little-endian AArch64 instructions)
#  hdd_open_adapters_for_mission_mode: b.ne +12 (54000061) -> b +12 (14000003)
#  wlan_vdev_set_dot11mode:            cbnz w8, +12 (35000068) -> b +12 (14000003)
patch() {
  [ "$(word "$OUT" "$1")" = "$2" ] || { rm -f "$OUT"; die "unexpected bytes at offset $1"; }
  printf '\003\000\000\024' | dd of="$OUT" bs=1 seek="$1" conv=notrunc 2>/dev/null \
    || { rm -f "$OUT"; die "write failed at offset $1"; }
}
patch $((0x4a8234)) 61000054
patch $((0x3e1650)) 68000035

[ "$(sha "$OUT")" = "$PATCHED_SHA" ] || { rm -f "$OUT"; die "the patched file does not have the expected checksum"; }
chmod 600 "$OUT"
echo "patched driver written to $OUT"
