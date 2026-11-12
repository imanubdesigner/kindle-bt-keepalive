#!/bin/sh
# BT Keepalive - shared helpers. Sourced by the other scripts, never run directly.
# Plain POSIX sh only: it has to run on the Kindle's busybox ash.
#
# The caller sets BTK_BASE (normally /mnt/us/btkeepalive) before sourcing this
# file and may set BTK_TAG to label its log lines.

BTK_VERSION="3.0.1"
BTK_BASE="${BTK_BASE:-/mnt/us/btkeepalive}"

BTK_STATE_FILE="$BTK_BASE/config.conf"       # active mode (written by setmode.sh)
BTK_USER_CONF="$BTK_BASE/btkeepalive.conf"   # user settings (MAC, threshold...)
BTK_STATUS_FILE="$BTK_BASE/status"           # one-line "what is going on" note
BTK_WRAPPER_LOG="$BTK_BASE/log/wrapper.log"
BTK_JOB_NAME="btkeepalive"
BTK_UPSTART_CONF="${BTK_UPSTART_CONF:-/etc/upstart/btkeepalive.conf}"
BT_CONFIG="${BT_CONFIG:-/var/local/zbluetooth/bt_config.conf}"

BTK_LOG_MAX_BYTES=262144       # rotate a log to <name>.1 beyond this size
BTK_LOCK_TIMEOUT=300           # Always On: sleep lock lifetime (s), renewed every tick
BTK_TICK=60                    # Always On: battery check / lock renewal interval (s)
BTK_RECONNECT_DELAYS="0 3 10 30"   # wait before each Connect attempt (s)
BTK_STORM_MAX=6                # more reconnects than this in 60 s = something is wrong
BTK_STORM_PAUSE=60             # ...so pause this long before trying again

NL='
'

mkdir -p "$BTK_BASE/log" 2>/dev/null

# ---------------------------------------------------------------- logging ---

rotate_log() {
  [ -f "$1" ] || return 0
  _sz=$(wc -c < "$1" 2>/dev/null)
  [ "$(( ${_sz:-0} + 0 ))" -gt "$BTK_LOG_MAX_BYTES" ] && mv -f "$1" "$1.1" 2>/dev/null
  return 0
}

log() {
  _lf="${LOGFILE:-$BTK_WRAPPER_LOG}"
  rotate_log "$_lf"
  printf '%s - [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${BTK_TAG:-btk}" "$*" >> "$_lf" 2>/dev/null
  return 0
}

# One-line status note shown by "Current Mode" (no file = everything fine).
set_status()   { printf '%s\n' "$1" > "$BTK_STATUS_FILE" 2>/dev/null; }
clear_status() { rm -f "$BTK_STATUS_FILE" 2>/dev/null; }

# ---------------------------------------------------------- notifications ---

# Escape one line for embedding in a JSON string.
json_escape_line() {
  printf '%s' "$1" | tr '\t' ' ' | tr -d '\001-\010\013-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# notify "text"  (real newlines for multi-line text; any characters are safe)
notify() {
  _text=""
  _first=1
  while IFS= read -r _line || [ -n "$_line" ]; do
    _esc=$(json_escape_line "$_line")
    if [ "$_first" -eq 1 ]; then _text="$_esc"; _first=0; else _text="$_text\\n$_esc"; fi
  done <<BTK_NOTIFY_END
$1
BTK_NOTIFY_END
  lipc-set-prop com.lab126.pillow pillowAlert "{\"clientParams\":{\"alertId\":\"appAlert1\",\"show\":true,\"customStrings\":[{\"matchStr\":\"alertTitle\",\"replaceStr\":\"BT Keepalive\"},{\"matchStr\":\"alertText\",\"replaceStr\":\"$_text\"}]}}" 2>/dev/null
  return 0
}

# --------------------------------------------------------------- sleeping ---

# Interruptible sleep: a trapped signal is handled right away instead of after
# the foreground `sleep` finishes (plain `sleep` would delay SIGTERM handling).
nap() {
  sleep "$1" &
  NAP_PID=$!
  wait "$NAP_PID" 2>/dev/null
  NAP_PID=""
  return 0
}

# ------------------------------------------------------------- validation ---

is_number() {
  case "$1" in ''|*[!0-9]*) return 1 ;; esac
  return 0
}

