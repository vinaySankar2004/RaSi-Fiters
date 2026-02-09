# Mobile API Map (iOS-first, Android-ready)

Scope: endpoints for the mobile apps only. No functional/UI changes—this documents how to use existing routes (plus the new `/auth/login/app` alias) in a single-intent, server-shaped way so the client does minimal data manipulation.

## Login
- `POST /api/auth/login/app` (alias: `/api/auth/login/global`; legacy `/api/auth/login` untouched)
- Request: `username`, `password`, optional `device_id`, `push_token`
- Response: `token`, `refresh_token`, `user {id, username, member_name, global_role, date_joined}`, `message`

## Post-login bootstrap
- `GET /api/app/bootstrap` (to add; aggregates existing data)
- Returns: `user`, `active_program {id, name, day_index, next_workout}`, `streak {current, best}`, `today {date, workout_name, est_duration}`, `recent_activity` (last few logs), `app_flags` (feature toggles, min_version)
- Server assembles; client renders only.

## Home/dashboard refresh
- `GET /api/app/home` (reuse bootstrap shape or a lightweight variant)
- Returns: `progress {week_sessions, week_minutes, avg_duration, trend_vs_prev}`, `at_a_glance` cards, `announcements`
- Server computes aggregates; client displays.

## Programs
- List: `GET /api/programs?scope=mobile` (filters out web-only)
- Enroll: `POST /api/program-memberships` with `program_id`; response: `active_program` snapshot
- Detail: `GET /api/programs/:id/overview` (mobile view)
- Detail returns: summary, week/day layout, next session info, equipment, coach notes; server flattens schedule.
- Summary (card view): `GET /api/app/programs/summary` (or `GET /api/programs?scope=mobile&include=membership_summary`)
    - Returns array of `program_summary` objects:
    ```json
    {
      "id": "uuid",
      "name": "string",
      "status": "Active|Paused|Archived",
      "state": "upcoming|active|completed",      // derived from dates
      "start_date": "YYYY-MM-DD",
      "end_date": "YYYY-MM-DD",
      "is_user_active": true,
      "member_counts": { "total": 42, "active": 37 },
      "last_activity_at": "YYYY-MM-DD"
    }
    ```
    - Server computes `state`, `member_counts`, `is_user_active`, `last_activity_at`; client renders only.
- Select program: `PUT /api/app/programs/:id/select` (optional) to set active context; returns `program_summary`.
- Create program: `POST /api/programs` (mobile payload) returning `program_summary`.

## Today’s workout / session prep
- `GET /api/workouts/today` (or `/api/programs/:id/workouts/today`)
- Returns: `workout_id`, `title`, ordered `blocks` with movements/reps/sets/tempo, expected duration, tips
- Server orders/resolves; client just shows.

## Workout logs (create/update)
- Create: `POST /api/workout-logs` with `{ workout_id, program_id, date, duration_minutes, perceived_effort, notes }`
- Update: `PATCH /api/workout-logs/:id` for duration/notes adjustments
- Response: saved log with `member_name`, timestamps; server handles member resolution.

## History & recent
- `GET /api/member-history/me?range=last30` (or existing `memberRecent` equivalent)
- Returns: logs with `date`, `workout_name`, `duration`, `program_name`; server sorts/labels.

## Progress metrics
- `GET /api/member-metrics/me?period=week`
- Returns: `sessions`, `minutes`, `avg_duration`, `trend_vs_prev`; server computes deltas.

## Streaks
- `GET /api/member-streaks/me`
- Returns: `current`, `best`, `last_activity_date`, `missed_days`; server calculates.

## Analytics events
- `POST /api/analytics/event`
- Types: `login_success`, `login_failed`, `home_viewed`, `program_selected`, `workout_started`, `workout_completed`
- Payload: `type`, `screen`, optional `program_id`, `workout_id`, `device_id`, `context` (e.g., `platform: "ios"`)

## Responsibilities split
- Server: return fully shaped objects and computed metrics; keep authorization and validation; reuse existing logic (no behavioral drift).
- Client: call one endpoint per intent, store/use payload as-is, avoid client-side joins or calculations beyond view rendering.
