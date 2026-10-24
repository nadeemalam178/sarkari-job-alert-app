@echo off
title Sarkari Job Alert - Expo Mobile App (Phone Debugging)
echo ========================================================
echo       Sarkari Job Alert - Expo Mobile Runner
echo ========================================================
echo.
cd /d "%~dp0\expo-mobile"

echo [1/3] Checking Node.js and dependencies...
if not exist node_modules (
    echo Installing Expo & React Native dependencies (one-time setup)...
    call npm install
)

echo.
echo ========================================================
echo   HOW TO DEBUG ON YOUR PHONE:
echo   1. Install 'Expo Go' app from Play Store / App Store
echo   2. Make sure your Phone and PC are on the same Wi-Fi
echo   3. Scan the QR code shown below with Expo Go!
echo ========================================================
echo.
echo Starting Expo Development Server...
call npx expo start
pause
