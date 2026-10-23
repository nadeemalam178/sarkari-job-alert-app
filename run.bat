@echo off
title Sarkari Result Job Alert Web App
echo ========================================================
echo       Launching Sarkari Result Job Alert System
echo ========================================================
echo.
cd /d "%~dp0"

echo [1/3] Checking dependencies...
python -m pip install -r requirements.txt --quiet

echo [2/3] Starting web server & background scraper...
start http://localhost:5000

echo [3/3] Server is live at http://localhost:5000
echo Press Ctrl+C in this window to stop the server anytime.
echo.
python app.py
pause
