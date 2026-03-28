# Always-On Mode — iPod Mode

This variant is designed for users who want to use the Kindle as a **dedicated audio player**, keeping the Bluetooth connection alive and preventing deep sleep during playback — even with the cover closed.

Tested on **Kindle Signature 11th Generation, firmware 5.18.5.0.1** — audio playback continued uninterrupted for 10+ minutes with the cover closed and the screen off.

> ⚠️ This variant intercepts the Kindle's suspend cycle to keep it awake during playback. This has a noticeable impact on battery life compared to reading-mode. Only use this variant when you need uninterrupted audio playback over long periods.

---

## How it works

The script listens to **two event sources simultaneously**:

- `com.lab126.powerd` — power management events
- `com.lab126.btfd` — Bluetooth events

When the Kindle tries to go into deep sleep, it dispatches a `readyToSuspend` countdown. The script intercepts it and sets `deferSuspend 600` to delay the suspension by 10 minutes — at which point the Kindle will try again, and the script will defer again, indefinitely.

When the BT disconnects, it reconnects automatically.

Both battery level and charging state are checked before acting. Below `THRESHOLD` and not charging, the Kindle is allowed to sleep normally and reconnection is skipped. You can adjust `THRESHOLD` to your preference — the default is `25` (%).

| What | Why |
|------|-----|
| `printf ... \| lipc-wait-event -l` | Listens to two event sources simultaneously |
| `readyToSuspend` | Fires when the Kindle is about to enter deep sleep |
| `deferSuspend 600` | Delays deep sleep by 10 minutes, renewed on each attempt |
| `Disconnect_Result` | Fires every time the Kindle drops the BT connection |
| `sleep 2` | Gives the Kindle a moment before attempting reconnection |
| `lipc-set-prop Connect` | Immediately reconnects the Bluetooth device |
| `THRESHOLD=25` | Below this battery %, allows sleep and skips reconnect |
| `start on started lab126` | Auto-starts reliably at boot with the main Kindle job |
| `respawn` | Restarts the script automatically if it exits unexpectedly |

---

## Step 1 — Find the MAC Address of your Bluetooth device

```sh
cat /var/local/zbluetooth/bt_config.conf
```

Look for the section with `Name = Your Device Name` and copy the MAC address from the first line (e.g. `[11:22:33:1F:D0:7D]`).

---

## Step 2 — Create the folder structure

Connect the Kindle via USB and create the following folders inside the Kindle root:

```
yourname/
├── bin/
└── log/
```

Replace `yourname` with any name you prefer. You can use a file manager:
- **Linux**: Nautilus, Thunar, Dolphin, or any other file manager
- **Windows**: File Explorer

The Kindle root is accessible at:
- **Linux**: `/run/media/youruser/Kindle/`
- **Windows**: the Kindle drive letter (e.g. `D:\`)

---

## Step 3 — Create `btconnect.sh`

Copy [`btconnect.sh`](./btconnect.sh) to `yourname/bin/btconnect.sh` and edit it with your values:

```sh
#!/bin/bash

# MAC address of the Bluetooth device to keep connected
MAC="XX:XX:XX:XX:XX:XX"   # ← replace with your MAC address

# Log file path
LOGFILE="/mnt/us/yourname/log/btkeepalive"   # ← replace yourname

# Minimum battery level to attempt reconnection and defer suspend.
# Below this threshold and not charging, the Kindle is allowed to sleep
# and reconnection is skipped. Adjust this value to your preference.
THRESHOLD=25

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
```

---

## Step 4 — Create `btkeepalive.conf`

Connect via SSH and make the script executable:

```sh
chmod +x /mnt/us/yourname/bin/btconnect.sh
```

Create `/etc/upstart/btkeepalive.conf`:

> If the filesystem is read-only, run `mntroot rw` first.

```sh
start on started lab126
stop on stopping lab126

respawn
respawn limit 5 60

script
    exec /bin/sh /mnt/us/yourname/bin/btconnect.sh
end script
```

---

## Step 5 — Start and verify

```sh
initctl start btkeepalive
initctl status btkeepalive
```

Reboot and verify it starts automatically:

```sh
initctl status btkeepalive
# expected: btkeepalive start/running, process XXXX
```

---

## Notes

- `deferSuspend` is only set when the Kindle dispatches a `readyToSuspend` event — not at startup. This is the correct approach as confirmed by the Kindle's internal power management.
- The default `THRESHOLD` is `25%`. Feel free to adjust it — for example, `20` if you want playback to continue until the battery is nearly empty, or `50` if you prefer to be more conservative.
- When the battery drops below `THRESHOLD` and the device is not charging, the Kindle goes into deep sleep normally and reconnection is skipped.
- Logs are saved to `/mnt/us/yourname/log/btkeepalive`.
