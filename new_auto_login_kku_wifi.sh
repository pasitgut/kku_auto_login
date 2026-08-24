#!/bin/bash

# ============================================================
# KKU WiFi Auto Login
# เปลี่ยนแค่ 2 ค่านี้
# ============================================================

KKU_USERNAME="YOUR_USERNAME"
KKU_PASSWORD="YOUR_PASSWORD"

# ============================================================

set -u

KKU_HOST="nac03.kku.ac.th"
LOGIN_HOST="login.kku.ac.th"
CAPTIVE_URL="https://${KKU_HOST}/login?dst=http%3A%2F%2Fneverssl.com%2F"
INTERNET_HOST="8.8.8.8"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_internet() {
    ping -c 1 -W 2 "$INTERNET_HOST" >/dev/null 2>&1
}

# ------------------------------------------------------------
# 1. ตรวจ Internet ก่อน
# ------------------------------------------------------------

if check_internet; then
    log "Internet connection is active."
    exit 0
fi

log "Internet is unavailable."
log "Checking KKU captive portal..."

# ------------------------------------------------------------
# 2. ดึง MAC และ IP จาก KKU portal
#    ไม่ hardcode
# ------------------------------------------------------------

PORTAL_HTML=$(curl -k -sS --max-time 10 "$CAPTIVE_URL")

if [ -z "$PORTAL_HTML" ]; then
    log "ERROR: Cannot reach KKU captive portal."
    exit 1
fi

KKU_MAC=$(printf '%s\n' "$PORTAL_HTML" |
    sed -n 's/.*name="mac" value="\([^"]*\)".*/\1/p' |
    head -n 1)

KKU_IP=$(printf '%s\n' "$PORTAL_HTML" |
    sed -n 's/.*name="ip" value="\([^"]*\)".*/\1/p' |
    head -n 1)

if [ -z "$KKU_MAC" ]; then
    log "ERROR: Could not determine MAC from KKU portal."
    exit 1
fi

if [ -z "$KKU_IP" ]; then
    log "ERROR: Could not determine IP from KKU portal."
    exit 1
fi

log "KKU MAC: $KKU_MAC"
log "KKU IP : $KKU_IP"

# ------------------------------------------------------------
# 3. ตรวจ username/password
# ------------------------------------------------------------

if [ -z "$KKU_USERNAME" ] || [ "$KKU_USERNAME" = "YOUR_USERNAME" ]; then
    log "ERROR: Please set KKU_USERNAME."
    exit 1
fi

if [ -z "$KKU_PASSWORD" ] || [ "$KKU_PASSWORD" = "YOUR_PASSWORD" ]; then
    log "ERROR: Please set KKU_PASSWORD."
    exit 1
fi

# ------------------------------------------------------------
# 4. Normalize username แบบเดียวกับ KKU frontend
#
# lowercase
# remove spaces
# remove @kku.ac.th
# remove '-'
# ------------------------------------------------------------

USERNAME=$(printf '%s' "$KKU_USERNAME" |
    tr '[:upper:]' '[:lower:]' |
    tr -d ' ' |
    sed 's/@kku\.ac\.th$//' |
    tr -d '-')

log "Username: $USERNAME"

# ------------------------------------------------------------
# 5. สร้าง JSON payload
# ------------------------------------------------------------

PAYLOAD_JSON=$(python3 - "$USERNAME" "$KKU_PASSWORD" "$KKU_MAC" "$KKU_IP" <<'PY'
import json
import sys

username = sys.argv[1]
password = sys.argv[2]
mac = sys.argv[3]
ip = sys.argv[4]

payload = {
    "username": username,
    "password": password,
    "os": "Linux",
    "browser": "Chrome",
    "nas": "@nac03",
    "mac": mac,
    "ip": ip
}

print(json.dumps(payload, separators=(",", ":")))
PY
)

if [ -z "$PAYLOAD_JSON" ]; then
    log "ERROR: Failed to create payload."
    exit 1
fi

# ------------------------------------------------------------
# 6. Base64 encode
# ------------------------------------------------------------

PAYLOAD=$(printf '%s' "$PAYLOAD_JSON" | base64 -w0)

if [ -z "$PAYLOAD" ]; then
    log "ERROR: Failed to encode payload."
    exit 1
fi

# ------------------------------------------------------------
# 7. Stage 1
#    POST login.kku.ac.th/auth/authorize
# ------------------------------------------------------------

log "Authorizing KKU account..."

AUTH_RESPONSE=$(curl -k -sS --max-time 15 \
    -X POST \
    "https://${LOGIN_HOST}/auth/authorize" \
    --data-urlencode "payload=${PAYLOAD}")

if printf '%s' "$AUTH_RESPONSE" |
    grep -q '"type"[[:space:]]*:[[:space:]]*"success"'; then

    log "KKU account authorization successful."

else

    log "ERROR: KKU account authorization failed."
    log "Server response: $AUTH_RESPONSE"
    exit 1

fi

# ------------------------------------------------------------
# 8. Stage 2
#    POST ไปยัง MikroTik/NAC
# ------------------------------------------------------------

log "Activating KKU WiFi session..."

LOGIN_RESPONSE=$(curl -k -sS --max-time 15 \
    -X POST \
    "https://${KKU_HOST}/login" \
    --data-urlencode "username=${USERNAME}" \
    --data-urlencode "password=${KKU_PASSWORD}" \
    --data-urlencode "dst=" \
    --data-urlencode "popup=true")

# ------------------------------------------------------------
# 9. ตรวจผล login
# ------------------------------------------------------------

if printf '%s' "$LOGIN_RESPONSE" |
    grep -q "You are logged in"; then

    log "KKU WiFi login successful."

elif printf '%s' "$LOGIN_RESPONSE" |
    grep -qi "Incorrect Username or Password"; then

    log "ERROR: Incorrect username or password."
    exit 1

else

    log "WARNING: Login response was not recognized."
    log "Checking Internet anyway..."

fi

# ------------------------------------------------------------
# 10. ตรวจ Internet จริง
# ------------------------------------------------------------

sleep 2

if check_internet; then

    log "=========================================="
    log "Internet connection is now ACTIVE."
    log "=========================================="

    exit 0

else

    log "=========================================="
    log "ERROR: Login completed but Internet is DOWN."
    log "=========================================="

    exit 1

fi
