#!/bin/bash

# MAC address of the Bluetooth device to keep connected
MAC="XX:XX:XX:XX:XX:XX"   # ← replace with your MAC address

# Log file path
LOGFILE="/mnt/us/yourname/log/btkeepalive"   # ← replace yourname

echo "$(date) - script started" >> "$LOGFILE"

# Listen for all Bluetooth events. Using "*" instead of "Disconnect_Result"
# allows the script to intercept the connection silently — before the device
# actually disconnects — so headphones never play the disconnect sound.
lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
    if [[ "$EVENT" == *"Disconnect_Result"* ]]; then
        echo "$(date) - disconnection detected, reconnecting" >> "$LOGFILE"
        sleep 2
        lipc-set-prop com.lab126.btfd Connect "$MAC"
        echo "$(date) - Connect command sent to $MAC" >> "$LOGFILE"
    fi
done
