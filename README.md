# 🎯 Sarkari Result Qualification-Based Job Alert App

An automated, 100% free, multi-platform system that continuously monitors **Sarkari Result**, parses post eligibility details, matches them against your educational qualifications (B.Ed, CTET, STET, Graduate, 10th, 12th, MCA, BCA, B.Tech, etc.), and immediately sends push alerts to your phone lockscreen and browser.

---

## 🌟 Key Features

- **⚡ Incremental Caching & Token-Saver Engine**:
  - Automatically caches seen jobs in SQLite and `data/jobs.json`.
  - Never re-scrapes old posts, saving network requests and compute tokens.
  - When you change qualifications in the UI, it re-matches in-memory in ~0.1 seconds with **zero** internet requests!
- **📱 Instant Mobile Lockscreen Push (Zero-Login / Zero Play Store)**:
  - Powered by `ntfy.sh` — 100% free, open-source push notification service.
  - Receive vibration & sound alerts with direct click-to-apply links on your phone.
- **🚀 100% Free Cloud Deployment Ready**:
  - Deploy effortlessly to **Vercel** or **Netlify**.
  - Background scraper automated 24/7 via **GitHub Actions** cron (runs every 2 hours free).
- **🔍 Google Search Console & SEO Ready**:
  - Includes `sitemap.xml`, `robots.txt`, OpenGraph tags, and Schema.org (`JobPosting` & `WebSite` JSON-LD) structured data.
- **📱 Standalone Android APK**:
  - Includes PWA manifest & Capacitor configuration to build a native `.apk` file for direct installation on Android phones.

---

## 🚀 Quick Start (Local PC)

### 1. Launch with One Click
Double-click `run.bat` (or open terminal and run):
```bash
pip install -r requirements.txt
python app.py
```
Open **`http://localhost:5000`** in your browser.

---

## 📤 Step-by-Step: Deploy to GitHub & Vercel / Netlify

### Step 1: Push to GitHub
1. Open PowerShell in this project folder:
   ```bash
   git init
   git add .
   git commit -m "Initial commit of Sarkari Result Job Alert App"
   git branch -M main
   ```
2. Create a new repository on [GitHub](https://github.com/new).
3. Connect and push:
   ```bash
   git remote add origin https://github.com/<your-username>/<your-repo-name>.git
   git push -u origin main
   ```

### Step 2: Deploy to Vercel (1-Click & 100% Free)
1. Go to [vercel.com](https://vercel.com) and log in with your GitHub account.
2. Click **Add New Project** -> Select your repository.
3. Keep default settings (Vercel automatically detects `vercel.json`).
4. Click **Deploy**. Your app is now live with a free `https://your-project.vercel.app` domain!

### Step 3: Enable 24/7 GitHub Actions Scraper
- In your GitHub repo, go to the **Actions** tab.
- The `.github/workflows/scraper-cron.yml` is already configured to run every 2 hours automatically.
- You can also click **Run workflow** to test it anytime manually.

---

## 📱 How to Get Mobile Lockscreen Alerts on Your Phone

1. Install the free **ntfy** app on your phone:
   - [ntfy on Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
   - Or open `https://ntfy.sh/sarkari_job_alert_user` directly in your phone browser.
2. In the app, tap **+ (Subscribe to topic)** and enter your secret topic name (default: `sarkari_job_alert_user`).
3. That's it! Whenever a matching job is posted, your phone will ring and show the notification on your lock screen with a direct link to apply.

---

## 🔍 How to Connect Google Search Console

1. Open [Google Search Console](https://search.google.com/search-console).
2. Click **Add Property** and enter your live URL (e.g., `https://your-app.vercel.app`).
3. Verify ownership (via HTML tag or DNS).
4. In the left menu, click **Sitemaps**, enter `sitemap.xml`, and click **Submit**.
5. Google will now index your web app and qualification job feeds directly in Google Search results.

---

## 📦 How to Build the Android APK

### Option A: 1-Minute Fast Online APK (Recommended)
1. Open [PWABuilder.com](https://www.pwabuilder.com/).
2. Enter your live Vercel/Netlify URL.
3. Click **Package For Stores** -> Select **Android** -> Click **Download APK Package**.
4. Transfer the `.apk` to your phone and install!

### Option B: Local Build via Capacitor
Run `build-apk.bat` in this folder and choose **Option 2**. It will generate the Android Studio project with `npx cap add android` and build the debug APK.

---

## 📂 Project Structure

```
sarkari-job-alert-app/
├── .github/workflows/
│   └── scraper-cron.yml      # Free 24/7 automated scraping cron
├── api/
│   └── index.py              # Vercel serverless entry point
├── data/
│   ├── jobs.json             # Persistent jobs cache (token saver)
│   ├── settings.json         # User qualification preferences
│   └── default_settings.json # Defaults
├── static/
│   ├── index.html            # Responsive UI + SEO Schema.org tags
│   ├── style.css             # Sleek modern layout
│   ├── app.js                # Frontend reactive state & audio chime
│   ├── sw.js                 # PWA Service worker
│   ├── manifest.json         # PWA Android install manifest
│   ├── sitemap.xml           # Google Search Console sitemap
│   ├── robots.txt            # Search crawler directives
│   └── icons/                # High-res PWA & APK icons
├── scraper.py                # Regex qualification extractor
├── notifier.py               # Dispatcher for ntfy.sh, browser, telegram
├── database.py               # SQLite & JSON sync manager
├── app.py                    # Flask server
├── build-apk.bat             # Android APK build script
├── run.bat                   # 1-click Windows runner
├── vercel.json               # Vercel configuration
├── netlify.toml              # Netlify configuration
└── requirements.txt          # Python dependencies
```
