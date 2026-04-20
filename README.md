# Kindle Bluetooth Keepalive

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="logo/kindle-bt-keepalive-logo-dark.png">
    <img alt="kindle-bt-keepalive logo" src="logo/kindle-bt-keepalive-logo.png" width="452">
  </picture>
</p>



![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Kindle](https://img.shields.io/badge/kindle-FF9900?style=for-the-badge&logo=amazon&logoColor=white) ![License MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge) ![Bluetooth](https://img.shields.io/badge/bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white) ![Upstart](https://img.shields.io/badge/upstart-333333?style=for-the-badge&logo=linux&logoColor=white)

Keep your Bluetooth headphones connected on a jailbroken Kindle, without unexpected disconnections caused by screen saver or suspend mode.

Tested on **Kindle Paperwhite 11th Generation, firmware 5.18.5.0.1**.

---

## Rationale & Inspiration 🍃

For me, reading is far more than a mere intellectual exercise; it is a profoundly immersive ritual. There is an unparalleled serenity in losing oneself within the pages of a book while enveloped by the rhythmic cadence of **falling rain** or the evocative symphony of a **secluded woodland**.

I have always sought to curate my reading environment with the delicate sounds of nature: the gentle rustle of foliage, the distant call of avian life, and the subtle creaking of timber. These elements do not distract; rather, they serve as a sanctuary for the mind to wander.

This project was born out of a necessity to preserve that very atmosphere. I discovered that the Kindle's power-saving measures often sever the Bluetooth connection during periods of sonic subtlety, abruptly shattering the immersion. This script is a modest endeavor, conceived for **educational purposes and personal exploration**, to ensure that the whisper of the forest or the patter of the rain remains uninterrupted. It is, in essence, a tool crafted to safeguard the sanctity of the reading experience.

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

---

## ⚠️ Disclaimer

**This project is strictly the result of academic study and personal experimentation.**

The author **disclaims all responsibility** for any potential hardware or software damage, data loss, or the voiding of device warranties that may arise from the use or installation of this software. By utilizing this script, the user acknowledges and accepts all associated risks. This software is provided "as is," without any guarantees of performance or stability.

---

## 📄 License

This project is licensed under the [MIT License](https://github.com/imanubdesigner/kindle-bt-keepalive?tab=MIT-1-ov-file#readme) - see the file for details.
