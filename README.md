# 🎯 Sarkari Result Qualification-Based Job Alert App

An automated, multi-platform system that continuously monitors **Sarkari Result**, **FreeJobAlert**, and **RojgarResult**, filters out non-job noise (results, admit cards), matches posts against your specific qualifications (B.Ed, CTET, STET, Graduate, 10th, 12th, MCA, BCA, B.Tech, etc.), and immediately delivers alerts to your phone lockscreen and browser.

---

## 🌟 Key Features

- **📱 Mobile App Layout (Bottom Dock & Slide-Out Side Panel)**:
  - **Floating Dock Navigation**: Modern iOS/Android style bottom dock bar for quick thumb access to For You, All Jobs, Education, and Alerts.
  - **Slide-Out Side Panel (Drawer)**: Clean slide-in menu with candidate profile, portal filter chips (SarkariResult ★, FreeJobAlert, RojgarResult), and Wi-Fi phone link.
- **⚡ Live Phone Debugging with Expo (`expo-mobile/`)**:
  - Run `start-expo.bat` and scan the QR code with **Expo Go** on your physical Android or iPhone.
  - Instant live debugging and fast-reload directly on your phone!
  - In-app server IP switcher to connect to your computer on any Wi-Fi.
- **🎓 Smart Qualification Matcher (50+ Indian Govt Job Degrees)**:
  - Highest qualification selector + live autosuggest search for specific degrees.
  - Automatic downward eligibility (Graduates automatically match general 12th/10th openings).
- **🚫 Strict Non-Job Exclusion**:
  - Excludes admit cards, results, scorecards, allotments, scholarships, and syllabi.
  - **100% active recruitment vacancies only**.
- **🥇 Sarkari Result Priority & Cross-Portal Deduplication**:
  - Normalized deduplication across portals, always prioritizing Sarkari Result links with `SarkariResult ★` badge.
- **🔔 Phone Lock Screen Push via `ntfy.sh` (100% Free / Zero Play Store)**:
  - Instant push notifications to phone lock screen with vibration and direct apply links.

---

## 🚀 Quick Start (Local PC)

### 1. Start Backend & Web App
Double-click `run.bat` (or run `python app.py`).
Open **`http://localhost:5000`** in your browser.

### 2. Debug Live on Your Phone via Expo Go
1. Install the free **Expo Go** app from Google Play Store or App Store.
2. Ensure phone & PC are on the same Wi-Fi.
3. Double-click `start-expo.bat` in this folder.
4. Scan the QR code in the terminal with Expo Go. The app runs live on your phone!

---

## 📱 How to Get Mobile Lockscreen Alerts on Your Phone

1. Install the free **ntfy** app on your phone:
   - [ntfy on Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
2. In the app, tap **+ (Subscribe to topic)** and enter your topic name (default: `sarkari_job_alert_user`).
3. You will receive real-time push alerts whenever matching jobs are posted.

---

## 📦 How to Build the Standalone Android APK

### Option 1: Expo Cloud Build (EAS Build - Recommended)
Inside `expo-mobile/`:
```bash
npm install -g eas-cli
eas login
eas build -p android --profile preview
```
Expo compiles the `.apk` in the cloud and gives you a direct download link!

### Option 2: 1-Click Fast Online APK (PWABuilder)
Paste your live Vercel/Netlify URL into [PWABuilder.com](https://www.pwabuilder.com/) and download the APK package.

---

## 📂 Project Structure

```
sarkari-job-alert-app/
├── expo-mobile/              # React Native / Expo Mobile App for phone debugging
│   ├── App.js                # Mobile app with WebView, IP switcher & native bridge
│   ├── app.json              # Expo configuration (permissions, icons, theme)
│   ├── package.json          # Expo SDK 52 dependencies
│   └── start.bat             # 1-click Expo runner
├── static/                   # Web PWA Frontend
│   ├── index.html            # Mobile dock bar, slide-out drawer, SEO & schema
│   ├── style.css             # Floating dock, slide-out side panel, glassmorphism
│   ├── app.js                # Reactive state, audio chime & qualification autosuggest
│   ├── sw.js                 # PWA Service worker
│   ├── manifest.json         # PWA Manifest
│   └── sitemap.xml           # Google Search Console sitemap
├── scraper.py                # Multi-portal scraper with Sarkari Result priority
├── database.py               # SQLite & user authentication manager
├── notifier.py               # Phone lockscreen notification dispatcher
├── app.py                    # Flask server
├── start-expo.bat            # 1-click Expo phone runner
├── run.bat                   # 1-click PC runner
└── README.md
```
