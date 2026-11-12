#!/bin/sh
# Started at boot by the Upstart job: reads the saved mode and hands over to the
# matching btconnect.sh (exec, so Upstart keeps tracking the same process).

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"
BTK_TAG="wrapper"

log "started (v$BTK_VERSION)"
MODE=$(btk_mode)
log "mode=$MODE"

case "$MODE" in
  reading)   exec /bin/sh "$BTK_BASE/reading-mode/btconnect.sh" ;;
  always-on) exec /bin/sh "$BTK_BASE/always-on/btconnect.sh" ;;
  *)
    # Idle instead of exiting: an exit would make Upstart respawn us in a loop.
    log "mode '$MODE': nothing to do, idling"
    trap 'exit 0' TERM INT HUP
    while :; do nap 3600; done
    ;;
esac
