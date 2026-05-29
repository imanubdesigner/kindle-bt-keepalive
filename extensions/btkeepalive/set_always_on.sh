#!/bin/sh
# Enable Always On Mode:
#   1. Writes "always-on" to config.conf (persists across reboots)
#   2. Installs the Upstart job on first run (boot persistence)
#   3. Stops any currently running keepalive service/processes cleanly
#   4. Starts the always-on btconnect.sh (via Upstart or fallback nohup)
#   5. Shows a Pillow notification to confirm the mode change

BASE_DIR="/mnt/us/btkeepalive"
CONFIG_FILE="$BASE_DIR/config.conf"
ALWAYS_ON_SCRIPT="$BASE_DIR/always-on/btconnect.sh"
WRAPPER_SCRIPT="$BASE_DIR/bin/btkeepalive_wrapper.sh"
UPSTART_CONF="/etc/upstart/btkeepalive.conf"
LOGFILE="$BASE_DIR/log/wrapper.log"

# Ensure runtime directories exist
mkdir -p "$BASE_DIR/log"

# Ensure all required scripts are executable
chmod +x "$ALWAYS_ON_SCRIPT" "$WRAPPER_SCRIPT" 2>/dev/null

# --- 1. Persist mode ---
echo "always-on" > "$CONFIG_FILE"
echo "$(date) - [set_always_on] config set to: always-on" >> "$LOGFILE"

# --- 2. Install/reinstall Upstart job (boot persistence) ---
if ! grep -q "btkeepalive_wrapper" "$UPSTART_CONF" 2>/dev/null; then
    mntroot rw 2>/dev/null
    cat > "$UPSTART_CONF" << 'EOF'
start on started lab126
stop on stopping lab126

respawn
respawn limit 5 60

script
    exec /bin/sh /mnt/us/btkeepalive/bin/btkeepalive_wrapper.sh
end script
EOF
    mntroot ro 2>/dev/null
    echo "$(date) - [set_always_on] Upstart job installed" >> "$LOGFILE"
else
    echo "$(date) - [set_always_on] Upstart job already up-to-date, skipped" >> "$LOGFILE"
fi
initctl reload-configuration 2>/dev/null || true

# --- 3. Stop existing service and processes cleanly ---
# Stop Upstart first so respawn doesn't fight us
initctl stop btkeepalive 2>/dev/null || true
sleep 1
# Kill any leftover processes that may have been started via nohup fallback
pkill -f "btconnect.sh" 2>/dev/null || true
pkill -f "btkeepalive_wrapper.sh" 2>/dev/null || true
sleep 1

# --- 4. Start in always-on mode ---
echo "$(date) - [set_always_on] starting Always On Mode" >> "$LOGFILE"
initctl start btkeepalive 2>/dev/null || \
    nohup /bin/sh "$ALWAYS_ON_SCRIPT" > /dev/null 2>&1 &

# --- 5. Notify user ---
lipc-set-prop com.lab126.pillow pillowAlert \
  '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"Always On Mode enabled"}]}}'
