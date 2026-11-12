#!/bin/sh
# Enable Always On mode (reconnect after drops + keep the Kindle awake).
# All the logic lives in /mnt/us/btkeepalive/bin/setmode.sh (shared with KOReader).

BTK_BASE="${BTK_BASE:-/mnt/us/btkeepalive}"
if [ ! -f "$BTK_BASE/lib/common.sh" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"btkeepalive folder not found. Copy it to /mnt/us/"}]}}' 2>/dev/null
  exit 1
fi
exec /bin/sh "$BTK_BASE/bin/setmode.sh" always-on
