# OAuth Client IDs Configuration Reference

## Current Configuration Status ✅

All three platforms are configured with the correct Google OAuth client IDs.

---

## Platform Configuration

### 1. Web Platform ✅
**Client ID:** `1015708422039-uik2ehutdgj9ophrts6s2ihfgd7i9icc.apps.googleusercontent.com`

**Location:** `lib/services/google_drive_service.dart`
```dart
_googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? '1015708422039-uik2ehutdgj9ophrts6s2ihfgd7i9icc.apps.googleusercontent.com' : null,
  scopes: [drive.DriveApi.driveScope],
);
```

**Required Redirect URIs (Google Cloud Console):**
- `http://localhost:5000/`
- `http://127.0.0.1:5000/`
- `http://localhost:8080/`
- `https://yourdomain.com/` (production)

**Run command:**
```bash
flutter run -d chrome --web-port=5000
```

---

### 2. Android Platform ✅
**Client ID:** `1015708422039-pjodglga18sp3scf0r5kchmnrqdemo5i.apps.googleusercontent.com`

**Location:** `android/app/google-services.json`
```json
{
  "client_id": "1015708422039-pjodglga18sp3scf0r5kchmnrqdemo5i.apps.googleusercontent.com",
  "client_type": 1,
  "android_info": {
    "package_name": "com.example.team_collab",
    "certificate_hash": "1c89b9da920f63687b4c81ddc6269c729e250235"
  }
}
```

**Authenticated with:**
- Package Name: `com.example.team_collab`
- Certificate Hash: `1c89b9da920f63687b4c81ddc6269c729e250235`

**Run command:**
```bash
flutter run -d android
```

---

### 3. iOS Platform ✅
**Client ID:** `1015708422039-kbqvauu17u7jj0ilh375suddvdokl7r1.apps.googleusercontent.com`

**Location:** `ios/Runner/Info.plist`
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.1015708422039-kbqvauu17u7jj0ilh375suddvdokl7r1</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>1015708422039-kbqvauu17u7jj0ilh375suddvdokl7r1.apps.googleusercontent.com</string>
```

**URL Scheme:** `com.googleusercontent.apps.1015708422039-kbqvauu17u7jj0ilh375suddvdokl7r1`

**Run command:**
```bash
flutter run -d ios
```

---

## 📋 Quick Reference

| Component | Auth Method | Client ID | Status |
|-----------|------------|-----------|--------|
| **Web** | OAuth 2.0 Redirect | `...uik2ehutdgj9ophrts6s2ihfgd7i9icc...` | ✅ Configured |
| **Android** | google-services.json | `...pjodglga18sp3scf0r5kchmnrqdemo5i...` | ✅ Configured |
| **iOS** | URL Scheme & GIDClientID | `...kbqvauu17u7jj0ilh375suddvdokl7r1...` | ✅ Configured |

---

## 🔍 Verification Checklist

### Web
- [ ] Run on localhost:5000
- [ ] Redirect URIs match Google Cloud Console
- [ ] Google Drive sign-in works
- [ ] File uploads succeed

### Android
- [ ] Package name matches: `com.example.team_collab`
- [ ] Certificate hash: `1c89b9da920f63687b4c81ddc6269c729e250235`
- [ ] google-services.json properly configured
- [ ] Google Drive sign-in works on device

### iOS
- [ ] URL scheme registered in Info.plist
- [ ] GIDClientID present and correct
- [ ] Google Drive sign-in works on simulator/device
- [ ] Can access Google Drive folders

---

## 🌍 All Platforms Together

```
┌─────────────────────────────────────────────────────┐
│        Google OAuth Configuration (All Platforms)    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Project: bigbys-management                         │
│  Project Number: 1015708422039                      │
│                                                      │
│  ┌─ Web (Port 5000) ──────────────────────────┐    │
│  │ ID: ...uik2ehutdgj9ophrts6s2ihfgd7i9icc...  │    │
│  │ Type: OAuth 2.0 Redirect                    │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌─ Android ──────────────────────────────────┐    │
│  │ ID: ...pjodglga18sp3scf0r5kchmnrqdemo5i... │    │
│  │ Type: Signed APK                            │    │
│  │ Package: com.example.team_collab            │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌─ iOS ──────────────────────────────────────┐    │
│  │ ID: ...kbqvauu17u7jj0ilh375suddvdokl7r1... │    │
│  │ Type: iOS App                               │    │
│  │ URL Scheme: com.googleusercontent.apps...  │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  APIs Enabled: Google Drive API v3 ✅              │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Testing Commands

### Test Web
```bash
# Start web on port 5000
flutter run -d chrome --web-port=5000

# Then try:
# 1. Click "Sign in"
# 2. Verify Google OAuth popup
# 3. Test file upload to Google Drive
```

### Test Android
```bash
# Build and run on Android device/emulator
flutter run -d android

# Then try:
# 1. Sign in with Google
# 2. Test Google Drive access
# 3. Upload test file
```

### Test iOS
```bash
# Build and run on iOS device/simulator
flutter run -d ios

# Then try:
# 1. Sign in with Google
# 2. Test Google Drive access
# 3. Upload test file
```

---

## 📝 If You Need to Change Client IDs

### To Update Web Client ID
```dart
// In lib/services/google_drive_service.dart
_googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? 'YOUR_NEW_WEB_CLIENT_ID' : null,
  scopes: [drive.DriveApi.driveScope],
);
```

### To Update Android Client ID
1. Download new `google-services.json` from Firebase Console
2. Replace `android/app/google-services.json`
3. Update certificate hash if needed

### To Update iOS Client ID
1. Update `ios/Runner/Info.plist`:
   - `GIDClientID` value
   - `CFBundleURLSchemes` array

---

## ✅ Current Setup Status

```
Web:     1015708422039-uik2ehutdgj9ophrts6s2ihfgd7i9icc.apps.googleusercontent.com ✅
Android: 1015708422039-pjodglga18sp3scf0r5kchmnrqdemo5i.apps.googleusercontent.com ✅
iOS:     1015708422039-kbqvauu17u7jj0ilh375suddvdokl7r1.apps.googleusercontent.com ✅

All platforms ready for Google Drive integration! 🚀
```

---

## 🔐 Security Notes

- ✅ These are OAuth 2.0 client IDs (not API keys)
- ✅ Safe to commit to version control
- ✅ Tied to specific package names/bundle identifiers
- ✅ Can only authenticate to your app
- ✅ Server-side secret stored in Google Cloud Console (not in app)

---

## 📚 Related Docs

- [GOOGLE_DRIVE_FILE_ORGANIZATION.md](GOOGLE_DRIVE_FILE_ORGANIZATION.md) - File storage architecture
- [FIREBASE_GOOGLE_DRIVE_SETUP.md](FIREBASE_GOOGLE_DRIVE_SETUP.md) - Initial setup guide
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What was implemented
- [USAGE_GUIDE.md](USAGE_GUIDE.md) - How to use the system

---

**Your OAuth configuration is complete and ready! 🎉**
