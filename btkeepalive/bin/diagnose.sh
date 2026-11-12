#!/bin/sh
# Prints a diagnostics report (also saved to log/diagnostics.txt).
# Handy for bug reports and for learning what btfd actually emits on your Kindle.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"
BTK_TAG="diagnose"

report() {
  echo "BT Keepalive $BTK_VERSION - diagnostics - $(date)"
  echo
  echo "== status =="
  status_text
  echo
  echo "== upstart =="
  initctl status "$BTK_JOB_NAME" 2>&1
  if [ -f "$BTK_UPSTART_CONF" ]; then
    if [ "$(cat "$BTK_UPSTART_CONF")" = "$(job_text)" ]; then echo "job file: present, up to date"
    else echo "job file: present, DIFFERENT from the expected one (run a mode again to refresh it)"; fi
  else
    echo "job file: absent (no start at boot)"
  fi
  echo
  echo "== config =="
  if load_config; then
    echo "MAC=$MAC THRESHOLD=$THRESHOLD DEBUG_EVENTS=${DEBUG_EVENTS:-0}"
    echo "LOGFILE=$LOGFILE"
  else
    echo "PROBLEM: $CONFIG_ERROR"
  fi
  echo
  echo "== power =="
  echo "battLevel=$(lipc-get-prop com.lab126.powerd battLevel 2>&1) isCharging=$(lipc-get-prop com.lab126.powerd isCharging 2>&1)"
  echo
  echo "== bluetooth =="
  echo "ConnectedDevices: $(lipc-get-prop com.lab126.btfd ConnectedDevices 2>&1)"
  echo
  echo "== wrapper.log (last 15) =="
  tail -n 15 "$BTK_WRAPPER_LOG" 2>/dev/null
  echo
  echo "== ${LOGFILE:-btkeepalive.log} (last 15) =="
  tail -n 15 "${LOGFILE:-$BTK_BASE/log/btkeepalive.log}" 2>/dev/null
}

OUT="$BTK_BASE/log/diagnostics.txt"
report > "$OUT" 2>&1
cat "$OUT"
