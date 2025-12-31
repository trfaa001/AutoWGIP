#!/bin/bash
set -euo pipefail

source "functions.sh"

LOG_FILE="/var/log/wgAUTO.log"
CONFIG_FILE="/etc/wgAUTO/AUTOwgIP.conf"

#Check if config file exists before sourcing
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    log "Config file not found at $CONFIG_FILE"
    exit 1
fi

FILE_PATH="${WG_CONFIG_DIR}/${WG_INTERFACE_NAME}.conf" #File path to the wireguard config

SAVED_DATA=$(cat /etc/wgAUTO/data.conf 2>/dev/null || true)
SAVED_IP="${SAVED_DATA%%:*}"
SAVED_PORT="${SAVED_DATA##*:}"

CURRENT_IP=$(curl -s ifconfig.me) #Can be replaced with other providers/services
CURRENT_PORT=$PORT

echo "Host current public IP: $CURRENT_IP Host saved IP: $SAVED_IP"
echo "Host current port: $CURRENT_PORT Host saved port: $SAVED_PORT" 

if [ "$FORCE_MODE" = "on" ]; then
    log "Force mode on"
else
    if [ "$IP_VERIFICATION" = "on" ]; then
        validate_ip "$CURRENT_IP"
    else
        log "IP validation off"
    fi

    validate_port "$PORT"
fi


# Update if the ip or port change
if [ "$CURRENT_IP" != "$SAVED_IP" ] || [ "$CURRENT_PORT" != "$SAVED_PORT" ]; then
        printf "%s:%s" "$CURRENT_IP" "$CURRENT_PORT" > /etc/wgAUTO/data.conf

        for CTID in $(pct list | awk 'NR>1 {print $1}'); do
                log "container" "$CTID" "found!"

            if pct exec "$CTID" -- test -f "$FILE_PATH"; then
                log "File $FILE_PATH exists in container $CTID"

                if [ "$DRY_RUN" = "on" ]; then
                    log "[DRY RUN] Would run in CT $CTID with the file path $FILE_PATH"
                    log "[DRY RUN] Would update endpoint to $CURRENT_IP:$PORT"
                    continue
                fi

                run_in_ct "$CTID" cp "$FILE_PATH" "$FILE_PATH.bak"

                log "[$CTID] Updating WireGuard endpoint to $CURRENT_IP:$PORT"
                run_in_ct "$CTID" sed -i "10s|.*|Endpoint = $CURRENT_IP:$PORT|" "$FILE_PATH"
                run_in_ct "$CTID" wg-quick down ${WG_INTERFACE_NAME}.conf
                run_in_ct "$CTID" wg-quick up ${WG_INTERFACE_NAME}.conf
            else
                log "[$CTID] does not have the file $FILE_PATH"
            fi
        done
fi