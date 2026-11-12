#!/bin/sh
# Prints the current mode and whether it is really running.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"

status_text