# 6 hex pairs separated by ':' or '-'
is_mac() {
  printf '%s' "$1" | grep -Eq '^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$'
}

btk_mode() {
  _m=""
  [ -f "$BTK_STATE_FILE" ] && read -r _m < "$BTK_STATE_FILE"
  _m=$(printf '%s' "$_m" | tr -d '\r ')
  printf '%s' "${_m:-default}"
}

# Reads btkeepalive.conf. Returns 1 and sets CONFIG_ERROR if it is unusable.
# Sets MAC, THRESHOLD, LOGFILE, DEBUG_EVENTS (defaults for the last three).
load_config() {
  CONFIG_ERROR=""
  if [ ! -f "$BTK_USER_CONF" ]; then
    CONFIG_ERROR="btkeepalive.conf not found in $BTK_BASE"
    return 1
  fi
  # A syntax error in a sourced file would abort this whole script: test first.
  if ! ( . "$BTK_USER_CONF" ) >/dev/null 2>&1; then
    CONFIG_ERROR="btkeepalive.conf has a syntax error"
    return 1
  fi
  MAC=""; THRESHOLD=""; LOGFILE=""; DEBUG_EVENTS=""
  . "$BTK_USER_CONF" 2>/dev/null
  # Tolerate Windows line endings and stray spaces.
  MAC=$(printf '%s' "$MAC" | tr -d '\r\n ')
  THRESHOLD=$(printf '%s' "$THRESHOLD" | tr -d '\r\n ')
  LOGFILE=$(printf '%s' "$LOGFILE" | tr -d '\r\n')
  DEBUG_EVENTS=$(printf '%s' "$DEBUG_EVENTS" | tr -d '\r\n ')

  if ! is_mac "$MAC"; then
    if [ -z "$MAC" ] || [ "${MAC#XX}" != "$MAC" ]; then
      CONFIG_ERROR="MAC address not set in btkeepalive.conf"
    else
      CONFIG_ERROR="MAC address '$MAC' is not valid (expected AA:BB:CC:DD:EE:FF)"
    fi
    return 1
  fi
  if ! is_number "$THRESHOLD" || [ "$THRESHOLD" -gt 100 ]; then THRESHOLD=20; fi
  [ -n "$LOGFILE" ] || LOGFILE="$BTK_BASE/log/btkeepalive.log"
  mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null
  return 0
}

# Blocks until btkeepalive.conf is usable, telling the user once what is wrong.
# (Exiting instead would make Upstart respawn the job in a loop.)
require_config() {
  _told=0
  while ! load_config; do
    set_status "waiting: $CONFIG_ERROR"
    if [ "$_told" -eq 0 ]; then
      log "config problem: $CONFIG_ERROR - waiting for it to be fixed"
      notify "Config problem:${NL}$CONFIG_ERROR${NL}Edit /mnt/us/btkeepalive/btkeepalive.conf"
      _told=1
    fi
    nap 30
  done
  [ "$_told" -eq 1 ] && log "config OK now, continuing"
  clear_status
  return 0
}

# ------------------------------------------------------------- power lock ---

release_lock() { lipc-set-prop com.lab126.powerd deferSuspend 0 2>/dev/null; }
renew_lock()   { lipc-set-prop com.lab126.powerd deferSuspend "$BTK_LOCK_TIMEOUT" 2>/dev/null; }

# ---------------------------------------------------------- reconnecting ---

# reconnect "reason": ask btfd to connect to $MAC.
# - retries with backoff if the request itself fails (e.g. btfd not ready at boot)
# - storm guard: if reconnects keep firing, pause instead of spinning forever
reconnect() {
  _reason="$1"
  _now=$(date +%s)
  if [ $(( _now - ${BTK_WIN_START:-0} )) -gt 60 ]; then BTK_WIN_START=$_now; BTK_WIN_COUNT=0; fi
  BTK_WIN_COUNT=$(( ${BTK_WIN_COUNT:-0} + 1 ))
  if [ "$BTK_WIN_COUNT" -gt "$BTK_STORM_MAX" ]; then
    log "more than $BTK_STORM_MAX reconnects within 60s, pausing ${BTK_STORM_PAUSE}s"
    nap "$BTK_STORM_PAUSE"
    BTK_WIN_START=$(date +%s); BTK_WIN_COUNT=1
  fi
  for _delay in $BTK_RECONNECT_DELAYS; do
    [ "$_delay" -gt 0 ] && nap "$_delay"
    if lipc-set-prop com.lab126.btfd Connect "$MAC" >/dev/null 2>&1; then
      log "connect requested ($_reason)"
      return 0
    fi
    log "connect request failed ($_reason), will retry"
  done
  log "connect request kept failing ($_reason), giving up until the next event"
  return 1
}

