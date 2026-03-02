# HealthKit App Store Submission Checklist

Complete these steps before submitting to the App Store.

---

## Xcode Project

- [ ] Open **Signing & Capabilities** for the RaSi-Fiters-App target
- [ ] Confirm **HealthKit** capability is present with **Background Delivery** checkbox checked
- [ ] Confirm **Background Modes** capability is present with **Background fetch** checked
- [ ] Ensure the 4 new Swift files are added to the build target:
  - `Shared/Services/HealthKitService.swift`
  - `Shared/Services/HealthKitWorkoutTypeMap.swift`
  - `Shared/Models/ProgramContext+HealthKit.swift`
  - `Features/Home/Settings/AppleHealthSettingsView.swift`

---

## Apple Developer Portal

- [ ] Go to **Certificates, Identifiers & Profiles** > **Identifiers**
- [ ] Select the RaSi Fiters App ID
- [ ] Ensure **HealthKit** capability is enabled
- [ ] Regenerate provisioning profiles if needed

---

## Privacy Policy

Update the privacy policy page at `https://vinaysankar2004.github.io/RaSi-Fiters/` to include:

- [ ] State that the app reads **workout data** (workout type, duration, date) from Apple Health
- [ ] State that this data is sent to the RaSi Fiters backend to automatically log workouts to the user's fitness programs
- [ ] State that health data is **never used for advertising, data mining, or shared with third parties**
- [ ] State that health data is **not stored in iCloud**
- [ ] Describe how users can disconnect Apple Health from the app settings to stop data collection
- [ ] Mention that users can revoke HealthKit access at any time via iOS Settings > Privacy & Security > Health

---

## App Store Connect

### App Privacy (Data Collection)

- [ ] Go to **App Privacy** section in App Store Connect
- [ ] Under **Data Collection**, add **Health & Fitness** data type
- [ ] Mark it as **Linked to User**
- [ ] Set purpose to **App Functionality**
- [ ] Do NOT mark it as used for **Tracking** or **Advertising**

### App Review Notes

- [ ] Add the following review instructions:

```
To test HealthKit integration:
1. Launch the app and sign in
2. Tap the account icon (top right) > Apple Health > Connect to Apple Health
3. Grant HealthKit workout read permission in the system dialog
4. Select a program under "Sync to Programs"
5. Open the Apple Workouts app and record a short workout (or add a workout manually via Health app > Browse > Activity > Workouts > Add Data)
6. Return to RaSi Fiters — the workout will sync automatically, or tap "Sync Now" in Apple Health settings
7. Open the selected program to verify the workout appears in the logs
```

- [ ] Provide a test account with at least one active program

---

## Final Verification (on physical device)

- [ ] Clean install the release build on a physical iPhone
- [ ] Connect to Apple Health and grant permissions
- [ ] Select a program and verify manual sync works
- [ ] Record a workout and verify auto-sync on app foreground
- [ ] Sign out and verify HealthKit settings are cleared
- [ ] Disconnect Apple Health from settings and verify sync stops
- [ ] Verify the privacy policy link in the app opens and mentions health data
