#!/bin/bash

MAC="XX:XX:XX:XX:XX:XX"
LOGFILE="/mnt/us/yourusarname/log/btkeepalive"
THRESHOLD=97

echo "$(date) - script started" >> "$LOGFILE"

lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
    if [[ "$EVENT" == *"Disconnect_Result"* ]]; then
        BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
        CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
        if [ "$CHARGING" -eq 1 ] || [ "$BATT" -ge "$THRESHOLD" ]; then
            echo "$(date) - disconnection detected, reconnecting (Batt: $BATT%, Charging: $CHARGING)" >> "$LOGFILE"
            sleep 2
            lipc-set-prop com.lab126.btfd Connect "$MAC"
        else
            echo "$(date) - low battery ($BATT%), skipping reconnect" >> "$LOGFILE"
        fi
    fi
done
