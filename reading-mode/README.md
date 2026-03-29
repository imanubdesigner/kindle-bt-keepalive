# Reading Mode — Battery Friendly

This variant is designed for users who use Bluetooth headphones **while reading**. It keeps the connection alive silently and automatically, without any audible disconnection sound from the headphones.

When you press the power button, the Kindle goes into deep sleep exactly like a stock device — no battery drain, no compromises.

> This is the recommended variant for most users. Unless you plan to use your Kindle as a dedicated music player for extended sessions — something portable MP3 players have been doing since the late 1990s — this is all you need.

---

## How it works

The script listens for **all Bluetooth events** using `"*"`. This allows it to intercept the connection before the Kindle fully drops it — so the headphones never play the disconnect sound and the reconnection is completely transparent.

`lipc-wait-event` is a passive listener. It does nothing until an event arrives, so there is no CPU usage, no polling, and no battery impact.

| What | Why |
|------|-----|
| `lipc-wait-event "*"` | Listens for all BT events, intercepts silently before disconnect |
| `Disconnect_Result` | Fallback — fires if a full disconnection does occur |
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
```

> Remember to replace `yourname` in the `LOGFILE` path with the folder name you created in Step 2.

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
- The script does **not** use `deferSuspend`. The Kindle goes into deep sleep normally when you press the power button, preserving battery life exactly like a stock device.
- `lipc-set-prop com.lab126.btfd Connect` is safe to call even when already connected — the Bluetooth daemon handles it gracefully.
- Logs are saved to `/mnt/us/yourname/log/btkeepalive`.
