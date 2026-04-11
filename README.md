

# 🌬️ RPI5FanControl

### Manual Fan Speed Enforcement for Raspberry Pi 5

<p align="center">
  <img src="logo (2).png" alt="RPI5FanControl Logo" width="500"/>
</p>

---

## 🚀 Overview

**RPI5FanControl** is a lightweight yet powerful Bash utility that gives you **full manual control over the Raspberry Pi 5 fan**.

Unlike the default firmware—which dynamically and sometimes unpredictably overrides fan speed—this tool **forces and maintains a fixed speed** using a resilient background daemon.

---

## ✨ Key Features

* 🎯 **Manual fan control (0–4 levels)**
* 🔁 **Persistent daemon** that:

  * Survives SSH disconnections
  * Detects firmware overrides
  * Instantly restores your chosen speed
* ⚡ **Ultra-fast reaction time** (~150 ms)
* 📊 **Live status display**:

  * CPU temperature
  * Fan speed & percentage
  * Daemon state
* 🧾 **Detailed logging** in `/tmp/pi5_fan_control.log`
* 🎨 **Colorized terminal output**
* 🧹 **Automatic cleanup** (PID + temp files)
* 🔒 **Input validation (safe values only)**

---

## 📌 Requirements

* Raspberry Pi **5**
* Official **active cooler (fan)**
* Linux system with access to:

  * `/sys/class/thermal/cooling_device0`
  * `/sys/class/thermal/thermal_zone0`
* **sudo/root privileges**

---

## 📥 Installation

```bash
git clone https://github.com/iyotee/RPI5FanControl
cd RPI5FanControl
chmod +x fan.sh
```

---

## 🕹️ Usage

### ▶️ Set a fixed fan speed

```bash
sudo ./fan.sh --speed N
```

Where **N = 0–4**:

| Level | Description             |
| ----- | ----------------------- |
| 0     | 🔇 Off (~60°C max)      |
| 1     | 🤫 Low (quiet, 50–60°C) |
| 2     | ⚖️ Medium (40–50°C)     |
| 3     | 🔊 High (35–45°C)       |
| 4     | 🚀 Max cooling (loud)   |

**Example:**

```bash
sudo ./fan.sh --speed 3
```

---

### ⛔ Stop daemon (عودة au mode automatique firmware)

```bash
sudo ./fan.sh --stop
```

---

### 📊 Show status

```bash
sudo ./fan.sh --status
```

Displays:

* CPU temperature 🌡️
* Current fan speed
* Max speed
* Percentage
* Daemon status
* Recent logs

---

### 🧾 Show logs

```bash
sudo ./fan.sh --logs
```

Or:

```bash
sudo ./fan.sh --logs 50
```

---

### ❓ Help

```bash
sudo ./fan.sh --help
```

---

## ⚙️ How It Works

The script directly interacts with the Linux thermal system:

* `/sys/class/thermal/cooling_device0/cur_state`
* `/sys/class/thermal/cooling_device0/max_state`
* `/sys/class/thermal/thermal_zone0/temp`

### 🔁 Daemon Logic

1. Continuously writes the target speed
2. Detects firmware overrides
3. Instantly restores your value
4. Logs all activity

✔ Preventive rewrite every 20 cycles
✔ Real-time correction tracking

---

## 🧾 Log File

```
/tmp/pi5_fan_control.log
```

**Example:**

```
[12:03:15] Daemon started (PID: 1234)
[12:03:15] Target speed: 3
[12:03:20] ⚠️ Firmware override: 3 -> 1 (restored)
[12:04:00] ✓ Active – 200 cycles, 42°C, 12 corrections
```

---

## ⚠️ Limitations

* Requires **root privileges**
* Only compatible with **Raspberry Pi 5**
* Overrides firmware behavior
* ❌ No automatic temperature curve (manual only)

---

## 🧑‍💻 Author

**Jeremy Noverraz (1988–2026)**
📦 Version: `2026.0114`
📅 Created: 14 January 2026

---

## 💡 Suggestions for Repo Structure

Pour que le logo fonctionne correctement, ajoute :

```
RPI5FanControl/
│── fan.sh
│── README.md
└── docs/
    └── logo.png   ← ton image
```

👉 Renomme ton image en `logo.png` et place-la dans `docs/`.

---

Si tu veux, je peux aussi te faire :

* une **version GitHub ultra stylée (badges, shields, dark mode)**
* ou une **page projet type landing (README premium)**
