@echo off
set CHECK_URL=https://www.google.com

:check_connection
:: ใช้ curl เพื่อโหลดหน้าเว็บและเช็ค HTTP Status Code
curl -s --head %CHECK_URL% | find "200 OK" >nul
if %errorlevel% neq 0 (
    echo No internet connection. Logging in...
    goto :auto_login
) else (
    echo Internet is up.
)
goto :sleep

:: ฟังก์ชั่น login อัตโนมัติ
:auto_login
curl -L -X POST "https://nac15.kku.ac.th/login" -d "username=STUDENTID&password=PASSWORD&dst=&popup=true"
echo Logged in successfully.
goto :sleep

:sleep
timeout /t 30 >nul
goto :check_connection
