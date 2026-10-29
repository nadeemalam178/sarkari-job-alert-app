# 🏛️ Sarkari Job Alert Mobile App (v2.1.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/nadeemalam178/sarkari-job-alert-app?color=blue&logo=github)](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/latest)

An ultra-fast, cross-platform Flutter application and Python automation suite for Indian government job aspirants. Continuously scrapes and parses recruitment notices from **SarkariResult**, **FreeJobAlert**, and **RojgarResult**, filters out non-job clutter (admit cards, answer keys, results), and maps vacancies to candidates using an intelligent qualification hierarchy engine.

---

## ✨ Key Features (v2.1.0)

### 💎 Tactile Glassmorphism & Aubergine-Slate Theme
- **Deep 6-Tone Palette**: Custom dark/light surfaces calibrated to deep aubergine-slate tones (`#17151C`, `#292531`, `#45404F`, `#716879`, `#AAA2B3`, `#E2DDE7`).
- **Dynamic Full-Screen Immersive Scroll**: As you scroll down through job listings, the top navigation header smoothly collapses UP and the bottom dock slides DOWN (`Curves.easeInOutCubic`), expanding the feed to 100% full-screen. Scrolling up instantly restores navigation.
- **Glassmorphic Cards**: Frosted acrylic containers with ambient glow borders, high-contrast badges, and tactile haptic feedback.
- **3D Sovereign Superellipse Icon**: Premium Apple/Google-grade 3D metallic golden bell emblem with Ashoka crest and specular glass reflections.

### 🌐 Universal Explore Job Pool & Non-Blocking Instant Sync
- **Unfiltered Multi-Portal Aggregator**: The **Explore** tab now displays all active postings across SarkariResult, FreeJobAlert, and RojgarResult without qualification restrictions, with automated cross-portal deduplication favoring verified SarkariResult posts.
- **Pull-To-Refresh Synchronization**: Replaced clumsy sync buttons with native smooth pull-to-refresh (`RefreshIndicator`) on both Home and Explore tabs with animated feedback.
- **Instant 0ms Cache Startup**: Cached listings render synchronously on cold launch, with automated non-blocking background sync keeping listings up to date.

### 🚀 Over-The-Air (OTA) Updates & Compact Architecture APKs
- **OTA Update Engine**: Built-in GitHub Releases integration (`OtaUpdateService`) checks for new releases directly from the Profile screen and enables seamless one-tap updates.
- **Compact Split-per-ABI APKs**: Download sizes reduced by up to **65%** (~15–18 MB vs ~51 MB universal) targeting specific device architectures (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

### 🔒 Clean Production Authentication & Native Notifications
- **Production-Ready Security**: Zero dummy accounts, test emails, or pre-filled credentials. Authentic registration and sign-in flow connected to SQLite backend with password hashing.
- **Native Android Notification Permission**: Automatic runtime permission request on modern Android devices (`POST_NOTIFICATIONS`) via Android 13+ native MethodChannel.

---

## 📥 Download Standalone Android APKs (v2.1.0)

Direct download links from [GitHub Releases v2.1.0](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/tag/v2.1.0):

| Architecture | APK File | Size | Recommended Devices |
|---|---|---|---|
| **ARM64-v8a** (Most Popular) | [Download ARM64 APK](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/download/v2.1.0/SarkariJobAlert-v2.1.0-arm64-v8a.apk) | **~18.0 MB** | Modern 64-bit phones (Pixel, OnePlus, Samsung, Xiaomi, Realme, etc.) |
| **ARMv7a** (Legacy 32-bit) | [Download ARMv7a APK](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/download/v2.1.0/SarkariJobAlert-v2.1.0-armeabi-v7a.apk) | **~15.5 MB** | Older 32-bit Android smartphones |
| **x86_64** (Emulators) | [Download x86_64 APK](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/download/v2.1.0/SarkariJobAlert-v2.1.0-x86_64.apk) | **~19.4 MB** | Android Emulators, Windows Subsystem for Android, Chromebooks |
| **Universal** (All CPUs) | [Download Universal APK](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/download/v2.1.0/SarkariJobAlert-v2.1.0-universal.apk) | ~51.1 MB | Compatible with all Android devices |

### Installation Instructions
1. Download the architecture APK for your device (or Universal if unsure).
2. Tap the downloaded `.apk` file and select **Install** (allow *Install unknown apps* if prompted).
3. Register your aspirant account and begin receiving personalized Sarkari job alerts!

---

## 🛠️ Local Development & Build

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13 or higher)
- [Android SDK / Android Studio](https://developer.android.com/studio)
- Python 3.10+ (for backend scraper and API)

### 1. Run the Mobile App (Flutter)
```bash
cd mobile_flutter
flutter pub get
flutter run
```

### 2. Compile Release APKs
```bash
cd mobile_flutter

# Compile compact architecture-specific APKs (~15–18 MB each):
flutter build apk --release --split-per-abi

# Or compile universal APK (~51 MB):
flutter build apk --release
```
Binaries will be placed in `mobile_flutter/build/app/outputs/flutter-apk/`.

### 3. Run Backend Scraper & Web Server (Optional)
```bash
pip install -r requirements.txt
python app.py
```
Open `http://localhost:5000` to view the companion web dashboard.

---

## 📂 Project Architecture

```
sarkari-job-alert-app/
├── mobile_flutter/                  # Flutter Native Mobile App
│   ├── android/                     # Android Gradle setup & native Notification channel
│   ├── assets/icon/                 # High-resolution 3D app icons
│   ├── lib/
│   │   ├── models/                  # JobPost & Qualification data models
│   │   ├── screens/
│   │   │   ├── auth_screen.dart     # Candidate sign-in & registration (clean authentication)
│   │   │   ├── main_dashboard_screen.dart # Home & Explore tabs with scroll-collapse bars
│   │   │   ├── profile_screen.dart  # Stream selector, OTA update checker & theme toggles
│   │   │   └── splash_screen.dart   # Branded 3D opening animation
│   │   ├── services/
│   │   │   ├── api_service.dart     # Backend REST communications
│   │   │   ├── storage_service.dart # Local SharedPreferences storage & cache
│   │   │   ├── notification_service.dart # Runtime POST_NOTIFICATIONS permission
│   │   │   └── ota_update_service.dart   # Over-the-air update manager via GitHub API
│   │   ├── theme/                   # Glassmorphism design & aubergine-slate palette
│   │   ├── utils/                   # Hierarchical qualification matching logic
│   │   └── widgets/                 # Tactile cards, docks, sheets, filters
│   └── pubspec.yaml                 # v2.1.0 dependencies & assets
├── static/                          # Companion Web Dashboard (PWA)
├── scraper.py                       # Multi-portal scraper with date/fee/link extraction
├── database.py                      # SQLite storage & user preferences engine
├── app.py                           # Flask REST API server
└── README.md
```

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).
