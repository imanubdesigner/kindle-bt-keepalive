#!/bin/sh

# Reading Mode

CONFIG_FILE="/mnt/us/btkeepalive/btkeepalive.conf"
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"Config file missing. Copy btkeepalive.conf to /mnt/us/btkeepalive/"}]}}'
  exit 1
fi

mkdir -p "$(dirname "$LOGFILE")"

echo "$(date) - reading mode started" >> "$LOGFILE"

lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
  if echo "$EVENT" | grep -q "Disconnect_Result"; then
    lipc-set-prop com.lab126.btfd Connect "$MAC" 2>/dev/null
    echo "$(date) - disconnect detected, reconnected immediately" >> "$LOGFILE"
  fi
done &

lipc-set-prop com.lab126.btfd Connect "$MAC" 2>/dev/null

wait $!
