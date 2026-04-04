# Firebase Configuration Files

## Important Notice

This directory should contain the `google-services.json` file for Firebase integration.

## Setup Instructions

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" or select existing project
3. Enter project name (e.g., "SmartPOS")

### Step 2: Register Android App
1. In Firebase Console, click on "Add App" → Android icon
2. Enter the following details:
   - **Package name**: `com.gulfamali.smartpos` (must match applicationId in build.gradle.kts)
   - **App nickname**: Smart POS (optional)
   - **Debug signing certificate SHA-1**: (optional, needed for Google Sign In)

### Step 3: Download Configuration File
1. Download the `google-services.json` file
2. Place it in this directory: `SmartPOS/android/app/google-services.json`

### Step 4: Enable Firebase Services
In Firebase Console, enable the following services:

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Enable "Google" (optional, for Google Sign In)

#### Cloud Firestore
1. Go to Firestore Database
2. Click "Create Database"
3. Start in **test mode** (for development)
4. Choose your preferred location

### Step 5: Security Rules (Production)
For production, update Firestore security rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Add role-based access control
    }
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Important Notes

- **DO NOT** commit `google-services.json` to version control (it's in .gitignore)
- Each team member needs to download their own copy from Firebase Console
- For iOS, you'll also need `GoogleService-Info.plist` in `ios/Runner/`

## Troubleshooting

### Common Issues

1. **"Default FirebaseApp is not initialized"**
   - Solution: Ensure `google-services.json` is in the correct location
   - Rebuild the app after adding the file

2. **Google Sign In not working**
   - Solution: Add SHA-1 certificate fingerprint to Firebase Console
   - Get SHA-1: `./gradlew signingReport` (in android directory)

3. **Build errors**
   - Solution: Run `flutter clean` and `flutter pub get`
   - Check that all Firebase dependencies are up to date

## Testing Without Firebase

The app is designed to handle Firebase initialization failures gracefully. If you want to test without Firebase:

1. The app will print a debug message but continue to run
2. Authentication features will not work
3. Local SQLite database will still function

## Next Steps

After adding `google-services.json`:
1. Run `flutter pub get`
2. Run `flutter clean`
3. Run `flutter run`
4. Test authentication features

For more information, see the [Firebase Flutter Setup Guide](https://firebase.google.com/docs/flutter/setup).
