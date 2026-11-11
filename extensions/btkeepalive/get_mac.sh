#!/bin/sh
# Get paired Bluetooth device MAC addresses and show via Pillow notification.
# Displays up to the last 3 paired devices with sanitized names.

COMMON="/mnt/us/btkeepalive/bin/common.sh"
[ -f "$COMMON" ] && . "$COMMON" || . "$(dirname "$0")/../../btkeepalive/bin/common.sh"

CONFIG_FILE="${SYSTEM_BT_CONF:-/var/local/zbluetooth/bt_config.conf}"

if [ ! -f "$CONFIG_FILE" ]; then
  notify "BT Keepalive" "No paired devices found. Pair via Settings -> Bluetooth first."
  exit 1
fi

# Parse config file using awk to safely isolate MACs and Names per section
DEVICES=$(awk '
  /^\[([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\]$/ {
    if (mac != "") {
      printf "%s%s\n", mac, (name != "" ? " (" name ")" : "")
    }
    mac = substr($0, 2, length($0) - 2)
    name = ""
  }
  /^Name = / && mac != "" {
    name = substr($0, 8)
    gsub(/["\\]/, "", name)
    name = substr(name, 1, 30)
  }
  END {
    if (mac != "") {
      printf "%s%s\n", mac, (name != "" ? " (" name ")" : "")
    }
  }
' "$CONFIG_FILE" | tail -3)

if [ -z "$DEVICES" ]; then
  notify "BT Keepalive" "No paired devices found. Pair via Settings -> Bluetooth first."
else
  # Format multi-line list for notification
  FORMATTED=$(echo "$DEVICES" | tr '\n' ',' | sed 's/,$//' | sed 's/,/ | /g')
  notify "BT Keepalive" "Paired devices: $FORMATTED"
fi
