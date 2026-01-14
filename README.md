# RPI5FanControl — Manual Fan Speed Enforcement for Raspberry Pi 5

This project provides a robust Bash script that **forces and maintains a fixed fan speed** on the Raspberry Pi 5.  
It is designed to **override the Raspberry Pi firmware**, which normally resets the fan speed automatically and unpredictably.

The script runs a **background daemon** that continuously enforces the target speed, detects firmware overrides, and restores your chosen value within milliseconds.

---

## ✨ Features

- **Full manual control** of the Raspberry Pi 5 active‑cooling fan  
- **Daemon mode** that:
  - Survives SSH disconnections  
  - Detects firmware speed changes  
  - Rewrites the fan state aggressively  
  - Logs all events to `/tmp/pi5_fan_control.log`
- **Status display** with temperature, fan speed, percentage, and daemon state
- **Safe validation** of speed values (0–4)
- **Automatic cleanup** of PID and target files
- **Colorized terminal output**
- **Very fast reaction time** (check interval: 0.15s)

---

## 📌 Requirements

- Raspberry Pi **5**  
- Raspberry Pi **active cooler** (fan connected to the official header)  
- Linux environment with access to:
  - `/sys/class/thermal/cooling_device0`
  - `/sys/class/thermal/thermal_zone0`
- **sudo/root privileges**

---

## 📥 Installation

```bash
git clone https://github.com/iyotee/RPI5FanControl
cd RPI5FanControl
chmod +x fan.sh
```

---

## 🚀 Usage

### Set a fixed fan speed

```bash
sudo ./fan.sh --speed N
```

Where **N** is between **0 and 4**:

| Level | Description |
|-------|-------------|
| 0 | Off (silent, CPU up to ~60°C) |
| 1 | Low (quiet, ~50–60°C) |
| 2 | Medium (~40–50°C) |
| 3 | High (audible, ~35–45°C) |
| 4 | Maximum cooling (loud) |

Example:

```bash
sudo ./fan.sh --speed 3
```

---

### Stop the daemon and return to automatic firmware control

```bash
sudo ./fan.sh --stop
```

---

### Show current status

```bash
sudo ./fan.sh --status
```

Displays:

- CPU temperature  
- Current fan state  
- Max fan state  
- Percentage  
- Daemon status  
- Recent log entries  

---

### Show logs

```bash
sudo ./fan.sh --logs
```

Or specify number of lines:

```bash
sudo ./fan.sh --logs 50
```

---

### Help

```bash
sudo ./fan.sh --help
```

---

## 🛠 How It Works

The script interacts directly with:

- `/sys/class/thermal/cooling_device0/cur_state`
- `/sys/class/thermal/cooling_device0/max_state`
- `/sys/class/thermal/thermal_zone0/temp`

The **daemon loop**:

1. Writes the target speed repeatedly  
2. Detects firmware overrides  
3. Restores your chosen speed instantly  
4. Logs events such as:
   - Firmware interference  
   - Temperature snapshots  
   - Speed changes  
   - Correction counts  

It also performs a **preventive rewrite every 20 cycles** to ensure stability.

---

## 📄 Log File

Logs are stored at:

```
/tmp/pi5_fan_control.log
```

Example entries:

```
[12:03:15] Daemon started (PID: 1234)
[12:03:15] Target speed: 3
[12:03:20] ⚠️ Firmware changed: 3 -> 1, restoring to 3
[12:04:00] ✓ Active – 200 cycles, 42°C, 12 corrections
```

---

## ⚠️ Notes & Limitations

- Must be run as **root**  
- Only works on **Raspberry Pi 5**  
- Overrides **firmware fan control**  
- Does **not** implement temperature‑based automatic curves  
- Intended for users who want **full manual control**  

---

## 🧑‍💻 Author

**Jeremy Noverraz (1988–2026)**  
Version: **2026.0114**  
Created: **14 January 2026**