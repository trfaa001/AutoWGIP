#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/wgAUTO.log"

source "functions.sh"

#You may need to change these
FILE_PATH="/etc/wireguard/wg0.conf" #File path to the wireguard config
PORT="8473" #Wireguard port

CURRENT_IP=$(curl -s ifconfig.me) #Can be replaced with other providers/services
SAVED_IP=$(cat /etc/wgAUTO/data.conf)

echo "Host current public IP: $CURRENT_IP Host saved IP: $SAVED_IP" 

validate_port "$PORT"

validate_ip "$CURRENT_IP"

#Only changes the ip if the ip has changed
if [ "$CURRENT_IP" != "$SAVED_IP" ]; then
        printf "$CURRENT_IP" > /etc/wgAUTO/data.conf

        for CTID in $(pct list | awk 'NR>1 {print $1}'); do
                log "container" "$CTID" "found!"

            if pct exec "$CTID" -- test -f "$FILE_PATH"; then
                log "File $FILE_PATH exists in container $CTID"

                run_in_ct "$CTID" cp "$FILE_PATH" "$FILE_PATH.bak"

                log "[$CTID] Updating WireGuard endpoint to $CURRENT_IP:$PORT"
                run_in_ct "$CTID" sed -i "10s|.*|Endpoint = $CURRENT_IP:$PORT|" "$FILE_PATH"
                run_in_ct "$CTID" wg-quick down wg0
                run_in_ct "$CTID" wg-quick up wg0
            else
                log "[$CTID] does not have the file $FILE_PATH"
            fi
        done
fi