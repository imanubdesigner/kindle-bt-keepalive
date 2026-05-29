#!/bin/sh

# Always-On

CONFIG_FILE="/mnt/us/btkeepalive/btkeepalive.conf"
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  lipc-set-prop com.lab126.pillow pillowAlert '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"Config file missing. Copy btkeepalive.conf to /mnt/us/btkeepalive/"}]}}'
  exit 1
fi

mkdir -p "$(dirname "$LOGFILE")"

trap 'lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null; echo "$(date) - sleep prevention released (trap)" >> "$LOGFILE"' EXIT

echo "$(date) - always-on mode started" >> "$LOGFILE"

lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
  if echo "$EVENT" | grep -q "Disconnect_Result"; then
    lipc-set-prop com.lab126.btfd Connect "$MAC" 2>/dev/null
    echo "$(date) - disconnect detected, reconnected immediately" >> "$LOGFILE"
  fi
done &

lipc-set-prop com.lab126.btfd Connect "$MAC" 2>/dev/null

lipc-set-prop com.lab126.powerd deferSuspend 86400 2>/dev/null
echo "$(date) - sleep prevention set (24h)" >> "$LOGFILE"

while :; do
  BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
  CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
  if [ "$BATT" -lt "${THRESHOLD:-20}" ] 2>/dev/null && [ "$CHARGING" != "1" ] 2>/dev/null; then
    lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null
    echo "$(date) - battery at ${BATT}%, sleep prevention removed, exiting" >> "$LOGFILE"
    exit 0
  fi
  sleep 600
done
