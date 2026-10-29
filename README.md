# 🏛️ Sarkari Job Alert Mobile App (v2.0.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/nadeemalam178/sarkari-job-alert-app?color=blue&logo=github)](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/latest)

An ultra-fast, cross-platform Flutter application and Python automation suite for Indian government job aspirants. Continuously scrapes and parses recruitment notices from **SarkariResult**, **FreeJobAlert**, and **RojgarResult**, filters out non-job clutter (admit cards, answer keys, results), and maps vacancies to candidates using an intelligent qualification hierarchy engine.

---

## ✨ Key Features

### 💎 Tactile Glassmorphism Design
- **Adaptive Theme System**: True dynamic switching between **Dark**, **Light**, and **System Auto** modes.
- **Glassmorphic Cards**: Frosted acrylic containers with ambient glow borders, high contrast badges, and tactile haptic feedback.
- **3D Sovereign Superellipse Icon**: Premium Apple/Google-grade 3D metallic golden bell emblem with Ashoka crest and specular glass reflections.
- **Fluid Opening Transitions**: Seamless branded splash screen with `TactileFadeSlide` cubic easing transitions.

### 🎓 Smart Qualification Matcher (RRB NTPC & Graduate Support)
- **Hierarchical Stream Matching**: Candidates with specific degrees (e.g. `B.SC`, `B.TECH`, `B.COM`) automatically qualify for general `GRADUATE` posts, including:
  - **RRB NTPC Graduate Vacancies** (Station Master, Goods Train Manager, Senior Clerk)
  - **SSC CGL & CHSL Openings**
  - **UPSC & State PSC Recruitments**
  - Downward eligibility for general 12th/10th posts without manual reconfiguration.
- **Custom Qualification Management**: Update qualifications in real time from the Profile screen to recalculate matched vacancies on the fly.

### 📋 Detailed Vacancy Intelligence
Each job card opens an interactive detail container showing:
- 📅 **Important Dates**: Application begin date and last date of submission.
- 👥 **Total Vacancies**: Total post counts extracted from official tables.
- 💰 **Application Fee & Age Limits**: Category-wise fee breakdown and age bracket rules.
- 🔗 **Action Links**: Direct **Apply Online**, **Download Notification (PDF)**, and **Official Website** buttons.

### 🧭 Intuitive Tab Navigation
- **Home Tab**: Candidate command center featuring urgent deadline alerts, stream-matched recommendations, and quick sector pills (Railways, SSC, Banking, Defense, State PSC).
- **Explore Tab**: Real-time recruitment search engine with instant query matching, portal filtering chips (`SarkariResult ★`, `FreeJobAlert`, `RojgarResult`), and complete directory access.
- **Center Sync Dock**: Single, deduplicated live vacancy sync action at the center of the bottom dock.
- **Profile Tab**: Candidate credentials, qualification stream selector, system theme toggles, and notification settings.

---

## 📥 Download Standalone Android APK

Get the pre-compiled Android release APK directly from our GitHub Releases:

👉 **[Download Latest APK (v2.0.0)](https://github.com/nadeemalam178/sarkari-job-alert-app/releases/latest)**

1. Download `SarkariJobAlert-v2.0.0.apk` to your Android device.
2. Open the file and tap **Install** (allow installation from browser if prompted).
3. Open the app to access instant Sarkari job alerts!

---

## 📱 Candidate Demo Login

The application comes pre-configured with a quick-fill demo candidate profile:

| Field | Demo Credential |
|---|---|
| **Candidate Email** | `nadeem.aspirant@sarkarialert.in` |
| **Password** | `Sarkari@2026` |
| **Mobile Number** | `+91 98765 43210` |
| **Highest Degree** | `B.SC (Bachelor of Science)` |

> **Tip**: Tap **1-Tap Auto Fill Demo** or **Google Sign-In** on the welcome screen to instantly log in.

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

### 2. Compile Release APK
```bash
cd mobile_flutter
flutter build apk --release
```
The optimized release APK will be located at:
`mobile_flutter/build/app/outputs/flutter-apk/app-release.apk`

### 3. Run Backend Scraper & Web Server (Optional)
```bash
# Install dependencies
pip install -r requirements.txt

# Start backend server
python app.py
```
Open `http://localhost:5000` to view the companion web dashboard.

---

## 📂 Project Architecture

```
sarkari-job-alert-app/
├── mobile_flutter/                  # Complete Flutter Native Mobile App
│   ├── android/                     # Android Gradle setup & permissions
│   ├── assets/icon/                 # High-resolution 3D app icons
│   ├── lib/
│   │   ├── models/                  # JobPost & Qualification data models
│   │   ├── screens/
│   │   │   ├── auth_screen.dart     # Candidate onboarding & Google auto-fill
│   │   │   ├── main_dashboard_screen.dart # Home & Explore tabs
│   │   │   ├── profile_screen.dart  # Stream selector & theme manager
│   │   │   └── splash_screen.dart   # Branded 3D opening animation
│   │   ├── services/                # API and local SharedPreferences storage
│   │   ├── theme/                   # Glassmorphism design & color palette
│   │   ├── utils/                   # Hierarchical qualification matching logic
│   │   └── widgets/                 # Tactile cards, docks, sheets, filters
│   └── pubspec.yaml                 # Dependencies & asset configuration
├── static/                          # Companion Web Dashboard (PWA)
├── scraper.py                       # Multi-portal scraper with date/fee/link extraction
├── database.py                      # SQLite storage & user preferences engine
├── app.py                           # Flask REST API server
└── README.md
```

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).
