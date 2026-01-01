CONFIG_FILE="/etc/wgAUTO/AUTOwgIP.conf"
INSTALL_PATH="/usr/local/bin/autoWG"
FUNCTIONS_FILE="/usr/local/bin/functions.sh"

# Check if config file exists to pull the config file location
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    : "${LOG_FILE:=/var/log/wgAUTO.log}"
else
    echo "Config file not found at $CONFIG_FILE"
    echo "Using fallback location for the log file"
    LOG_FILE="/var/log/wgAUTO.log"
fi

confirm() {
    while true; do
        read -p "Are you sure you want to uninstall autoWG? [Y/N] " yn

        if [ "$yn" = "" ]; then
            yn='N'
        fi

        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

uninstall() {
    echo "Removing cron job..."
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "$INSTALL_PATH" | crontab -
    fi


    echo "Removing scripts..."
    rm -f "$INSTALL_PATH"
    rm -f "$FUNCTIONS_FILE"

    echo "Removing config file..."
    rm -f "$CONFIG_FILE"

    echo "Removing log file..."
    rm -f "$LOG_FILE"

    echo "Removing data file..."
    rm -f /etc/wgAUTO/data.conf


    echo "autoWG has been fully uninstalled."
}

if confirm; then
    echo "Proceeding with uninstallation..."

    uninstall
else
    echo "Aborting..."
    exit 1
fi