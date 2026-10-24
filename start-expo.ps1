Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "          SARKARI JOB ALERT - EXPO MOBILE RUNNER (POWERSHELL)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path "$ScriptDir\expo-mobile"

Write-Host "[1/2] Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules\expo")) {
    Write-Host "Installing Expo & React Native dependencies..." -ForegroundColor Yellow
    npm install
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "  HOW TO DEBUG ON YOUR PHONE:" -ForegroundColor Green
Write-Host "  1. Install 'Expo Go' app from Play Store or App Store" -ForegroundColor Green
Write-Host "  2. Ensure Phone and PC are on the SAME WI-FI" -ForegroundColor Green
Write-Host "  3. Scan the QR code shown below with Expo Go!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Starting Expo Development Server..." -ForegroundColor Cyan

npx expo start --go
