#!/usr/bin/env bash

set -euo pipefail

# =========================
# Configuration
# =========================

KKU_HOST="nac03.kku.ac.th"
LOGIN_URL="https://nac03.kku.ac.th/login"

INTERNET_TEST_URL="http://connectivitycheck.gstatic.com/generate_204"

KKU_USERNAME="KKU_STUDENTID"
KKU_PASSWORD="KKU_PASSWORD"

MAX_RETRY=2
TIMEOUT=3

STATE_FILE="/tmp/kku_wifi_last_login"
LOCK_FILE="/tmp/kku_wifi.lock"

LOGIN_COOLDOWN=1800   # 30 minutes

# =========================
# Lock (prevent concurrent runs)
# =========================

exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

# =========================
# Logging
# =========================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# =========================
# Network Checks
# =========================

check_kku_network() {
    ping -c1 -W1 "$KKU_HOST" &>/dev/null
}

check_internet() {
    curl -fs --max-time "$TIMEOUT" "$INTERNET_TEST_URL" &>/dev/null
}

# =========================
# Cooldown Control
# =========================

can_login() {

    if [[ ! -f "$STATE_FILE" ]]; then
        return 0
    fi

    last=$(cat "$STATE_FILE")
    now=$(date +%s)

    diff=$((now-last))

    if (( diff > LOGIN_COOLDOWN )); then
        return 0
    fi

    return 1
}

record_login() {
    date +%s > "$STATE_FILE"
}

# =========================
# KKU Auth
# =========================

kku_login() {
    curl -s -k -X POST "$LOGIN_URL" \
        --data "username=$KKU_USERNAME&password=$KKU_PASSWORD" \
        &>/dev/null
}

# =========================
# Login Flow
# =========================

attempt_login() {

    for ((i=1;i<=MAX_RETRY;i++)); do

        log "Login attempt $i/$MAX_RETRY..."

        kku_login

        sleep 2

        if check_internet; then
            log "Login successful."
            record_login
            return 0
        fi

        log "Login attempt failed."

    done

    return 1
}

# =========================
# Main
# =========================

main() {

    log "Checking internet connectivity..."

    if check_internet; then
        log "Internet already active."
        exit 0
    fi

    log "Internet unavailable."

    if ! check_kku_network; then
        log "Not connected to KKU WiFi."
        exit 1
    fi

    log "Connected to KKU WiFi."

    if ! can_login; then
        log "Login cooldown active. Skipping login."
        exit 0
    fi

    if attempt_login; then
        exit 0
    else
        log "Login failed after $MAX_RETRY attempts."
        exit 1
    fi
}

main
