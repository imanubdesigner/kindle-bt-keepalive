#!/bin/sh
# Show the last 3 paired Bluetooth devices with their MAC addresses.

BTK_BASE="${BTK_BASE:-/mnt/us/btkeepalive}"
if [ ! -f "$BTK_BASE/lib/common.sh" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"btkeepalive folder not found. Copy it to /mnt/us/"}]}}' 2>/dev/null
  exit 1
fi
. "$BTK_BASE/lib/common.sh"

OUT=$(/bin/sh "$BTK_BASE/bin/paired.sh")
if [ -z "$OUT" ]; then
  notify "No paired devices found.${NL}Pair via Settings -> Bluetooth first."
  exit 1
fi
notify "Paired devices:${NL}$OUT"
