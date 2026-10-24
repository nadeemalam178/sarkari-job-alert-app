@echo off
title Sarkari Job Alert - Expo Mobile Runner
color 0b
echo ======================================================================
echo           SARKARI JOB ALERT - EXPO MOBILE RUNNER
echo ======================================================================
echo.

:: Navigate to expo-mobile folder safely
cd /d "%~dp0"
if exist "expo-mobile" (
    cd "expo-mobile"
)

echo [1/3] Checking Node.js environment...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH!
    echo Please install Node.js from https://nodejs.org
    pause
    exit /b 1
)
node -v
npm -v

echo.
echo [2/3] Checking Expo dependencies...
if not exist "node_modules\expo" (
    echo Dependencies not found. Installing now (this happens only once)...
    call npm install
)

echo.
echo ======================================================================
echo   HOW TO CONNECT AND DEBUG ON YOUR PHONE:
echo   1. Install 'Expo Go' app from Google Play Store or Apple App Store
echo   2. Connect your Phone and PC to the SAME WI-FI network
echo   3. Scan the QR code shown below using Expo Go!
echo   (Press 's' to switch between LAN and Tunnel if Wi-Fi has isolation)
echo ======================================================================
echo.
echo [3/3] Starting Expo Development Server for Expo Go...
echo.

call npx expo start --go

echo.
echo Expo server stopped.
pause
