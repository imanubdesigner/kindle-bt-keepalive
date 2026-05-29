<p align="center" style="padding-bottom: 24px;">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo/kindle-bt-keepalive-logo-dark.png">
    <img alt="kindle-bt-keepalive logo" src="assets/logo/kindle-bt-keepalive-logo.png" width="300">
  </picture>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black">
  <img src="https://img.shields.io/badge/kindle-FF9900?style=for-the-badge&logo=amazon&logoColor=white">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge">
  <img src="https://img.shields.io/badge/bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white">
  <img src="https://img.shields.io/badge/KUAL-4A90E2?style=for-the-badge&logo=amazon&logoColor=white">
  <img src="https://img.shields.io/badge/KOReader-FF6600?style=for-the-badge&logo=koreader&logoColor=white">
  <img src="https://img.shields.io/badge/upstart-333333?style=for-the-badge&logo=linux&logoColor=white">
</p>

Keep your Bluetooth headphones connected on a jailbroken Kindle, without unexpected disconnections caused by screen saver or suspend mode. Features both **KUAL** and **KOReader** integration for point-and-click control directly from your Kindle.

Tested on **Kindle Paperwhite 11th Generation, firmware 5.18.5.0.1**.

---

## Rationale & Inspiration 🍃

For me, reading is far more than a mere intellectual exercise; it is a profoundly immersive ritual. There is an unparalleled serenity in losing oneself within the pages of a book while enveloped by the rhythmic cadence of **falling rain** or the evocative symphony of a **secluded woodland**.

This project was born out of a necessity to preserve that very atmosphere. I discovered that the Kindle's power-saving measures often sever the Bluetooth connection during periods of sonic subtlety, abruptly shattering the immersion. This script is a modest endeavor, conceived for **educational purposes and personal exploration**, to ensure that the whisper of the forest or the patter of the rain remains uninterrupted.

---

## Before You Start

**Important**: Before downloading this project, you must pair your Bluetooth headphones with your Kindle at least once:

