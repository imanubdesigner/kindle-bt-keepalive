#!/bin/sh
# Always On Mode
#
# Same reconnect behaviour as Reading Mode, plus a sleep lock: the Kindle is
# kept awake so the Bluetooth link is not dropped by suspend.
#
# - The lock is short (BTK_LOCK_TIMEOUT) and renewed every BTK_TICK seconds, so
#   it can never outlive this script by more than a few minutes.
# - Below THRESHOLD % (and not charging) the lock is released and the Kindle may
#   sleep again; it resumes by itself once charging starts or the battery has
#   recovered to THRESHOLD + 5 %. Reconnecting keeps working meanwhile.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"
BTK_TAG="always-on"
BTK_HOLD_LOCK=1

lock_loop() {
  _state=active
  renew_lock
  while :; do
    BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
    CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
    case "$_state" in
      active)
        if is_number "$BATT" && [ "$BATT" -lt "$THRESHOLD" ] && [ "$CHARGING" != "1" ]; then
          release_lock
          _state=low
          log "battery at ${BATT}% (< ${THRESHOLD}%), sleep prevention released"
          set_status "battery low (${BATT}%): sleep allowed, reconnect still active"
          notify "Battery at ${BATT}%:${NL}Always On paused, the Kindle may sleep.${NL}It resumes when charging."
        else
          renew_lock
        fi
        ;;
      low)
        if [ "$CHARGING" = "1" ] || { is_number "$BATT" && [ "$BATT" -ge $(( THRESHOLD + 5 )) ]; }; then
          _state=active
          clear_status
          renew_lock
          log "battery ok again (${BATT}%, charging=${CHARGING}), sleep prevention resumed"
        fi
        ;;
    esac
    nap "$BTK_TICK"
  done
}

trap 'exit 0' TERM INT HUP
trap btk_cleanup EXIT

require_config
log "started (v$BTK_VERSION), threshold=${THRESHOLD}%"

lock_loop &
LOCK_PID=$!

supervise_listener
