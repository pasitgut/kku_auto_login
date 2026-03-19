#!/bin/bash

KKU_HOST="nac03.kku.ac.th"

INTERNET_HOST="8.8.8.8"

KKU_LOGIN_URL="https://nac03.kku.ac.th/login"
KKU_LOGOUT_URL="https://nac03.kku.ac.th/logout"

KKU_USERNAME="KKU_STUDENTID" # Don't use "-"
KKU_PASSWORD="KKU_PASSWORD"

log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_internet() {

        ping -c 1 -W 2 "$INTERNET_HOST" > /dev/null 2>&1
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
                log "Internet connection is down. Attemping to log in to KKU WiFi..."

                if [ -z "$KKU_USERNAME" ]; then
                        log "Error: Please set your KKU_USERNAME in the script."
                        exit 1
                fi

                curl -s -k -X POST "$KKU_LOGIN_URL" --data "username=$KKU_USERNAME&password=$KKU_PASSWORD" > /dev/null

                log "Login attempt sent. Verifying connection status..."

                sleep 2

                if check_internet; then
                        log "Success: Login successful. Internet connection is now active."
                else
                        log "Failed: Login failed. Please check your username/password or network status."

                fi
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
