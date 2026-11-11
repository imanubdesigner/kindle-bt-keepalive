#!/bin/sh
# Show current BT Keepalive mode via Pillow notification

COMMON="/mnt/us/btkeepalive/bin/common.sh"
[ -f "$COMMON" ] && . "$COMMON" || . "$(dirname "$0")/../../btkeepalive/bin/common.sh"

if [ ! -f "$CONFIG_FILE" ]; then
  notify "BT Keepalive" "Current Mode: Disabled (Not configured yet)"
  exit 0
fi

read -r MODE < "$CONFIG_FILE"

STATUS=""
if is_service_running; then
  STATUS=" (Active)"
else
  [ "$MODE" != "default" ] && STATUS=" (Stopped)"
fi

case "$MODE" in
  "reading")
    MSG="Reading Mode$STATUS"
    ;;
  "always-on")
    MSG="Always On Mode$STATUS"
    ;;
  "default")
    MSG="Disabled (Default Mode)"
    ;;
  *)
    MSG="Unknown ($MODE)"
    ;;
esac

notify "BT Keepalive" "Current Mode: $MSG"
