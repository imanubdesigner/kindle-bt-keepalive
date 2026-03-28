# Reading Mode — Battery Friendly

This variant is designed for users who use Bluetooth headphones **while reading**. It reconnects automatically when the Kindle drops the BT connection, but does not interfere with the device's normal sleep behavior.

When you press the power button, the Kindle goes into deep sleep exactly like a stock device — no battery drain, no compromises.

> This is the recommended variant for most users. Unless you plan to use your Kindle as a dedicated music player for extended sessions — something portable MP3 players have done since the early 2000s — this is all you need.

---

## How it works

The script listens for Bluetooth disconnection events in real time. When the Kindle drops the connection, it checks the battery level and reconnects automatically — but only if the battery is above a defined threshold or the device is charging.

No `deferSuspend` is used. The Kindle sleeps and wakes up exactly as intended.

| What | Why |
|------|-----|
| `lipc-wait-event` | Listens for Bluetooth system events in real time |
| `Disconnect_Result` | Fires every time the Kindle drops the BT connection |
| `THRESHOLD=97` | Skips reconnection if battery is low and not charging |
| `sleep 2` | Gives the Kindle a moment before attempting reconnection |
| `lipc-set-prop Connect` | Immediately reconnects the Bluetooth device |
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

Replace `yourname` with any name you prefer (e.g. your username). You can use a file manager:
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

# Minimum battery level to attempt reconnection
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

- **You only need to pair once** via the Kindle UI. After that, everything is automatic.
- Reconnection is skipped when the battery is below `THRESHOLD` and the device is not charging. Lower this value if you want reconnection at lower battery levels.
- Logs are saved to `/mnt/us/yourname/log/btkeepalive`.
