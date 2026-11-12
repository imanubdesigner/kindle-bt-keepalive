#!/bin/sh
# Prints the last 3 paired Bluetooth devices, one per line: "MAC (Name)".
# Prints nothing (exit 1) when there is no Bluetooth config or no device.

BTK_BASE="${BTK_BASE:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
. "$BTK_BASE/lib/common.sh"

[ -f "$BT_CONFIG" ] || exit 1

ENTRIES=""
CUR=""
NAME=""

flush() {
  [ -n "$CUR" ] || return 0
  if [ -n "$NAME" ]; then ENTRIES="$ENTRIES$CUR ($NAME)$NL"; else ENTRIES="$ENTRIES$CUR$NL"; fi
}

while IFS= read -r LINE || [ -n "$LINE" ]; do
  LINE=$(printf '%s' "$LINE" | tr -d '\r')
  case "$LINE" in
    \[*\])
      flush
      CUR=${LINE#\[}; CUR=${CUR%\]}; NAME=""
      is_mac "$CUR" || CUR=""
      ;;
    "Name ="*|"Name="*)
      if [ -n "$CUR" ]; then
        NAME=${LINE#*=}
        while [ "${NAME# }" != "$NAME" ]; do NAME=${NAME# }; done
        NAME=$(printf '%s' "$NAME" | tr -d '\001-\037' | cut -c1-35)
      fi
      ;;
  esac
done < "$BT_CONFIG"
flush

[ -n "$ENTRIES" ] || exit 1
printf '%s' "$ENTRIES" | tail -n 3
