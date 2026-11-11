#!/bin/sh

# Always-On Mode

COMMON="/mnt/us/btkeepalive/bin/common.sh"
[ -f "$COMMON" ] && . "$COMMON"

CONF_FILE="/mnt/us/btkeepalive/btkeepalive.conf"
if [ -f "$CONF_FILE" ]; then
  . "$CONF_FILE"
else
  notify "BT Keepalive" "Config file missing. Copy btkeepalive.conf to /mnt/us/btkeepalive/"
  exit 0
fi

LOGFILE="${LOGFILE:-/mnt/us/btkeepalive/log/btkeepalive.log}"
mkdir -p "$(dirname "$LOGFILE")"
rotate_log "$LOGFILE" 256

if ! validate_mac "$MAC"; then
  echo "$(date) - [always-on] error: MAC address '$MAC' invalid or not configured" >> "$LOGFILE"
  notify "BT Keepalive" "Device MAC not configured. Use 'Get MAC Address' and edit btkeepalive.conf."
  exit 0
fi

echo "$(date) - [always-on] mode started (target: $MAC)" >> "$LOGFILE"

# Listen for Bluetooth disconnect events without spawning grep subshells
lipc-wait-event -m com.lab126.btfd "*" | while read -r EVENT; do
  case "$EVENT" in
    *Disconnect_Result*)
      echo "$(date) - [always-on] disconnect detected, reconnecting..." >> "$LOGFILE"
      reconnect "$MAC" &
      ;;
  esac
done &
WAIT_PID=$!

# Trap for graceful shutdown on EXIT, SIGINT, or SIGTERM
trap 'kill $WAIT_PID 2>/dev/null; lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null; echo "$(date) - [always-on] sleep deferral released" >> "$LOGFILE"; exit 0' EXIT INT TERM

# Initial connection attempt with retry backoff
reconnect "$MAC" &

# Always-on loop: renew a 900s (15 min) suspend deferral every 300s (5 min)
# If script crashes or is killed ungracefully, Kindle sleeps in max 15 minutes
while :; do
  lipc-set-prop com.lab126.powerd deferSuspend 900 2>/dev/null

  BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
  CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
  if [ -n "$BATT" ] && [ "$BATT" -lt "${THRESHOLD:-20}" ] 2>/dev/null && [ "$CHARGING" != "1" ] 2>/dev/null; then
    echo "$(date) - [always-on] battery low (${BATT}%), stopping keepalive to conserve power" >> "$LOGFILE"
    lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null
    initctl stop btkeepalive 2>/dev/null
    exit 0
  fi
  sleep 300
done
