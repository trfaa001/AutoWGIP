log() {
    if [ "$LOGGING" = "off" ]; then
        return
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$0] $*" >>"$LOG_FILE"
}

validate_port() {
    local PORT="$1"
    #Check if the port is in the rangr 1-65535
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        log "Error: PORT ($PORT) is not valid. Must be between 1 and 65535."
        exit 1
    fi
}


validate_ip() {
    local IP="$1"

    if [[ -z "$IP" ]]; then
        log "Could not fetch current local IP!"
        return 1
    fi

    # Try IPv4 with ipcalc
    if ipcalc -c "$IP/32" >/dev/null 2>&1; then
        log "Valid ipcalc"
        return 0
    fi

    # Try IPv6 with sipcalc or getent
    if command -v sipcalc >/dev/null; then
        if sipcalc "$IP" >/dev/null 2>&1; then
            log "Valid sipcalc"
            return 0
        fi
    else
        if getent hosts "$IP" >/dev/null 2>&1; then
            log "Valid getent"
            return 0
        fi
    fi

    log "Invalid IP"
    return 1
}

run_in_ct() {
    local CTID="$1"; shift
    
    if ! pct exec "$CTID" -- "$@"; then
        log "Error: command '$*' failed in container $CTID"
        exit 4
    fi
}

check_file_existance() {
    local File="$1"

    if [ -f "$File" ]; then
        return 0
    else
        return 1
    fi
}

get_current_ip() {
    local ip=""

    log "IP_SOURCES count: ${#IP_SOURCES[@]}"

    for src in "${IP_SOURCES[@]}"; do

        log "src: $src"

        ip=$(curl -4 -s --max-time 3 "$src" 2>&1)
        ip="${ip//$'\n'/}"
        
        log "curl output from $src: '$ip'"

        # Skip empty responses
        [ -z "$ip" ] && continue

        # Validate if IP_VERIFICATION is on
        if [ "$IP_VERIFICATION" = "on" ]; then
            if validate_ip "$ip"; then
                echo "$ip"
                return 0
            else
                log "Invalid IP returned from $src: $ip"
            fi
        else
            echo "$ip"
            return 0
        fi
    done

    # If all sources fail
    log "All IP sources failed"
    return 1
}