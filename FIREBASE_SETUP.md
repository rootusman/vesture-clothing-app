# Firebase Setup Instructions

## Prerequisites
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create a Firestore database

## Installation Steps

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase
Run the following command in your project root:
```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `firebase_options.dart` file
- Configure Firebase for Android/iOS/Web

### 3. Enable Email/Password Authentication
1. Go to Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

### 4. Create Firestore Database
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location for your database

### 5. Set Firestore Security Rules (Optional)
For production, update Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Testing the Authentication

1. **Run the app:**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test Sign Up:**
   - Go to Profile tab
   - Tap "Sign Up"
   - Choose "Sign Up as Regular User" or "Sign Up as Store Owner"
   - Fill in the form and create an account

3. **Test Login:**
   - Go to Profile tab
   - Tap "Login"
   - Enter your credentials

## User Data Structure

### Regular User
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "role": "regular_user",
  "createdAt": "timestamp"
}
```

### Store Owner
```json
{
  "ownerName": "Jane Smith",
  "storeName": "My Store",
  "email": "jane@example.com",
  "role": "store_owner",
  "createdAt": "timestamp"
}
```

## Troubleshooting

### Firebase not initialized error
- Make sure you've run `flutterfire configure`
- Check that `firebase_options.dart` exists in `lib/`
- Verify Firebase project credentials

### Authentication errors
- Check that Email/Password is enabled in Firebase Console
- Verify email format is correct
- Ensure password is at least 6 characters

### Firestore errors
- Verify Firestore database is created
- Check Firestore rules allow writes
- Ensure network connection is available

