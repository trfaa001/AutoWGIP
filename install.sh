#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/wgAUTO.log"
CONFIG_DIR="/etc/wgAUTO"
DATA_FILE="$CONFIG_DIR/data.conf"
INSTALL_PATH="/usr/local/bin/autoWG"
CRON_JOB="*/20 * * * * $INSTALL_PATH >> $LOGFILE 2>&1"

echo "Starting installation..."

echo "Creating config directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [ ! -f "$DATA_FILE" ]; then
    echo "Initializing data.conf..."
    touch "$DATA_FILE"
    chmod 600 "$DATA_FILE"
fi

echo "Creating log file at $LOGFILE..."
touch "$LOGFILE"
chmod 640 "$LOGFILE"

# Deploy main script
if [ -f "src/main.sh" ]; then
    cp "src/main.sh" "$INSTALL_PATH"
    chmod 755 "$INSTALL_PATH"
    echo "Installed autoWG to $INSTALL_PATH"
else
    echo "Error: src/main.sh not found"
    exit 1
fi

# Add cron job
if ! crontab -l 2>/dev/null | grep -q "$INSTALL_PATH"; then
    echo "Adding cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "Cron job already exists."
fi

echo "Installation complete!"