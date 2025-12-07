# Store Owner Login Setup Guide

## Step 1: Configure Firebase (One-time setup)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database**
4. Click **Start collection**
5. Collection ID: `admin_config`
6. Click **Next**
7. Document ID: `authorized_admins`
8. Add field:
   - Field name: `emails`
   - Field type: `array`
   - Value: Add your email address (e.g., `admin@example.com`)
9. Click **Save**

## Step 2: Create Store Owner Account

1. Run the app
2. Tap **Sign Up**
3. Select **Store Owner**
4. Fill in the form:
   - Owner Name: Your name
   - Store Name: Your store name
   - Email: **Must match the email you added to Firebase**
   - Password: At least 6 characters
   - Confirm Password
5. Tap **Create Store Owner Account**

## Step 3: Login as Store Owner

1. Open the app
2. Tap **Login**
3. Enter your email and password
4. Tap **Login**
5. You should see an **Admin Panel** icon (⚙️) in the top right

## Troubleshooting

### "This email is not authorized for admin access"
- Make sure you added your email to the `admin_config/authorized_admins/emails` array in Firestore
- Email must match exactly (case-sensitive)
- Wait a few seconds for Firestore to sync

### Can't see Admin Panel icon
- Make sure you signed up as "Store Owner" not "Regular User"
- Try logging out and logging back in
- Check Firestore to verify your user document has `role: "store_owner"`

### Already have an account?
- If you already created an account as a regular user, you'll need to:
  1. Delete that user from Firebase Authentication
  2. Delete the user document from Firestore
  3. Sign up again as Store Owner

## Adding Multiple Store Owners

To add more store owners:
1. Go to Firestore → `admin_config/authorized_admins`
2. Edit the `emails` array
3. Add more email addresses
4. Each person can then sign up using their authorized email
