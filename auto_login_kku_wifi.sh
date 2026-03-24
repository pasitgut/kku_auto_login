#!/bin/bash

KKU_HOST="nac03.kku.ac.th"
INTERNET_HOST="https://google.com"

KKU_LOGIN_URL="https://nac03.kku.ac.th/login"
KKU_LOGOUT_URL="https://nac03.kku.ac.th/logout"

KKU_USERNAME="KKU_STUDENTID"
KKU_PASSWORD="KKU_PASSWORD"

MAX_RETRY=2

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_internet() {
    #ping -c 1 -W 2 "$INTERNET_HOST" > /dev/null 2>&1
    curl -s --max-time 3 "$INTERNET_HOST" > /dev/null 2>&1
    return $?
}

log "Checking KKU WiFi connection..."

log "Logging out from KKU WiFi session..."
curl -s -k "$KKU_LOGOUT_URL" > /dev/null

sleep 2

ping -c 1 -W 1 "$KKU_HOST" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Connected to KKU WiFi Network. Now checking internet access..."

    if check_internet; then
        log "Internet connection is active"
    else
        log "Internet connection is down. Attempting to log in to KKU WiFi..."

        if [ -z "$KKU_USERNAME" ]; then
            log "Error: Please set your KKU_USERNAME in the script."
            exit 1
        fi

        for ((i=1;i<=MAX_RETRY;i++)); do
            log "Login attempt $i..."

            curl -s -k -X POST "$KKU_LOGIN_URL" \
                --data "username=$KKU_USERNAME&password=$KKU_PASSWORD" \
                > /dev/null

            sleep 2

            if check_internet; then
                log "Success: Login successful. Internet connection is now active."
                exit 0
            else
                log "Login attempt $i failed."
            fi
        done

        log "Failed: Login failed after $MAX_RETRY attempts. Please check your username/password or network status."
    fi
else
    log "Not connected to KKU network. Checking general internet connection..."

    ping -c 1 -W 1 "$INTERNET_HOST" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log "Internet connection is active"
    else
        log "Internet connection is down"
    fi
fi
