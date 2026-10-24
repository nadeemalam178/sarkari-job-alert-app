# 📱 Sarkari Job Alert - Expo Mobile App

Run and debug the Sarkari Job Alert App live on your physical Android or iPhone device via **Expo Go** with zero Android Studio setup required.

---

## 🚀 How to Debug on Your Phone (in 60 seconds)

### Step 1: Install Expo Go on your Phone
- **Android**: [Download Expo Go on Google Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)
- **iOS**: [Download Expo Go on Apple App Store](https://apps.apple.com/app/expo-go/id982107779)

### Step 2: Start the Python Backend Server
Double-click `run.bat` in the root folder so the backend API is live on your local network (e.g. `http://192.168.1.11:5000`).

### Step 3: Start the Expo Development Server
Double-click `start-expo.bat` (or run in terminal):
```bash
cd expo-mobile
npx expo start
```
A large interactive **QR Code** will appear in the terminal window!

### Step 4: Scan and Test on Phone
1. Connect your phone to the **same Wi-Fi network** as your laptop.
2. Open the **Expo Go** app on your phone.
3. Tap **Scan QR code** and point your camera at the QR code in the terminal.
4. The app will bundle and open directly on your phone!
5. Any changes you make will live-reload instantly on your phone screen!

---

## 📦 How to Build Standalone Android APK via EAS (Cloud Build)

If you want a signed standalone `.apk` file compiled in the cloud:
1. Install EAS CLI:
   ```bash
   npm install -g eas-cli
   ```
2. Log in to your free Expo account:
   ```bash
   eas login
   ```
3. Build the APK:
   ```bash
   eas build -p android --profile preview
   ```
4. Expo's cloud builders will compile the `.apk` and give you a direct download link!