handle_events() {
  while IFS= read -r EVENT; do
    [ "$DEBUG_EVENTS" = "1" ] && log "event: $EVENT"
    case "$EVENT" in
      *Disconnect_Result*) reconnect "disconnect event" ;;
    esac
  done
}

start_listener() {
  ( lipc-wait-event -m com.lab126.btfd "*" 2>/dev/null | handle_events ) &
  LISTENER_PID=$!
}

# Direct children of a pid (no pkill -P / pgrep: older busybox lacks them).
children_of() {
  for _d in /proc/[0-9]*; do
    if grep -q "^PPid:[[:space:]]*$1\$" "$_d/status" 2>/dev/null; then
      printf '%s ' "${_d#/proc/}"
    fi
  done
}

# Kill a process and its direct children. The parent goes first so it cannot
# spawn a replacement (e.g. a new sleep) while we are killing its children.
kill_tree() {
  _kids=$(children_of "$1")
  kill "$1" 2>/dev/null
  [ -n "$_kids" ] && kill $_kids 2>/dev/null
  return 0
}

stop_listener() {
  [ -n "$LISTENER_PID" ] || return 0
  kill_tree "$LISTENER_PID"
  LISTENER_PID=""
}

# Runs the event listener forever; restarts it (with backoff) if it dies, e.g.
# because btfd or the framework restarted. Never returns.
supervise_listener() {
  _bo=5
  while :; do
    _t0=$(date +%s)
    start_listener
    reconnect startup
    wait "$LISTENER_PID" 2>/dev/null
    stop_listener
    _lived=$(( $(date +%s) - _t0 ))
    [ "$_lived" -ge 60 ] && _bo=5
    log "event listener ended after ${_lived}s, restarting in ${_bo}s"
    nap "$_bo"
    _bo=$(( _bo * 2 )); [ "$_bo" -gt 60 ] && _bo=60
  done
}

# Common shutdown path for the btconnect.sh scripts (EXIT trap).
btk_cleanup() {
  [ -n "$BTK_CLEANED" ] && return 0
  BTK_CLEANED=1
  stop_listener
  [ -n "$LOCK_PID" ] && kill_tree "$LOCK_PID"
  [ -n "$NAP_PID" ] && kill "$NAP_PID" 2>/dev/null
  [ "$BTK_HOLD_LOCK" = "1" ] && release_lock
  log "stopped"
  return 0
}

# ----------------------------------------------------------------- status ---

# Any btkeepalive process alive? (/proc scan: works without pgrep)
procs_running() {
  for _d in /proc/[0-9]*; do
    [ "${_d#/proc/}" = "$$" ] && continue
    _c=$(tr '\0' ' ' 2>/dev/null < "$_d/cmdline") || continue
    case "$_c" in
      *btconnect.sh*|*btkeepalive_wrapper.sh*) return 0 ;;
    esac
  done
  return 1
}

is_running() {
  initctl status "$BTK_JOB_NAME" 2>/dev/null | grep -q 'start/running' && return 0
  procs_running
}

status_text() {
  _mode=$(btk_mode)
  case "$_mode" in
    reading)   _label="Reading Mode" ;;
    always-on) _label="Always On Mode" ;;
    default)   printf 'Default (disabled)\n'; return 0 ;;
    *)         printf 'Unknown mode: %s\n' "$_mode"; return 0 ;;
  esac
  if is_running; then printf '%s (running)\n' "$_label"; else printf '%s (NOT running)\n' "$_label"; fi
  if [ -s "$BTK_STATUS_FILE" ]; then
    read -r _note < "$BTK_STATUS_FILE"
    printf '%s\n' "$_note"
  fi
  return 0
}

# Upstart job text. Kept byte-identical to the one used by v2.x, so upgrading
# never needs to touch the (read-only) system partition.
job_text() {
  cat << JOB
start on started lab126
stop on stopping lab126

respawn
respawn limit 5 60

script
    exec /bin/sh $BTK_BASE/bin/btkeepalive_wrapper.sh
end script
JOB
}
