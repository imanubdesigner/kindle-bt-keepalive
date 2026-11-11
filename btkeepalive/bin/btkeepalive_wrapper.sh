#!/bin/sh
# Wrapper script to start the correct mode on boot via Upstart.
# Reads mode from /mnt/us/btkeepalive/config.conf and execs the
# appropriate btconnect.sh. Called exclusively by the Upstart job.

BIN_DIR="$(dirname "$0")"
COMMON="$BIN_DIR/common.sh"
[ -f "$COMMON" ] && . "$COMMON" || . "/mnt/us/btkeepalive/bin/common.sh"

LOGFILE="$BASE_DIR/log/wrapper.log"
mkdir -p "$BASE_DIR/log"
rotate_log "$LOGFILE" 256

echo "$(date) - [wrapper] started" >> "$LOGFILE"

# Read mode from config; default to disabled if file missing or value unknown
if [ -f "$CONFIG_FILE" ]; then
  read -r MODE < "$CONFIG_FILE"
else
  MODE="default"
fi

echo "$(date) - [wrapper] mode=$MODE" >> "$LOGFILE"

case "$MODE" in
  "reading"|"always-on")
    # Verify btkeepalive.conf exists and MAC is valid before spawning daemon
    if [ ! -f "$CONF_FILE" ]; then
      echo "$(date) - [wrapper] error: $CONF_FILE missing, exiting cleanly" >> "$LOGFILE"
      notify "BT Keepalive" "Config file missing. Copy btkeepalive.conf to /mnt/us/btkeepalive/"
      exit 0
    fi
    . "$CONF_FILE"
    if ! validate_mac "$MAC"; then
      echo "$(date) - [wrapper] error: MAC address '$MAC' invalid or not set, exiting cleanly" >> "$LOGFILE"
      notify "BT Keepalive" "Device MAC not configured. Use 'Get MAC Address' and edit btkeepalive.conf."
      exit 0
    fi

    if [ "$MODE" = "reading" ]; then
      exec /bin/sh "$READING_SCRIPT"
    else
      exec /bin/sh "$ALWAYS_ON_SCRIPT"
    fi
    ;;
  *)
    echo "$(date) - [wrapper] default or disabled mode, stopping service" >> "$LOGFILE"
    exit 0
    ;;
esac