1. Turn on your Bluetooth headphones
2. On your Kindle: **Settings → Bluetooth**
3. Select your device and complete pairing
4. Once paired, you can proceed with the [Installation](#installation) steps below

> **Note**: This project requires a jailbroken Kindle with [KUAL](https://wiki.mobileread.com/wiki/KUAL) installed.

---

## Features ⚡

- **KUAL Menu Integration**: No more SSH or KTerm needed after setup
- **KOReader Plugin**: Full menu access inside KOReader, no exit required
- **Get MAC Address**: One-click MAC detection via KUAL or KOReader
- **Current Mode**: Check active mode with one click
- **Three Modes**: Reading Mode, Always On, and Default (Disable)
- **Persistent**: Settings survive reboots via Upstart
- **Zero Configuration**: Single config file with MAC address
- **Pillow & KOReader Notifications**: Visual feedback on mode changes

---

## Screenshots

<p align="center">
  <img src="assets/screenshots/bluetooth-keepalive-kual.png" alt="KUAL Menu Integration" width="280">
  <img src="assets/screenshots/current_mode.png" alt="Current Mode Notification" width="280">
</p>

---

## Choose Your Mode

| | Reading Mode | Always On |
|---|---|---|
| **Use case** | Reading with BT headphones | Continuous audio playback (iPod Style) |
| **Deep sleep** | ✅ Normal — preserves battery | ⚠️ Deferred — keeps device awake |
| **Reconnect on low battery** | Skipped below threshold | Always attempts |
| **Battery impact** | Minimal | Higher |
| **Recommended for** | Most users | Extended listening sessions |

**Default (Disable)**: Restores Kindle to vanilla state, removes all background processes and Upstart jobs.

---

## Project Structure

```
kindle-bt-keepalive/
├── btkeepalive/              ← Copy to /mnt/us/btkeepalive/
│   ├── always-on/
│   │   └── btconnect.sh
│   ├── reading-mode/
│   │   └── btconnect.sh
│   ├── bin/
│   │   └── btkeepalive_wrapper.sh
│   └── btkeepalive.conf      ← Edit with your MAC
├── extensions/               ← Copy to /mnt/us/extensions/
│   └── btkeepalive/
│       ├── config.xml        ← KUAL extension config
│       ├── menu.json         ← KUAL menu definition
│       ├── get_mac.sh        ← MAC address detection
│       ├── get_mode.sh       ← Current mode display
│       ├── set_reading.sh
│       ├── set_always_on.sh
│       └── set_default.sh
├── btkeepalive.koplugin/      ← Copy to /mnt/us/koreader/plugins/
│   ├── _meta.lua              ← KOReader plugin metadata
│   └── main.lua               ← Menu & action handlers
└── assets/                   ← Logos and screenshots
    ├── logo/
    └── screenshots/
```

---

## Prerequisites

- Jailbroken Kindle with [KUAL](https://wiki.mobileread.com/wiki/KUAL) installed
- [KOReader](https://github.com/koreader/koreader) (optional, only needed for the KOReader plugin)
- SSH access via [kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite) or KTerm (only for [Usage Verification](#usage-verification))
- [KinAMP](https://github.com/kbarni/KinAMP) by [@kbarni](https://github.com/kbarni) — native music player (optional, but recommended)

> **Note**: Make sure you've completed the [Before You Start](#before-you-start) steps before proceeding.

---

## Installation

### 1. Download and Copy Files

1. Download the project: **[Clone or Download ZIP](https://github.com/imanubdesigner/kindle-bt-keepalive/releases)** from GitHub
2. Extract the ZIP on your computer (or clone the repository)
3. Connect your Kindle via USB
4. On your Kindle drive, copy the `btkeepalive/` folder to `/mnt/us/`
5. On your Kindle drive, copy the `extensions/` folder to `/mnt/us/`

> **Windows users**: Simply copy or drag-and-drop the folders from the extracted ZIP directly to the root of your Kindle drive in Explorer (usually named "Kindle").

### 2. Copy KOReader Plugin (optional)

If you use [KOReader](https://github.com/koreader/koreader), copy the `btkeepalive.koplugin/` folder to `/mnt/us/koreader/plugins/`. Restart KOReader and find **Bluetooth Keepalive** in the **Tools** menu.

### 3. Configure Your Bluetooth Device

Edit `/mnt/us/btkeepalive/btkeepalive.conf` and replace the MAC address.

**You can edit this file with any text editor:**
- **Windows**: Notepad, Notepad++, VS Code
- **Linux**: gedit, nano, vim, VS Code, Kate
- **macOS**: TextEdit, BBEdit, VS Code, Sublime Text
- **On Kindle**: vi/vim (via SSH/KTerm)

**Find your device MAC:**
- Pair your headphones via Kindle: Settings → Bluetooth
- Click **"Get MAC Address"** in the KUAL Bluetooth Keepalive menu (first menu item)
- A Pillow notification shows your device's MAC address
- Alternatively, via SSH or Kterm: `cat /var/local/zbluetooth/bt_config.conf`

**Edit the config file:**

```bash
# Replace MAC="XX:XX:XX:XX:XX:XX" with your device MAC
# Example: MAC="75-c8-28-1a-12-b2"
```

### 4. Launch KUAL

1. Open **KUAL** on your Kindle
2. You'll see **Bluetooth Keepalive** in the menu
3. **First click "Get MAC Address"** (first menu item) to detect your paired device MAC
4. A notification shows: "Device MAC: XX:XX:XX:XX:XX:XX"
5. Copy the MAC and edit [`/mnt/us/btkeepalive/btkeepalive.conf`](#configuration-file) with any text editor
6. Select **Reading Mode** or **Always On**
7. A notification confirms the mode change

> **Tip**: You can verify the service is running with the [Usage Verification](#usage-verification) steps.

### 5. Using the KOReader Plugin (optional)

If you use KOReader, you can control Bluetooth Keepalive without leaving your book:

1. Open **KOReader**
2. Tap **Tools → Bluetooth Keepalive**
3. All the same menu items as KUAL are available: **Get MAC Address**, **Current Mode**, **Reading Mode**, **Always On**, **Default (Disable)**
4. Mode changes are confirmed with a KOReader popup notification

---

## Configuration File

Only one file to edit: `/mnt/us/btkeepalive/btkeepalive.conf`

```bash
# MAC address of your Bluetooth headphones
MAC="XX:XX:XX:XX:XX:XX"  # ← Replace with your device MAC

# Minimum battery percentage before allowing sleep (Always On mode only)
THRESHOLD=20

# Log file path (auto-created)
LOGFILE="/mnt/us/btkeepalive/log/btkeepalive.log"
```

---

## How It Works

1. **KUAL Menu Click** or **KOReader Plugin** → Calls `set_reading.sh` or `set_always_on.sh`
2. **Script Actions**:
   - Writes mode to `config.conf`
   - Installs Upstart job for boot persistence
   - Stops existing processes cleanly
   - Starts new mode immediately
3. **Upstart Service**: `btkeepalive_wrapper.sh` reads mode and launches correct `btconnect.sh`
4. **BT Connection**: Scripts listen for disconnect events and auto-reconnect
5. **Disable**: Removes Upstart job, kills all processes, restores vanilla Kindle

---

## Usage Verification

After selecting a mode, verify with:

```bash
# Check service status
initctl status btkeepalive
# Expected: "btkeepalive start/running, process XXXX"

# View logs
tail -f /mnt/us/btkeepalive/log/wrapper.log
tail -f /mnt/us/btkeepalive/log/btkeepalive.log
```

---

## Acknowledgements

- [**@notmarek**](https://github.com/notmarek) — for [kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite), a lightweight SSH solution for Kindle.
- [**@kbarni**](https://github.com/kbarni) — for [KinAMP](https://github.com/kbarni/KinAMP), a native music player for Kindle that works beautifully on e-ink displays.
- [**KUAL Team**](https://wiki.mobileread.com/wiki/KUAL) — for the Kindle Unified Application Launcher.
- [**KOReader Team**](https://github.com/koreader/koreader) — for the open-source document viewer and its extensible plugin system.

---

## ⚠️ Disclaimer

**This project is strictly the result of academic study and personal experimentation.**

The author **disclaims all responsibility** for any potential hardware or software damage, data loss, or the voiding of device warranties that may arise from the use or installation of this software. By utilizing this script, the user acknowledges and accepts all associated risks. This software is provided "as is," without any guarantees of performance or stability.

---

## 📄 License

This project is licensed under the [MIT License](https://github.com/imanubdesigner/kindle-bt-keepalive?tab=MIT-1-ov-file#readme) - see the LICENSE file for details.

---

<br>

<p align="center">
  <img src="https://img.shields.io/badge/-Craated%20with%20%E2%9D%A4%EF%B8%8F%20%E2%98%95%20for%20readers%20everywhere%20%F0%9F%93%9A-888888?style=for-the-badge" alt="footer">
</p>
