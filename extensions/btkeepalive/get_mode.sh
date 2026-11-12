#!/bin/sh
# Show the current mode, and whether it is really running.

BTK_BASE="${BTK_BASE:-/mnt/us/btkeepalive}"
if [ ! -f "$BTK_BASE/lib/common.sh" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"btkeepalive folder not found. Copy it to /mnt/us/"}]}}' 2>/dev/null
  exit 1
fi
. "$BTK_BASE/lib/common.sh"
notify "$(status_text)"
