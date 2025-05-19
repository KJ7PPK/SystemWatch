#!/bin/bash

# ---- CONFIG ----
HOST="mainframe"
NTFY_USER="notify"
NTFY_PASS="Ghj74Lmn25rTqv8X"
NTFY_TOPIC="The_Home_Lab"
NTFY_URL="https://notify.chawthorne.com/${NTFY_TOPIC}"
TMPDIR="/tmp/systemwatch"
CONF="/etc/systemwatch/systemwatch.conf"
[ -f "$CONF" ] && source "$CONF"
mkdir -p "$TMPDIR"
# ----------------

notify() {
  local MESSAGE="$1"
  local TITLE="${HOST}: ${MESSAGE}"
  curl -s -u "${NTFY_USER}:${NTFY_PASS}" \
       -H "Title: ${TITLE}" \
       -H "Priority: default" \
       -d "${MESSAGE}" \
       "${NTFY_URL}" > /dev/null
}

# --- Check for high load ---
if [ "$MONITOR_LOAD" = "true" ]; then
  LOAD=$(cut -d ' ' -f1 /proc/loadavg)
  if (( $(echo "$LOAD > 4.0" | bc -l) )); then
      FLAG="$TMPDIR/highload"
      if [ ! -f "$FLAG" ]; then
          notify "High load: $LOAD"
          touch "$FLAG"
      fi
  else
      rm -f "$TMPDIR/highload"
  fi
fi

# --- Check for low disk space ---
if [ "$MONITOR_DISK" = "true" ]; then
  THRESHOLD=90
  DISK_USE=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')
  if [ "$DISK_USE" -gt "$THRESHOLD" ]; then
      FLAG="$TMPDIR/diskfull"
      if [ ! -f "$FLAG" ]; then
          notify "Root disk over $THRESHOLD% ($DISK_USE%)"
          touch "$FLAG"
      fi
  else
      rm -f "$TMPDIR/diskfull"
  fi
fi

# --- Check for failed SMART status ---
if [ "$MONITOR_SMART" = "true" ]; then
  for DEV in /dev/sd?; do
      smartctl -H "$DEV" | grep -q "FAILED"
      if [ $? -eq 0 ]; then
          FLAG="$TMPDIR/smartfail.$(basename $DEV)"
          if [ ! -f "$FLAG" ]; then
              notify "SMART FAIL on $DEV"
              touch "$FLAG"
          fi
      else
          rm -f "$TMPDIR/smartfail.$(basename $DEV)"
      fi
  done
fi

# --- Check if OMV engine is active ---
if [ "$MONITOR_OMV" = "true" ]; then
  if ! systemctl is-active --quiet openmediavault-engined; then
      FLAG="$TMPDIR/omvdead"
      if [ ! -f "$FLAG" ]; then
          notify "OMV engine appears to be down"
          touch "$FLAG"
      fi
  else
      rm -f "$TMPDIR/omvdead"
  fi
fi

# --- SSH login detection ---
if [ "$MONITOR_SSH" = "true" ]; then
  LASTLOGIN="$TMPDIR/last_ssh"
  CURRENT=$(last -n 1 -F -a | grep 'still logged in' | head -n1)
  if [ "$CURRENT" != "$(cat $LASTLOGIN 2>/dev/null)" ]; then
      echo "$CURRENT" > "$LASTLOGIN"
      IP=$(echo "$CURRENT" | awk '{print $NF}')
      notify "New SSH login from $IP"
  fi
fi
