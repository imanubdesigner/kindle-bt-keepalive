#!/bin/bash

# MAC address of the Bluetooth device to keep connected
MAC="XX:XX:XX:XX:XX:XX"   # ← replace with your MAC address

# Log file path
LOGFILE="/mnt/us/yourname/log/btkeepalive"   # ← replace yourname

# Minimum battery level to attempt reconnection and defer suspend
THRESHOLD=97

echo "$(date) - ipod mode started" >> "$LOGFILE"

printf 'com.lab126.powerd\ncom.lab126.btfd' | lipc-wait-event -l -m readyToSuspend,Disconnect_Result 2>/dev/null | while read EVENT; do

    case "$EVENT" in

    *"readyToSuspend"*)
        BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
        CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
        if [ "$CHARGING" -eq 1 ] || [ "$BATT" -ge "$THRESHOLD" ]; then
            lipc-set-prop com.lab126.powerd deferSuspend 600
            echo "$(date) - readyToSuspend intercepted, deferSuspend set (Batt: $BATT%, Charging: $CHARGING)" >> "$LOGFILE"
        else
            echo "$(date) - low battery ($BATT%), allowing sleep" >> "$LOGFILE"
        fi
        ;;

    *"Disconnect_Result"*)
        BATT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null)
        CHARGING=$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null)
        if [ "$CHARGING" -eq 1 ] || [ "$BATT" -ge "$THRESHOLD" ]; then
            echo "$(date) - disconnection detected, reconnecting (Batt: $BATT%, Charging: $CHARGING)" >> "$LOGFILE"
            sleep 2
            lipc-set-prop com.lab126.btfd Connect "$MAC"
        else
            echo "$(date) - low battery ($BATT%), skipping reconnect" >> "$LOGFILE"
        fi
        ;;

    esac
done
