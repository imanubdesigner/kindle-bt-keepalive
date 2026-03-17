#!/bin/bash

# MAC address of the Bluetooth device to keep connected
MAC="XX:XX:XX:XX:XX:XX"   # ← replace with your MAC address

# Log file path
LOGFILE="/mnt/us/yourname/log/btkeepalive"

# Prevent the Kindle from suspending for 2 hours
lipc-set-prop com.lab126.powerd deferSuspend 7200
echo "$(date) - script started, deferSuspend set to 7200" >> "$LOGFILE"

# Listen for Bluetooth events and reconnect on disconnection
lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
    if [[ "$EVENT" == *"Disconnect_Result"* ]]; then
        echo "$(date) - disconnection detected: $EVENT" >> "$LOGFILE"

        # Wait a moment before reconnecting
        sleep 2

        # Reconnect the Bluetooth device
        lipc-set-prop com.lab126.btfd Connect "$MAC"
        echo "$(date) - Connect command sent to $MAC" >> "$LOGFILE"
    fi
done
