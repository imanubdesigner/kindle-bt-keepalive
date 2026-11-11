#!/bin/sh
# Default (Disable) Mode:
#   1. Releases power deferrals immediately
#   2. Writes "default" to config.conf
#   3. Stops Upstart service and kills daemon processes
#   4. Removes the Upstart job and restores read-only filesystem
#   5. Alerts user

COMMON="/mnt/us/btkeepalive/bin/common.sh"
[ -f "$COMMON" ] && . "$COMMON" || . "$(dirname "$0")/../../btkeepalive/bin/common.sh"

LOGFILE="$BASE_DIR/log/wrapper.log"
mkdir -p "$BASE_DIR/log"
rotate_log "$LOGFILE" 256

# Release any active sleep deferral from Always On mode immediately
lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null
echo "$(date) - [set_default] sleep prevention released" >> "$LOGFILE"

# Persist mode
echo "default" > "$CONFIG_FILE"
echo "$(date) - [set_default] config set to: default" >> "$LOGFILE"

# Stop Upstart service BEFORE pkill (prevents respawn fighting pkill)
initctl stop btkeepalive 2>/dev/null || true

# Kill any leftover processes
pkill -f "btconnect.sh" 2>/dev/null || true
pkill -f "btkeepalive_wrapper.sh" 2>/dev/null || true
echo "$(date) - [set_default] all keepalive processes stopped" >> "$LOGFILE"

# Remove Upstart job and restore read-only root
if [ -f "$UPSTART_CONF" ]; then
  if mntroot rw 2>/dev/null; then
    rm -f "$UPSTART_CONF"
    initctl reload-configuration 2>/dev/null || true
    mntroot ro 2>/dev/null
    echo "$(date) - [set_default] Upstart job removed, root restored to ro" >> "$LOGFILE"
  fi
fi

notify "BT Keepalive" "Disabled (default mode)"
