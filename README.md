# Kindle Bluetooth Keepalive

 ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Kindle](https://img.shields.io/badge/kindle-FF9900?style=for-the-badge&logo=amazon&logoColor=white) ![License MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge) ![Bluetooth](https://img.shields.io/badge/bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white) ![Upstart](https://img.shields.io/badge/upstart-333333?style=for-the-badge&logo=linux&logoColor=white)

Keep your Bluetooth headphones connected while reading on Kindle, without disconnections caused by screen saver or suspend mode.

Tested on **Kindle Signature 11th Generation, firmware 5.18.5.0.1**.

---

## Prerequisites

- Jailbroken Kindle
- SSH access or KTerm installed
- Bluetooth headphones already paired with the Kindle at least once via the UI (Settings → Bluetooth)

---

## Step 1 — Find the MAC Address of your Bluetooth device

```sh
cat /var/local/zbluetooth/bt_config.conf
```

Look for the section with `Name = Your Device Name` and copy the MAC address from the first line (e.g. `[11:22:33:1F:D0:7D]`).

---

## Step 2 — Create the folder structure

Connect the Kindle via USB. It will appear as a storage device on your computer.

Create the following folder structure inside the Kindle root:

```
yourname/
├── bin/
└── log/
```

Replace `yourname` with any name you prefer (e.g. your username).

You can do this using a file manager:
- **Linux**: Nautilus, Thunar, Dolphin, or any other file manager
- **Windows**: File Explorer

The Kindle root will be accessible at:
- **Linux**: `/run/media/youruser/Kindle/`
- **Windows**: the Kindle drive letter (e.g. `D:\`)

---

## Step 3 — Create `btconnect.sh`

Create the file `yourname/bin/btconnect.sh` with the following content, replacing the MAC address with yours:

```sh
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
```

> Remember to replace `yourname` in the `LOGFILE` path with the folder name you created in Step 2.

---

## Step 4 — Create `btkeepalive.conf`

Connect via SSH and make the script executable:

```sh
chmod +x /mnt/us/yourname/bin/btconnect.sh
```

Then create the file `/etc/upstart/btkeepalive.conf`.

> **Note**: writing to `/etc/upstart/` requires root access. If the filesystem is read-only, run `mntroot rw` first.

```sh
mntroot rw
vi /etc/upstart/btkeepalive.conf
```

Content of the file:

```sh
start on started lab126
stop on stopping lab126

respawn
respawn limit 5 60

script
    exec /bin/sh /mnt/us/yourname/bin/btconnect.sh
end script
```

> Replace `yourname` with your folder name.

The `respawn` directive ensures the script is automatically restarted if it crashes or exits unexpectedly.

---

## Step 5 — Start without rebooting

```sh
initctl start btkeepalive
```

Verify it is running:

```sh
initctl status btkeepalive
```

Reboot the Kindle and verify it starts automatically:

```sh
initctl status btkeepalive
# expected: btkeepalive start/running, process XXXX
```

---

## How it works

| What | Why |
|------|-----|
| `deferSuspend 7200` | Tells the Kindle not to suspend for 2 hours |
| `lipc-wait-event` | Listens for Bluetooth system events in real time |
| `Disconnect_Result` | Fires every time the Kindle drops the BT connection |
| `sleep 2` | Gives the Kindle a moment before attempting reconnection |
| `lipc-set-prop Connect` | Immediately reconnects the Bluetooth device |
| `start on started lab126` | Auto-starts reliably at boot with the main Kindle job |
| `respawn` | Restarts the script automatically if it exits unexpectedly |

---

## Notes

- **You only need to pair once** via the Kindle UI. After that, everything is automatic.
- The `deferSuspend` value is set in seconds. `7200` = 2 hours. You can adjust it if needed.
- `lipc-set-prop com.lab126.btfd Connect` is safe to call even when already connected — the Bluetooth daemon handles it gracefully.
- Logs are saved to `/mnt/us/yourname/log/btkeepalive` and are useful for diagnosing any remaining disconnection issues.
