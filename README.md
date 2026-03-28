# Kindle Bluetooth Keepalive

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Kindle](https://img.shields.io/badge/kindle-FF9900?style=for-the-badge&logo=amazon&logoColor=white) ![License MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge) ![Bluetooth](https://img.shields.io/badge/bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white) ![Upstart](https://img.shields.io/badge/upstart-333333?style=for-the-badge&logo=linux&logoColor=white)

Keep your Bluetooth headphones connected on a jailbroken Kindle, without unexpected disconnections caused by screen saver or suspend mode.

Tested on **Kindle Signature 11th Generation, firmware 5.18.5.0.1**.

---

## Choose your variant

| | [reading-mode](./reading-mode/) | [always-on](./always-on/) |
|---|---|---|
| **Use case** | Reading with BT headphones | Continuous audio playback (iPod Style) |
| **Deep sleep** | ✅ Normal — preserves battery | ⚠️ Deferred — keeps device awake |
| **Reconnect on low battery** | Skipped below threshold | Always attempts |
| **Battery impact** | Minimal | Higher |
| **Recommended for** | Most users | Extended listening sessions |

---

## Prerequisites

Both variants require:

- Jailbroken Kindle
- SSH access via [kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite) by [@notmarek](https://github.com/notmarek), or KTerm installed
- [KinAMP](https://github.com/kbarni/KinAMP) by [@kbarni](https://github.com/kbarni) — native music player for Kindle (optional, but recommended)
- Bluetooth device already paired at least once via the Kindle UI (Settings → Bluetooth)

---

## Acknowledgements

- [**@notmarek**](https://github.com/notmarek) — for [kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite), a lightweight SSH solution for Kindle.
- [**@kbarni**](https://github.com/kbarni) — for [KinAMP](https://github.com/kbarni/KinAMP), a native music player for Kindle that works beautifully on e-ink displays.
