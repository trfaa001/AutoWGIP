#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/wgAUTO.log"
CONFIG_DIR="/etc/wgAUTO"
CONFIG_FILE="$CONFIG_DIR/AUTOwgIP.conf"
DATA_FILE="$CONFIG_DIR/data.conf"
INSTALL_PATH="/usr/local/bin/autoWG"
FUNCTIONS_PATH="/usr/local/bin/functions.sh"
CRON_JOB="*/20 * * * * $INSTALL_PATH >> $LOGFILE 2>&1"

echo "Starting installation..."

echo "Creating config directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Deploy data file

echo "Initializing data.conf..."
touch "$DATA_FILE"
chmod 600 "$DATA_FILE"

# Deploy log file

echo "Creating log file at $LOGFILE..."
touch "$LOGFILE"
chmod 640 "$LOGFILE"

# Deploy config file
echo "Creating config file at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
cp "src/default.conf" "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"

# Deploy main script
if [ -f "src/main.sh" ]; then
    cp "src/main.sh" "$INSTALL_PATH"
    cp "src/functions.sh" "$FUNCTIONS_PATH"
    chmod 755 "$INSTALL_PATH"
    chmod 755 "$FUNCTIONS_PATH"
    echo "Installed autoWG to $INSTALL_PATH"
else
    echo "Error: src/main.sh not found"
    exit 1
fi

# Add cron job
if ! crontab -l 2>/dev/null | grep -q "$INSTALL_PATH"; then
    ( crontab -l 2>/dev/null || true; echo "$CRON_JOB" ) | crontab -
else
    echo "Cron job already exists."
fi


echo "Installation complete!"