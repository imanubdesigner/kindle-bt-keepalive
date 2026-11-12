#!/bin/sh
# Usage: setmode.sh reading | always-on | default
#
#   1. saves the mode (config.conf), so it survives reboots
#   2. installs the Upstart job if needed (boot persistence)
#   3. stops whatever is running and starts the new mode
#   4. checks that it really started and tells the user
#
# Exit status: 0 = done, 1 = failed (see log/wrapper.log), 2 = bad usage.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"
BTK_TAG="setmode"

MODE="$1"
case "$MODE" in
  reading)   SCRIPT="$BTK_BASE/reading-mode/btconnect.sh"
             DONE_MSG="Reading Mode enabled${NL}Reconnects after each drop.${NL}The Kindle sleeps normally." ;;
  always-on) SCRIPT="$BTK_BASE/always-on/btconnect.sh"
             DONE_MSG="Always On enabled${NL}Keeps the Kindle awake and${NL}reconnects after each drop." ;;
  default)   SCRIPT=""
             DONE_MSG="Disabled (default mode)" ;;
  *) echo "usage: $0 reading|always-on|default" >&2; exit 2 ;;
esac

fail() {
  log "FAILED: $*"
  notify "Could not enable $MODE:${NL}$*${NL}See btkeepalive/log/wrapper.log"
  exit 1
}

# Stop the Upstart job first so respawn cannot fight us, then clean up leftovers.
stop_all() {
  initctl stop "$BTK_JOB_NAME" >/dev/null 2>&1
  pkill -f "btconnect.sh" 2>/dev/null
  pkill -f "btkeepalive_wrapper.sh" 2>/dev/null
  _i=0
  while [ "$_i" -lt 5 ] && procs_running; do nap 1; _i=$(( _i + 1 )); done
  if procs_running; then
    pkill -9 -f "btconnect.sh" 2>/dev/null
    pkill -9 -f "btkeepalive_wrapper.sh" 2>/dev/null
    nap 1
  fi
  release_lock    # the killed script may not have been able to do it
}

# The Upstart job lives on the read-only system partition: only touch it when
# its content differs from what we want.
install_job() {
  if [ -f "$BTK_UPSTART_CONF" ] && [ "$(cat "$BTK_UPSTART_CONF" 2>/dev/null)" = "$(job_text)" ]; then
    log "Upstart job already installed, not touching the system partition"
    return 0
  fi
  mntroot rw 2>/dev/null
  job_text > "$BTK_UPSTART_CONF"
  _rc=$?
  mntroot ro 2>/dev/null
  if [ "$_rc" -ne 0 ]; then
    log "could not write $BTK_UPSTART_CONF"
    return 1
  fi
  initctl reload-configuration >/dev/null 2>&1
  if ! initctl status "$BTK_JOB_NAME" >/dev/null 2>&1; then
    log "Upstart does not know the job after installing it"
    return 1
  fi
  log "Upstart job installed"
  return 0
}

remove_job() {
  [ -f "$BTK_UPSTART_CONF" ] || { log "Upstart job not present, nothing to remove"; return 0; }
  mntroot rw 2>/dev/null
  rm -f "$BTK_UPSTART_CONF"
  _rc=$?
  initctl reload-configuration >/dev/null 2>&1
  mntroot ro 2>/dev/null
  if [ "$_rc" -ne 0 ]; then log "could not remove $BTK_UPSTART_CONF"; return 1; fi
  log "Upstart job removed, root restored to read-only"
  return 0
}

log "switching to mode: $MODE"

# Release any sleep lock right away (an Always On run may still hold one).
release_lock

# 1. persist the mode (atomic replace)
printf '%s\n' "$MODE" > "$BTK_STATE_FILE.tmp" && mv -f "$BTK_STATE_FILE.tmp" "$BTK_STATE_FILE" \
  || fail "cannot write $BTK_STATE_FILE"

# --- default: stop everything and remove the boot job -----------------------
if [ "$MODE" = "default" ]; then
  stop_all
  remove_job || log "warning: boot job could not be removed"
  clear_status
  notify "$DONE_MSG"
  exit 0
fi

# 2. boot persistence
PERSIST=1
install_job || PERSIST=0
chmod +x "$SCRIPT" "$BTK_BASE/bin/btkeepalive_wrapper.sh" 2>/dev/null

# 3. restart in the new mode
stop_all
clear_status
if ! initctl start "$BTK_JOB_NAME" >/dev/null 2>&1; then
  log "initctl start failed, falling back to a plain background process"
  PERSIST=0
  nohup /bin/sh "$SCRIPT" >/dev/null 2>&1 &
fi

# 4. verify
_i=0
while [ "$_i" -lt 5 ] && ! is_running; do nap 1; _i=$(( _i + 1 )); done
is_running || fail "the service did not start"

MSG="$DONE_MSG"
[ "$PERSIST" -eq 1 ] || MSG="$MSG${NL}(will not survive a reboot)"
if ! load_config; then
  MSG="$MSG${NL}${NL}But: $CONFIG_ERROR"
fi
log "mode $MODE running"
notify "$MSG"
exit 0
