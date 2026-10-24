@echo off
title Sarkari Job Alert - Expo Mobile Runner
color 0b
echo ======================================================================
echo           SARKARI JOB ALERT - EXPO MOBILE RUNNER
echo ======================================================================
echo.
cd /d "%~dp0"

echo [1/2] Checking dependencies...
if not exist "node_modules\expo" (
    echo Installing Expo & React Native dependencies...
    call npm install
)

echo.
echo [2/2] Starting Expo Development Server for Expo Go...
echo Scan the QR code below using the Expo Go app on your phone:
echo.

call npx expo start --go

echo.
echo Expo server stopped.
pause
