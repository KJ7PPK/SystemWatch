# SystemWatch

![Shell](https://img.shields.io/badge/script-bash-blue.svg)
![License](https://img.shields.io/github/license/yourusername/systemwatch)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![NTFY](https://img.shields.io/badge/notifications-ntfy.sh-orange)

**SystemWatch** is a lightweight host-level monitoring tool for Linux systems. It checks for critical health conditions and sends real-time push notifications via [ntfy.sh](https://ntfy.sh) or a self-hosted NTFY instance.

---

## 🔍 Features

SystemWatch monitors and sends NTFY alerts for:

- High CPU load
- Low disk space on the root filesystem
- SMART disk health failures
- OpenMediaVault (OMV) engine status
- SSH login events

---

## ✅ Compatibility

**Tested on:**
- Debian 11+
- Ubuntu 20.04 / 22.04
- Raspberry Pi OS (Bullseye / Bookworm)
- OpenMediaVault 6.x (Debian-based)

**Requirements:**
- `bash`, `curl`, `bc`, `smartmontools`, `systemd`
- If using OMV or MergerFS monitoring, those must be installed or enabled during setup

---

## 🚀 Installation

### Option 1: Manual Installation

```bash
sudo cp systemwatch.sh /usr/local/bin/systemwatch.sh
sudo chmod +x /usr/local/bin/systemwatch.sh
sudo cp systemwatch.service /etc/systemd/system/
sudo cp systemwatch.timer /etc/systemd/system/
sudo mkdir -p /etc/systemwatch/
sudo cp systemwatch.conf /etc/systemwatch/systemwatch.conf
sudo systemctl daemon-reexec
sudo systemctl enable --now systemwatch.timer
```

### Option 2: Run Setup Script

```bash
chmod +x setup.sh
sudo ./setup.sh
```

The setup script will:
- Prompt you for NTFY credentials and hostname
- Ask which features to monitor
- Auto-disable features if required components are missing
- Install and enable the timer service

---

## ⚙️ Configuration

After installation, you can modify which features are monitored by editing:

```bash
/etc/systemwatch/systemwatch.conf
```

Each capability can be toggled `true` or `false`.

---

## ⏱ Notification Frequency & Behavior

SystemWatch runs every **5 minutes** by default using a systemd timer:

- **First check:** 2 minutes after boot
- **Recurring:** Every 5 minutes (`OnUnitActiveSec=5min`)

You can adjust this interval by editing:

```bash
sudo nano /etc/systemd/system/systemwatch.timer
```

Then reload:

```bash
sudo systemctl daemon-reexec
sudo systemctl restart systemwatch.timer
```

### 🧠 Alert Behavior

SystemWatch uses temp flags in `/tmp/systemwatch/` to avoid duplicate notifications:

- You receive one alert per condition
- No re-alerting unless the condition clears and returns

---

## 📄 License

MIT
