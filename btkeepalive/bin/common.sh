#!/bin/sh
# Common definitions and utility functions for btkeepalive.
# Sourced by wrappers, daemon scripts, and KUAL extensions.

BASE_DIR="/mnt/us/btkeepalive"
CONFIG_FILE="$BASE_DIR/config.conf"
CONF_FILE="$BASE_DIR/btkeepalive.conf"
READING_SCRIPT="$BASE_DIR/reading-mode/btconnect.sh"
ALWAYS_ON_SCRIPT="$BASE_DIR/always-on/btconnect.sh"
WRAPPER_SCRIPT="$BASE_DIR/bin/btkeepalive_wrapper.sh"
UPSTART_CONF="/etc/upstart/btkeepalive.conf"
UPSTART_VERSION="3.0.0"
SYSTEM_BT_CONF="/var/local/zbluetooth/bt_config.conf"

# Send a Pillow visual alert notification on Kindle e-ink display
notify() {
  _TITLE="${1:-BT Keepalive}"
  _TEXT="$2"
  # Clean characters that break JSON
  _SAFE_TEXT=$(echo "$_TEXT" | tr '\r\n' ' ' | tr '"\\' "' ")
  lipc-set-prop com.lab126.pillow pillowAlert \
    "{\"clientParams\":{\"alertId\":\"appAlert1\",\"show\":true,\"customStrings\":[{\"matchStr\":\"alertTitle\",\"replaceStr\":\"$_TITLE\"},{\"matchStr\":\"alertText\",\"replaceStr\":\"$_SAFE_TEXT\"}]}}" 2>/dev/null
}

# Validate Bluetooth MAC address format
# Returns 0 if valid, 1 otherwise
validate_mac() {
  _MAC="$1"
  [ -z "$_MAC" ] && return 1
  case "$_MAC" in
    XX:XX:*|xx:xx:*|"")
      return 1
      ;;
  esac
  # Match 6 hex octets separated by colons or dashes
  if echo "$_MAC" | grep -Eq '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$'; then
    return 0
  fi
  return 1
}

# Rotate log file when exceeding size limit (default 256 KB)
rotate_log() {
  _FILE="$1"
  _MAX_KB="${2:-256}"
  [ ! -f "$_FILE" ] && return 0
  _SIZE_BYTES=$(wc -c < "$_FILE" 2>/dev/null || echo 0)
  _MAX_BYTES=$((_MAX_KB * 1024))
  if [ "$_SIZE_BYTES" -gt "$_MAX_BYTES" ]; then
    mv -f "$_FILE" "${_FILE}.1" 2>/dev/null
    : > "$_FILE"
  fi
}

# Check if btkeepalive is actively running
is_service_running() {
  if pgrep -f "btconnect.sh" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Connect with backoff retry
reconnect() {
  _TARGET_MAC="$1"
  for _DELAY in 0 3 10 30; do
    [ "$_DELAY" -gt 0 ] && sleep "$_DELAY"
    if lipc-set-prop com.lab126.btfd Connect "$_TARGET_MAC" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# Install or update Upstart job with boot persistence and normal exit 0
install_upstart_job() {
  _TMP_UPSTART="/tmp/btkeepalive.upstart.tmp"
  cat > "$_TMP_UPSTART" << EOF
# btkeepalive upstart job (version $UPSTART_VERSION)
start on started lab126
stop on stopping lab126

respawn
respawn limit 5 60
normal exit 0

script
    exec /bin/sh $WRAPPER_SCRIPT
end script
EOF

  # Only write to root filesystem if file doesn't match
  if [ ! -f "$UPSTART_CONF" ] || ! cmp -s "$_TMP_UPSTART" "$UPSTART_CONF" 2>/dev/null; then
    if mntroot rw 2>/dev/null; then
      cp -f "$_TMP_UPSTART" "$UPSTART_CONF"
      initctl reload-configuration 2>/dev/null || true
      mntroot ro 2>/dev/null
      rm -f "$_TMP_UPSTART"
      return 0
    else
      rm -f "$_TMP_UPSTART"
      return 1
    fi
  fi
  rm -f "$_TMP_UPSTART"
  return 0
}
