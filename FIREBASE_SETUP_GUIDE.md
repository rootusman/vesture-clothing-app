# Firebase Manual Setup Guide

Since Firebase authentication requires browser interaction, please follow these steps to complete the setup:

## Step 1: Authenticate with Firebase CLI

Open your terminal in the project directory and run:

```bash
firebase login
```

This will open a browser window. Sign in with the Google account that has access to your "vesture" Firebase project.

## Step 2: Configure FlutterFire

After successful login, run:

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

When prompted:
1. Select your existing **"vesture"** project from the list
2. Select the platforms you want to support (Android, iOS, Web, Windows)
3. The CLI will generate `lib/firebase_options.dart` and update platform-specific files

## Step 3: Verify Generated Files

After configuration, you should see:
- `lib/firebase_options.dart` - Contains your Firebase configuration
- Updated `android/app/build.gradle` (if Android selected)
- Updated `ios/Runner/GoogleService-Info.plist` (if iOS selected)

## Step 4: Enable Firebase Services in Console

Go to [Firebase Console](https://console.firebase.google.com/) and enable:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password" provider

2. **Cloud Firestore**
   - Go to Firestore Database → Create database
   - Start in **test mode** for development (you can secure it later)
   - Choose a location close to your users

3. **Storage** (for product images)
   - Go to Storage → Get started
   - Start in **test mode** for development

## Next Steps

Once you've completed these steps, let me know and I'll proceed with:
- Initializing Firebase in `main.dart`
- Refactoring `AuthService` to use Firebase Auth
- Refactoring `ProductRepository` to use Cloud Firestore
- Updating Cart and Favorites services

---

**Note**: The dependencies are already added to `pubspec.yaml` and installed.
