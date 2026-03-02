# APNs: What is APNS_PRODUCTION and how push works

## What is APNS_PRODUCTION and where do I set it?

Apple runs **two separate push gateways**:

- **Sandbox (development):** Used when the app is built and run from Xcode (debug builds, or installs from Xcode to a device). Device tokens from these builds **only work with the sandbox gateway**.
- **Production:** Used when the app is distributed via **TestFlight** or the **App Store**. Device tokens from those builds **only work with the production gateway**.

Your backend has to talk to the **same** gateway as the app that registered the device token. `APNS_PRODUCTION` is the switch that tells the backend which gateway to use.

**Where to set it:**

- **Locally** (backend `.env.local`):  
  - Omit it or set `APNS_PRODUCTION=false` when you’re testing with an app you run from Xcode.  
  - Set `APNS_PRODUCTION=true` only if you’re testing with a TestFlight/App Store build and want push from your local backend.
- **On Render:**  
  - Omit it (or `false`) if your iOS users are only using builds installed from Xcode.  
  - Set `APNS_PRODUCTION=true` when your app is on TestFlight or App Store and you want push to work for those users.

**Rule of thumb:**  

- **Xcode / debug build** → sandbox → **do not set** `APNS_PRODUCTION` (or set it to `false`).  
- **TestFlight / App Store build** → production → set `**APNS_PRODUCTION=true`** on the server that sends push to those users.

---

## How everything works (end-to-end)

### Two ways the app gets notified

1. **In-app (when the app is open)**
  The backend uses **SSE** (Server-Sent Events): the iOS app holds a long-lived connection to `GET /api/notifications/stream`. When something happens (e.g. program updated, role changed), the backend writes a message on that connection. The app receives it immediately and shows the **in-app modal** (the pop-up you already had). No push, no APNs.
2. **Push (when the app is in background or closed)**
  The backend sends a **remote notification** via **APNs**. Apple delivers it to the device and the system shows the banner/sound. The user can tap to open the app. This is what we added.

So: **SSE = in-app modal when app is open.** **APNs = system notification when app is backgrounded or killed.**

### How the app gets a device token (so the backend can push)

1. User opens **My Account → Notifications** and taps **Enable Notifications**.
2. The app calls iOS to **request notification permission** (alert, sound, badge). User allows or denies.
3. If allowed, the app calls **registerForRemoteNotifications()**. iOS talks to APNs and gets a **device token** (a string that identifies this app on this device).
4. iOS calls the app’s **App Delegate** with that token. The app:
  - Saves it in **UserDefaults** (so it can send it on the next login if needed).
  - Posts an in-app notification so the rest of the app can react.
5. If the user is **already logged in**, the app immediately calls **PUT /api/notifications/device** with `{ "push_token": "<device token>" }`. The backend **upserts** that token into **member_push_tokens** (linked to the current user). If the user is **not** logged in yet, the token is sent later **with the next login** (in the body of `POST /api/auth/login/global`). Either way, the backend ends up with at least one row per device in **member_push_tokens**.

### How the backend sends a push

1. Something happens that should notify users (e.g. program updated, member joined, role changed). The existing code calls **createNotification(...)** in `utils/notifications.js` with a list of **recipient member IDs**, **title**, and **body**.
2. **createNotification**:
  - Creates a row in **notifications** and **notification_recipients** (unchanged).
  - **SSE:** For each recipient, it calls **sendNotificationToMember(memberId, payload)**. That writes to any open SSE connection for that member (web or iOS). So in-app users get the modal.
  - **Push:** It then calls **sendPushToMembers(recipientIds, { id, title, body })** in `utils/pushNotifications.js`.
3. **sendPushToMembers**:
  - If APNs isn’t configured (missing env vars or key), it returns and does nothing.
  - It loads all **member_push_tokens** for those **member_id**s where **platform = 'ios'**.
  - For each device token it builds an **APNs payload** (title, body, optional notification_id) and sends it to **Apple’s servers** using your **.p8 key** and **APNS_*** env vars. **APNS_PRODUCTION** chooses **sandbox** vs **production** gateway.
  - If APNs returns “invalid token” or “unregistered”, the backend **deletes** that token from **member_push_tokens** so we don’t keep failing.

### Summary

- **User enables notifications** → app gets device token → backend stores it in **member_push_tokens** (via login body or **PUT /notifications/device**).
- **Event happens** (e.g. program updated) → **createNotification** runs → **SSE** delivers to connected clients (in-app modal) and **APNs** delivers to devices that have a token (system notification when app isn’t in foreground).
- **APNS_PRODUCTION** is only “which Apple gateway do we call?” — sandbox for Xcode builds, production for TestFlight/App Store. Set it in **backend `.env.local`** locally and in **Render → Environment** for the deployed backend.

## Who views it first (web vs iOS)

Acknowledgment is per user. The backend has one notification_recipients row per (notification, member). Whichever client (web or iOS) the user taps OK on first calls the acknowledge API and marks it done for that user. The other client still has it locally until it refetches. Push did not change this.

## Tap push vs in-app modal

When the user taps the push to open the app, the push payload includes notification_id. The app acknowledges that notification by ID (removes from queue and calls the API), so the in-app modal does not show for that notification. When the user is already in the app when the event happens, they get it via SSE and see the in-app modal as before; they tap OK to acknowledge.

