#!/system/bin/sh
# Samples the Wi-Fi downlink width five times a second. Run on the tablet (root not needed):
#   sh sample.sh <seconds>
# Each line is "<width> <rate in Mb/s>", for example "320MHz 5764.8". The last line is the
# average received rate. Count how often the width changes between lines.
N=$(( $1 * 5 )); i=0; b0=$(cat /sys/class/net/wlan0/statistics/rx_bytes); t0=$(date +%s)
while [ $i -lt $N ]; do
  iw dev wlan0 link | grep "rx bitrate" | sed 's/.*bitrate: //' | awk '{print $3, $1}'
  i=$((i+1)); sleep 0.2
done
b1=$(cat /sys/class/net/wlan0/statistics/rx_bytes); t1=$(date +%s)
echo "RXMBPS $(( (b1-b0)*8/1000000/(t1-t0) ))"
