# Port Operations App - Android Distribution Guide

## 📱 Built APK Files

The following Android app files have been successfully built:

### For Direct Installation (Sideloading)
- **File**: `frontend/build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 91 MB
- **Type**: Release APK (optimized for performance)
- **Signing**: Debug signed (for testing/internal distribution)

### For Google Play Store
- **File**: `frontend/build/app/outputs/bundle/release/app-release.aab`
- **Size**: 44 MB  
- **Type**: Android App Bundle
- **Signing**: Debug signed (needs proper signing for Play Store)

## 🚀 How to Share with Users

### Method 1: Direct APK Installation

1. **Share the APK file**:
   ```bash
   # The APK is located at:
   frontend/build/app/outputs/flutter-apk/app-release.apk
   ```

2. **User Installation Steps**:
   - Enable "Unknown Sources" or "Install from Unknown Sources" in Android settings
   - Download the APK file to their device
   - Tap the APK file to install
   - Follow the installation prompts

### Method 2: Upload to File Sharing Service

1. **Upload APK to cloud storage**:
   - Google Drive
   - Dropbox  
   - WeTransfer
   - Any file sharing service

2. **Share the download link** with users

### Method 3: Internal Distribution Platforms

1. **Firebase App Distribution**:
   - Upload APK to Firebase console
   - Invite testers via email
   - Users get installation links

2. **Google Play Console (Internal Testing)**:
   - Upload the AAB file
   - Create internal testing track
   - Invite testers

## ⚠️ Important Notes

### For Users Installing the APK:

1. **Security Warning**: Users may see a warning about installing from unknown sources - this is normal for APKs not from Play Store

2. **Enable Unknown Sources**:
   - Go to Settings > Security > Unknown Sources (Android 7 and below)
   - Go to Settings > Apps > Special Access > Install Unknown Apps (Android 8+)

3. **App Permissions**: The app will request necessary permissions during first launch

### App Details:
- **Package Name**: `com.portops.port_operations_app`
- **Version**: As defined in `pubspec.yaml`
- **Minimum Android Version**: Android 7.0 (API level 24)
- **Target Android Version**: Latest available

## 🔧 For Developers

### To Rebuild the APK:

```bash
# Navigate to frontend directory
cd frontend/

# Clean previous builds
flutter clean

# Get dependencies  
flutter pub get

# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release
```

### To Create Proper Production Signing:

1. **Generate release keystore**:
   ```bash
   keytool -genkey -v -keystore android/app/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release-key
   ```

2. **Update `android/key.properties`**:
   ```
   storePassword=your_store_password
   keyPassword=your_key_password  
   keyAlias=release-key
   storeFile=app/release-key.jks
   ```

3. **Update `android/app/build.gradle.kts`** to use release signing

## 📞 Support

For installation issues or app problems, users can contact:
- **Email**: admin@globalseatrans.com
- **App Issues**: Check the app logs or contact support

---

**Last Updated**: September 29, 2025
**Built With**: Flutter 3.29.3 