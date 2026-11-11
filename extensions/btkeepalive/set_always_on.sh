#!/bin/sh
# Enable Always On Mode:
#   1. Validates configuration
#   2. Writes "always-on" to config.conf
#   3. Installs/updates Upstart job
#   4. Cleanly restarts service
#   5. Verifies running state and alerts user

COMMON="/mnt/us/btkeepalive/bin/common.sh"
[ -f "$COMMON" ] && . "$COMMON" || . "$(dirname "$0")/../../btkeepalive/bin/common.sh"

LOGFILE="$BASE_DIR/log/wrapper.log"
mkdir -p "$BASE_DIR/log"
rotate_log "$LOGFILE" 256

# Ensure configuration is present and MAC is valid
if [ ! -f "$CONF_FILE" ]; then
  notify "BT Keepalive" "Config file missing. Copy btkeepalive.conf to /mnt/us/btkeepalive/"
  exit 1
fi

. "$CONF_FILE"
if ! validate_mac "$MAC"; then
  notify "BT Keepalive" "Device MAC not configured. Use 'Get MAC Address' and edit btkeepalive.conf."
  exit 1
fi

# Ensure all scripts are executable
chmod +x "$ALWAYS_ON_SCRIPT" "$WRAPPER_SCRIPT" 2>/dev/null

# Persist mode
echo "always-on" > "$CONFIG_FILE"
echo "$(date) - [set_always_on] mode set to: always-on" >> "$LOGFILE"

# Install/update Upstart job
if install_upstart_job; then
  echo "$(date) - [set_always_on] Upstart job verified/updated" >> "$LOGFILE"
else
  echo "$(date) - [set_always_on] warning: could not write Upstart job" >> "$LOGFILE"
fi

# Stop existing processes cleanly
initctl stop btkeepalive 2>/dev/null || true
pkill -f "btconnect.sh" 2>/dev/null || true
pkill -f "btkeepalive_wrapper.sh" 2>/dev/null || true

# Start service (via Upstart or background fallback)
echo "$(date) - [set_always_on] starting Always On Mode" >> "$LOGFILE"
( initctl start btkeepalive 2>/dev/null || nohup /bin/sh "$ALWAYS_ON_SCRIPT" >/dev/null 2>&1 ) &
sleep 1

# Verify startup
if is_service_running; then
  notify "BT Keepalive" "Always On Mode enabled"
  exit 0
else
  notify "BT Keepalive" "Notice: starting Always On Mode..."
  exit 0
fi
