#!/bin/sh

# Get paired Bluetooth device MAC addresses and show via Pillow notification.
# Displays up to the last 3 paired devices (most recently paired) with names.

CONFIG_FILE="/var/local/zbluetooth/bt_config.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert \
    '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"No paired devices found. Pair via Settings -> Bluetooth first."}]}}'
  exit 1
fi

# Extract last 3 paired device MACs (most recently paired)
grep -E '^\[([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\]$' "$CONFIG_FILE" | \
  tail -3 | tr -d '[]' > /tmp/btkeepalive_macs.txt

LIST=""
while read MAC; do
  NAME=$(grep -A 10 "^\[$MAC\]" "$CONFIG_FILE" | \
         grep "^Name = " | cut -d= -f2- | sed 's/^ *//')
  if [ -n "$NAME" ]; then
    SHORT_NAME=$(echo "$NAME" | cut -c1-35)
    LIST="$LIST$MAC ($SHORT_NAME)\n"
  else
    LIST="$LIST$MAC\n"
  fi
done < /tmp/btkeepalive_macs.txt
rm -f /tmp/btkeepalive_macs.txt

if [ -z "$LIST" ]; then
  lipc-set-prop com.lab126.pillow pillowAlert \
    '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"No paired devices found. Pair via Settings -> Bluetooth first."}]}}'
else
  lipc-set-prop com.lab126.pillow pillowAlert \
    '{"clientParams":{"alertId":"appAlert1","show":true,"customStrings":[{"matchStr":"alertTitle","replaceStr":"BT Keepalive"},{"matchStr":"alertText","replaceStr":"Paired devices:\n'"$LIST"'"}]}}'
fi
