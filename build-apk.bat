@echo off
echo ========================================================
echo       Sarkari Job Alert - Android APK Builder
echo ========================================================
echo.
echo Choose your preferred method to get the Android APK:
echo.
echo [1] 1-Click Fast Online APK (PWABuilder - Recommended)
echo [2] Local Offline APK Build (via Capacitor & Android SDK)
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo --------------------------------------------------------
    echo METHOD 1: Instant 1-Click APK via PWABuilder
    echo --------------------------------------------------------
    echo 1. Once your web app is hosted on Vercel/Netlify (or localhost via ngrok),
    echo    open: https://www.pwabuilder.com
    echo 2. Enter your live website URL (e.g. https://your-app.vercel.app).
    echo 3. Click 'Build My PWA' -> Choose 'Android' -> Click 'Download Package'.
    echo 4. You will get a ready-to-install signed .apk file!
    echo.
    start https://www.pwabuilder.com
    pause
    exit /b
)

if "%choice%"=="2" (
    echo.
    echo --------------------------------------------------------
    echo METHOD 2: Local Capacitor Android Build
    echo --------------------------------------------------------
    echo Checking Node.js and NPM...
    call npm -v >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Node.js is required for Capacitor build.
        pause
        exit /b
    )
    echo Installing Capacitor CLI and Android platform...
    call npm install @capacitor/core @capacitor/cli @capacitor/android --save-dev
    echo Initializing Android project...
    call npx cap add android
    echo Copying static assets to Android build...
    call npx cap sync android
    echo.
    echo Opening Android Studio to generate APK (Build -> Build APKs)...
    call npx cap open android
    echo.
    echo Done! You can now compile the debug APK in Android Studio or via Gradle:
    echo cd android && gradlew assembleDebug
    pause
    exit /b
)
