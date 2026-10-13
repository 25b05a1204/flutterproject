# ConnectUp / Study Buddy — Firebase-enabled source

## What is connected in this version
- Registration stores a user's name/email in Firestore `users`.
- Profile reads the signed-in account and supports editing name, branch, year and Junior/Senior role.
- Ask Doubt saves the original title/description/category to Firestore `doubts` before opening matching.
- Matching lists accounts in Firestore whose `role` is `senior` (no sample senior names).
- Selecting a senior creates a request and an in-app notification document.
- My Doubts reads the current user's posted doubts.
- Chat messages are saved in Firestore and streamed for the selected request.
- The Cloud Function can email a senior when an in-app notification is created, after SMTP is configured.

## Required Firebase setup
1. Open the Firebase project `connectupflutter` that matches the included `google-services.json` / `firebase_options.dart`.
2. In Firebase Console → Authentication → Sign-in method, enable **Email/Password**.
3. Create a **Cloud Firestore** database.
4. Publish the included `firestore.rules` in Firestore → Rules. Review and tighten rules before production use.
5. From the Flutter project root, run:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter run
   ```
6. Register accounts. Set accounts to Senior using the role selection screen or Profile → Edit Profile. A senior appears to juniors only after their Firestore `users/{uid}` document has `role: senior`.

## Email notification setup (optional; requires Firebase Blaze plan for deployed Functions)
The app writes in-app notifications to Firestore. To send actual email, deploy `functions/` as a Firebase Cloud Function and configure SMTP credentials; never put SMTP passwords in Flutter code.

From a terminal with Firebase CLI installed and logged in:
```bash
cd functions
npm install
cd ..
firebase functions:secrets:set SMTP_PASSWORD
```
For `SMTP_PASSWORD`, enter an app password from your email provider (for Gmail, use a Google App Password, not your normal account password). Configure `SMTP_USER` as a Firebase function parameter (and adjust the default SMTP host/port in `functions/index.js` if needed), then run:
```bash
firebase deploy --only functions:emailNewDoubtRequest
```
If your Firebase CLI prompts to initialize the project, choose the existing `connectupflutter` project and enable Firestore/Functions. The current function reads SMTP parameters and sends email to the senior's `users/{uid}.email`. Test with non-sensitive accounts first. Email delivery depends on correct SMTP/provider settings and deployed Cloud Functions.

## Notes / limitations
- This source has not been built on an Android emulator in this environment. Run `flutter analyze` and `flutter run` on your lab machine and share any exact error output for follow-up fixes.
- Firestore may prompt you to create a composite index for a query; follow the Firebase Console link shown in the error.
- The in-app notification list is available from Profile → Notifications. Push notifications to the phone lock screen are not configured in this version; those require Firebase Cloud Messaging and Android notification setup.
- Configure and verify Firestore rules, indexes, email and app behavior before submitting as a final production app.
