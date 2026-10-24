@echo off
title Sarkari Job Alert - Expo Mobile Runner
color 0b
echo ======================================================================
echo           SARKARI JOB ALERT - EXPO MOBILE RUNNER
echo ======================================================================
echo.

:: Navigate safely
cd /d "%~dp0"
if exist "expo-mobile" (
    cd "expo-mobile"
)

echo [1/2] Checking environment...
where node >nul 2>&1
if %errorlevel% neq 0 goto ERROR_NODE

call node -v
call npm -v

echo.
echo ======================================================================
echo   HOW TO CONNECT AND DEBUG ON YOUR PHONE:
echo   1. Install 'Expo Go' app from Google Play Store or Apple App Store
echo   2. Connect your Phone and PC to the SAME WI-FI network
echo   3. Scan the QR code shown below using Expo Go!
echo ======================================================================
echo.
echo [2/2] Starting Expo Development Server...
echo.

call npx expo start --go

if %errorlevel% neq 0 (
    echo.
    echo [Retry] Running standard Expo start...
    call npx expo start
)

echo.
echo Server finished or stopped.
pause
exit /b 0

:ERROR_NODE
echo.
echo [ERROR] Node.js was not detected in PATH!
echo Please make sure Node.js is installed from https://nodejs.org
echo.
pause
exit /b 1
