#!/bin/sh
# Reading Mode
#
# Reconnects the headphones right after every Bluetooth disconnect. The Kindle
# keeps its normal sleep behaviour (no wake lock), so a drop caused by sleeping
# is repaired when the Kindle wakes up, not prevented.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"
BTK_TAG="reading"
BTK_HOLD_LOCK=0

trap 'exit 0' TERM INT HUP
trap btk_cleanup EXIT

require_config
log "started (v$BTK_VERSION)"

supervise_listener
