# Kindle Bluetooth Keepalive for Pixel Buds

Keep your Bluetooth headphones connected while reading on Kindle, without disconnections caused by screen saver or suspend mode.

Tested on **Kindle Signature 11th Generation, firmware 5.18.5.0.1**.

---

## Prerequisites

- Jailbroken Kindle
- SSH access or KTerm installed
- Bluetooth headphones already paired with the Kindle at least once via the UI (Settings → Bluetooth)

---

## Step 1 — Find the MAC Address of your Pixel Buds

```sh
cat /var/local/zbluetooth/bt_config.conf
```

Look for the section with `Name = Your Device Name` and copy the MAC address from the first line (e.g. `[11:22:33:1F:D0:7D]`).

---

## Step 2 — Create `btconnect.sh`

Create the file `/mnt/us/btconnect.sh` with the following content, replacing the MAC address with yours:

```sh
#!/bin/bash
# Bluetooth Keepalive Script
MAC="XX:XX:XX:XX:XX:XX"   # ← replace with your MAC address

# 1. Prevent the Kindle from suspending
lipc-set-prop com.lab126.powerd deferSuspend 3600

# 2. Listen for disconnection events and reconnect automatically
lipc-wait-event -m com.lab126.btfd "*" | while read EVENT; do
    if [[ "$EVENT" == *"Disconnect_Result"* ]]; then
        lipc-set-prop com.lab126.btfd Connect "$MAC"
    fi
done
```

Make it executable:

```sh
chmod +x /mnt/us/btconnect.sh
```

---

## Step 3 — Create `btkeepalive.conf`

Create the file `/etc/upstart/btkeepalive.conf` with the following content:

```sh
start on started btm
stop on stopping btm
script
    exec /bin/sh /mnt/us/btconnect.sh
end script
```

This ties the keepalive script directly to the Bluetooth daemon (`btm`). If Bluetooth restarts, the script restarts automatically as well.

---

## Step 4 — Start without rebooting

```sh
initctl start btkeepalive
```

Verify it is running:

```sh
initctl status btkeepalive
```

---

## How it works

| What | Why |
|------|-----|
| `deferSuspend 3600` | Tells the Kindle not to suspend for 1 hour |
| `lipc-wait-event` | Listens for Bluetooth system events in real time |
| `Disconnect_Result` | Fires every time the Kindle drops the BT connection |
| `lipc-set-prop Connect` | Immediately reconnects the Pixel Buds |
| `start on started btm` | Auto-starts the script at boot with the BT daemon |

---

## Notes

- **You only need to pair once** via the Kindle UI. After that, everything is automatic.
- The `deferSuspend` value is set in seconds. `3600` = 1 hour. You can lower it if needed.
- `lipc-set-prop com.lab126.btfd Connect` is safe to call even when already connected — the Bluetooth daemon handles it gracefully.
