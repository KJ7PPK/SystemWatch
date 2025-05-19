#!/bin/bash

echo "=== SystemWatch Setup ==="

read -p "Hostname label for notifications (e.g., mainframe): " HOST
read -p "NTFY username: " USER
read -s -p "NTFY password: " PASS; echo
read -p "NTFY topic: " TOPIC
read -p "NTFY base URL (e.g., https://ntfy.example.com): " BASE

echo "Configuring monitoring features..."

FEATURES=(
  "MONITOR_LOAD:Monitor high CPU load"
  "MONITOR_DISK:Monitor disk space usage"
  "MONITOR_SMART:Monitor SMART disk health"
  "MONITOR_OMV:Monitor OpenMediaVault engine status"
  "MONITOR_SSH:Monitor SSH logins"
)

CONFIG_FILE="/etc/systemwatch/systemwatch.conf"
mkdir -p /etc/systemwatch
: > "$CONFIG_FILE"

for ITEM in "${FEATURES[@]}"; do
  KEY="${ITEM%%:*}"
  DESC="${ITEM#*:}"

  read -p "$DESC? (y/n): " RESP
  if [[ "$RESP" == "y" || "$RESP" == "Y" ]]; then
    if [[ "$KEY" == "MONITOR_SMART" ]]; then
      if ! command -v smartctl >/dev/null; then
        echo "smartmontools not found. Install it? (y/n): "
        read ANS
        if [[ "$ANS" == "y" || "$ANS" == "Y" ]]; then
          apt update && apt install -y smartmontools
          echo "$KEY=true" >> "$CONFIG_FILE"
        else
          echo "$KEY=false" >> "$CONFIG_FILE"
        fi
        continue
      fi
    elif [[ "$KEY" == "MONITOR_OMV" ]]; then
      if ! systemctl list-units --all | grep -q openmediavault-engined; then
        echo "OMV not detected. Skip monitoring? (y/n): "
        read ANS
        if [[ "$ANS" == "y" || "$ANS" == "Y" ]]; then
          echo "$KEY=false" >> "$CONFIG_FILE"
          continue
        fi
      fi
    fi
    echo "$KEY=true" >> "$CONFIG_FILE"
  else
    echo "$KEY=false" >> "$CONFIG_FILE"
  fi
done

echo "Embedding config into systemwatch.sh..."
sed -i "s/HOST="mainframe"/HOST="$HOST"/" systemwatch.sh
sed -i "s/NTFY_USER="notify"/NTFY_USER="$USER"/" systemwatch.sh
sed -i "s/NTFY_PASS="Ghj74Lmn25rTqv8X"/NTFY_PASS="$PASS"/" systemwatch.sh
sed -i "s|NTFY_URL="https://notify.chawthorne.com/\${NTFY_TOPIC}"|NTFY_URL="$BASE/\${NTFY_TOPIC}"|" systemwatch.sh
sed -i "s/NTFY_TOPIC="The_Home_Lab"/NTFY_TOPIC="$TOPIC"/" systemwatch.sh

echo "Installing..."
cp systemwatch.sh /usr/local/bin/systemwatch.sh
chmod +x /usr/local/bin/systemwatch.sh
cp systemwatch.service /etc/systemd/system/
cp systemwatch.timer /etc/systemd/system/
systemctl daemon-reexec
systemctl enable --now systemwatch.timer

echo "✅ Setup complete. SystemWatch is now running every 5 minutes."
