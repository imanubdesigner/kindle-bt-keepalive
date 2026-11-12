#!/bin/sh
# Write a diagnostics report to btkeepalive/log/diagnostics.txt.

BTK_BASE="${BTK_BASE:-/mnt/us/btkeepalive}"
if [ ! -f "$BTK_BASE/lib/common.sh" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"btkeepalive folder not found. Copy it to /mnt/us/"}]}}' 2>/dev/null
  exit 1
fi
. "$BTK_BASE/lib/common.sh"

/bin/sh "$BTK_BASE/bin/diagnose.sh" > /dev/null 2>&1
notify "Diagnostics saved to:${NL}btkeepalive/log/diagnostics.txt${NL}${NL}$(status_text)"
