#!/bin/bash

KKU_HOST="nac03.kku.ac.th"

INTERNET_HOST="8.8.8.8"

KKU_LOGIN_URL="https://nac03.kku.ac.th/login"
KKU_USERNAME="YOUR_STUDENT_ID"
KKU_PASSWORD="YOUR_PASSWORD"

check_internet() {

        ping -c 1 -W 2 "$INTERNET_HOST" > /dev/null 2>&1
        return $?
}

echo "Checking KKU WiFi connection..."

ping -c 1 -W 1 "$KKU_HOST" > /dev/null 2>&1

if [ $? -eq 0 ]; then
        echo "Connected to KKU WiFi Network. Now checking internet access..."

        curl -X GET "https://nac03.kku.ac.th/logout" > /dev/null
        if check_internet; then
                echo "Internet connection is active"
        else
                echo "Internet connection is down. Attemping to log in to KKU WiFi..."

                if [ -z "$KKU_USERNAME" ]; then
                        echo "Error: Please set your KKU_USERNAME in the script."
                        exit 1
                fi

                curl -s -k -X POST "$KKU_LOGIN_URL" --data "username=$KKU_USERNAME&password=$KKU_PASSWORD" > /dev/null

                echo "Login attempt sent. Verifying connection status..."

                sleep 2

                if check_internet; then
                        echo "Success: Login successful. Internet connection is now active."
                else
                        echo "Failed: Login failed. Please check your username/password or network status."
                fi
        fi
else
        echo "Not connected to KKU network. Checking general internet connection..."
        if check_internet; then
                echo "Internet connection is active"
        else
                echo "Internet connection is down"
        fi
fi
