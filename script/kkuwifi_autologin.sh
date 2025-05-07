#!/bin/bash

USERNAME="STUDENTID"
PASSWORD="PASSWORD"
LOGIN_URL="https://nac15.kku.ac.th/login"

check_internet() {
  ping -c 1 8.8.8.8 &>/dev/null
  return $?
}

do_login() {
  echo "Please with to login kku wifi"
  curl -s -X POST "$LOGIN_URL" -d "username=$USERNAME&password=$PASSWORD" >/dev/null
  echo "login Successful"
}

echo "Check Connection ..."

if check_internet; then
  echo "You connect successful"
else
  echo "You don't connection to internet"
  do_login
fi
