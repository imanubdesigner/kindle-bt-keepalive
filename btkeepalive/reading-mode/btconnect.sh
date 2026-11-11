#!/bin/sh

# Reading Mode

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
  echo "$(date) - [reading] error: MAC address '$MAC' invalid or not configured" >> "$LOGFILE"
  notify "BT Keepalive" "Device MAC not configured. Use 'Get MAC Address' and edit btkeepalive.conf."
  exit 0
fi

echo "$(date) - [reading] mode started (target: $MAC)" >> "$LOGFILE"

# Listen for Bluetooth disconnect events without spawning grep subshells
lipc-wait-event -m com.lab126.btfd "*" | while read -r EVENT; do
  case "$EVENT" in
    *Disconnect_Result*)
      echo "$(date) - [reading] disconnect detected, reconnecting..." >> "$LOGFILE"
      reconnect "$MAC" &
      ;;
  esac
done &
WAIT_PID=$!

# Trap for graceful shutdown on EXIT, SIGINT, or SIGTERM
trap 'kill $WAIT_PID 2>/dev/null; exit 0' EXIT INT TERM

# Initial connection attempt with retry backoff
reconnect "$MAC" &

wait "$WAIT_PID"
