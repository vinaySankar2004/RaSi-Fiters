# Mobile API — Login (iOS-first, Android-ready)

Scope: mobile clients only; no behavior or payload changes for existing web/legacy routes. This documents the canonical mobile login contract so iOS now (and Android later) can share a predictable endpoint with minimal client-side shaping.

## Naming and routing
- Canonical mobile/app route: `POST /auth/login/app` (verb is acceptable here because it is an action).
- Alias kept for continuity: `/auth/login/global` (same handler).
- Legacy compatibility: keep existing `/login` untouched for web/older clients.
- No versioning in path (per team guidance).
- Use nouns for resources elsewhere (e.g., `/users`, `/workouts`); reserve verbs for actions like `login`, `logout`, `reset_password`.

## Request (mobile)
```json
{
  "username": "string",
  "password": "string",
  "device_id": "string optional",   // if you want to bind a device to the session/notifications
  "push_token": "string optional"   // optional push registration token
}
```

## Success response (mobile)
```json
{
  "access_token": "jwt-string",     // same as existing `token`
  "refresh_token": "opaque-string",
  "user": {
    "id": "number",
    "username": "string",
    "member_name": "string",
    "global_role": "string",        // defaults to `standard` if unset
    "date_joined": "YYYY-MM-DD"
  },
  "message": "Login successful"
}
```
- Access token TTL remains 1 hour; refresh tokens keep sessions alive until logout.
- Refresh token TTL is configurable (see `REFRESH_TOKEN_TTL_DAYS`); unset means no expiry.
- Keep payload flat and ready to consume; client should only store token + refresh_token + user.

## Error responses (mobile)
- `401` — `{"error": "Invalid credentials"}`
- `500` — `{"error": "Server error during login"}`

## Refresh (mobile)
- `POST /auth/refresh`
- Request: `{ "refresh_token": "opaque-string" }`
- Response: `{ "token": "jwt-string", "refresh_token": "opaque-string", "message": "Token refreshed" }`
- Behavior: rotates refresh token on each use; revoked/expired tokens return `401`.

## Logout (mobile)
- `POST /auth/logout`
- Request: `{ "refresh_token": "opaque-string" }`
- Response: `{ "message": "Logged out" }`

## Responsibilities split
- Server: validate credentials, shape the user object above, issue JWT, return full payload; handle logging (`[global login]` logs remain).
- Client: send credentials (plus optional device/push fields), store `access_token` and `user`, no extra transformation.

## Analytics hook
- Single endpoint: `POST /analytics/event`
- Event types for login flow: `login_success`, `login_failed`, optionally `app_opened` before login.
- Recommended payload: `{"type": "login_success", "screen": "login", "username": "...", "device_id": "...", "context": {"platform": "ios"}}`

## Migration notes
- iOS should call `POST /auth/login/app`; Android can reuse the same contract later.
- `/auth/login/global` remains available if a caller is already using it.
- `/login` stays intact for existing clients; no UI/behavior changes.
- The app routes reuse the existing global login logic to avoid functional drift.
