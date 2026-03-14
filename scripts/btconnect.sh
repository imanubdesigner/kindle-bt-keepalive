#!/bin/bash
# Permanent Script for Pixel Buds
MAC="XX:XX:XX:XX:XX:XX"

# 1. Set a Delay
lipc-set-prop com.lab126.powerd deferSuspend 3600

# 2. Events
lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
    if [[ "$EVENT" == *"Disconnect_Result"* ]]; then
        # Reconnect
        lipc-set-prop com.lab126.btfd Connect "$MAC"
    fi
done
