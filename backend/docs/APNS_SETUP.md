# APNs (Apple Push Notifications) setup

Follow these steps so the backend can send push notifications to the iOS app.

---

## 1. Enable Push Notifications for your App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/) → **Certificates, Identifiers & Profiles** → **Identifiers**.
2. Open your **App ID** (e.g. `com.app.rasifiters` — must match the iOS app’s bundle ID).
3. Under **Capabilities**, enable **Push Notifications**.
4. Save the identifier.

---

## 2. Create an APNs Authentication Key (.p8)

1. In the same portal go to **Keys** (under “Certificates, Identifiers & Profiles”).
2. Click **+** to create a new key.
3. Give it a name (e.g. “RaSi Fiters APNs”).
4. Enable **Apple Push Notifications service (APNs)**.
5. Continue and **Register** the key.
6. On the confirmation screen:
   - **Download the .p8 file** (you can only download it once; store it safely).
   - Note the **Key ID** (e.g. `A1B2C3D4E5`).
7. Note your **Team ID** (top-right of the portal or in **Membership**).
8. Note your app’s **Bundle ID** (e.g. `com.app.rasifiters`).

---

## 3. Backend environment variables

Add these to your backend `.env` (or your deployment env):

| Variable | Required | Description |
|----------|----------|-------------|
| `APNS_KEY_ID` | Yes | The Key ID from step 2 (e.g. `A1B2C3D4E5`). |
| `APNS_TEAM_ID` | Yes | Your Apple Developer Team ID (10 characters). |
| `APNS_BUNDLE_ID` | Yes | Your app’s bundle ID (e.g. `com.app.rasifiters`). |
| `APNS_KEY_PATH` | Yes* | Full path to the `.p8` file on the server (e.g. `/secrets/APNsAuthKey_XXXXX.p8`). |
| `APNS_KEY` | Yes* | **Alternative to `APNS_KEY_PATH`**: contents of the .p8 file, **base64-encoded** (useful for cloud envs where you can’t mount a file). |
| `APNS_PRODUCTION` | No | Set to `true` to use the production APNs gateway. Omit or `false` for development/sandbox. |

\* Use **either** `APNS_KEY_PATH` **or** `APNS_KEY`, not both.

For **what APNS_PRODUCTION is**, **where to set it**, and **how the whole push flow works**, see [APNS_HOW_IT_WORKS.md](APNS_HOW_IT_WORKS.md).

### Example `.env` (using file path)

```env
APNS_KEY_ID=A1B2C3D4E5
APNS_TEAM_ID=XXXXXXXXXX
APNS_BUNDLE_ID=com.app.rasifiters
APNS_KEY_PATH=/path/to/AuthKey_A1B2C3D4E5.p8
# APNS_PRODUCTION=true   # uncomment for production/TestFlight/App Store
```

### Example using base64 key (e.g. Render, Railway)

1. Base64-encode the .p8 file:
   ```bash
   base64 -i AuthKey_XXXXX.p8 | tr -d '\n' > apns_key_base64.txt
   ```
2. Set in env:
   ```env
   APNS_KEY_ID=A1B2C3D4E5
   APNS_TEAM_ID=XXXXXXXXXX
   APNS_BUNDLE_ID=com.app.rasifiters
   APNS_KEY=<paste the contents of apns_key_base64.txt>
   ```

---

## 4. Development vs production

- **Development (Xcode run, simulator/device with dev build):**  
  Use sandbox APNs → leave `APNS_PRODUCTION` unset or `false`.  
  The iOS app’s entitlements use `aps-environment: development`.

- **Production (TestFlight, App Store):**  
  Use production APNs → set `APNS_PRODUCTION=true`.  
  For release builds, the app should use `aps-environment: production` (Xcode often handles this when you archive).

If the backend has no APNs env configured, push is skipped and the rest of the app still works (SSE and in-app modals are unchanged).

---

## 5. Deploying on Render (no file path)

Render doesn’t give you a persistent filesystem to upload the .p8 file, so **don’t use `APNS_KEY_PATH`** there. Use **`APNS_KEY`** with the key contents as base64.

### Steps for Render

1. **Get the base64 key (one-time, on your Mac):**
   ```bash
   base64 -i /path/to/your/AuthKey_XXXXX.p8 | tr -d '\n'
   ```
   Copy the whole output (one long line).

2. **In Render:** open your **Backend** service → **Environment** tab.

3. **Add (or edit) these variables:**
   - `APNS_KEY_ID` = your Key ID (e.g. `F9C876PZ9K`)
   - `APNS_TEAM_ID` = your Team ID (e.g. `VSTTF2AM22`)
   - `APNS_BUNDLE_ID` = `com.app.rasifiters`
   - **`APNS_KEY`** = paste the base64 string from step 1 (do **not** set `APNS_KEY_PATH` on Render)
   - `APNS_PRODUCTION` = `true` if you’re using production APNs (e.g. TestFlight/App Store); leave unset for sandbox.

4. Save. Render will redeploy; push will use the key from `APNS_KEY`.
