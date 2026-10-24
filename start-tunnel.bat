@echo off
title Sarkari Job Alert - Public Tunnel (Bypass Wi-Fi / Firewall)
color 0a
echo ======================================================================
echo       SARKARI JOB ALERT - PUBLIC TUNNEL (HTTPS)
echo ======================================================================
echo.
echo Starting localtunnel on port 5000...
echo This will generate a public HTTPS link you can open on your phone
echo without ANY Wi-Fi or Windows Firewall restrictions!
echo.
call npx localtunnel --port 5000
pause
