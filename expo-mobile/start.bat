@echo off
title Sarkari Job Alert - Expo Mobile Runner
color 0b
echo ======================================================================
echo           SARKARI JOB ALERT - EXPO MOBILE RUNNER
echo ======================================================================
echo.
cd /d "%~dp0"

call node -v
call npm -v

echo.
echo Starting Expo Development Server for Expo Go...
echo Scan the QR code below using the Expo Go app on your phone:
echo.

call npx expo start --go

if %errorlevel% neq 0 (
    call npx expo start
)

echo.
echo Server finished or stopped.
pause
