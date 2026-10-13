# Firebase Login Setup (Fruitectives 2.0)

The app code is already wired for Firebase Email/Password login.
You only need to do these steps once in the Firebase website.

## 1. Create the Firebase project
1. Go to https://console.firebase.google.com and sign in with your Google account.
2. Click **Create a project** → name it `Fruitectives` → you can turn Google Analytics off → **Create**.

## 2. Add the Android app
1. In the project, click the **Android** icon ("Add app").
2. **Android package name:** `com.example.andriodfruitectivesv2`  (must match exactly — note the spelling "andriod")
3. App nickname: `Fruitectives` (optional) → **Register app**.
4. Download **google-services.json** and put it here:
   `andriodFruitectivesv2/android/app/google-services.json`
5. Skip the remaining "Add Firebase SDK" steps — they are already done in the code.

## 3. Turn on Email/Password login
1. Left menu → **Build → Authentication → Get started**.
2. **Sign-in method** tab → **Email/Password** → Enable → **Save**.

## 4. Create the group account
1. Authentication → **Users** tab → **Add user**.
2. Email: `bryanpaul@gmail.com`
3. Password: (the group password)
4. **Add user**.

(You can also create accounts from inside the app with "Create Account".)

## 5. Run the app
In the project folder:
```
flutter clean
flutter pub get
flutter run
```
Log in with the account from step 4. Wrong password → the app shows "Incorrect email or password."

## What changed in the code
- `pubspec.yaml`: added `firebase_core` and `firebase_auth`.
- `android/settings.gradle.kts` + `android/app/build.gradle.kts`: added the Google Services plugin; minSdk raised to 23 (Firebase requirement).
- `lib/main.dart`:
  - Fixed a typo on line 1 (`climport` → `import`) that stopped the app from compiling.
  - Firebase starts up in `main()`.
  - **Log In** now checks email + password with Firebase.
  - **Create Account** now creates a real Firebase user.
  - **Profile** shows the signed-in email; **Log Out** signs out of Firebase.
  - If already logged in, the app opens straight to the Dashboard.
  - "Continue as Guest" still works without an account.
