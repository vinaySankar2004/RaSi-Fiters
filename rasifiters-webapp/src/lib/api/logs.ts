import { apiRequest } from "@/lib/api/client";

export async function addWorkoutLog(
  token: string,
  payload: {
    program_id: string;
    workout_name: string;
    date: string;
    duration: number;
    member_id?: string;
    member_name?: string;
  }
) {
  return apiRequest("/workout-logs", {
    method: "POST",
    token,
    body: payload
  });
}

export async function addDailyHealthLog(
  token: string,
  payload: {
    program_id: string;
    log_date: string;
    sleep_hours?: number | null;
    food_quality?: number | null;
    member_id?: string;
  }
) {
  return apiRequest("/daily-health-logs", {
    method: "POST",
    token,
    body: payload
  });
}

export async function updateDailyHealthLog(
  token: string,
  payload: {
    program_id: string;
    log_date: string;
    sleep_hours?: number | null;
    food_quality?: number | null;
    member_id?: string;
  }
) {
  return apiRequest("/daily-health-logs", {
    method: "PUT",
    token,
    body: payload
  });
}

export async function deleteDailyHealthLog(
  token: string,
  payload: { program_id: string; member_id: string; log_date: string }
) {
  return apiRequest("/daily-health-logs", {
    method: "DELETE",
    token,
    body: payload
  });
}

export async function deleteWorkoutLog(
  token: string,
  payload: { program_id: string; member_id: string; workout_name: string; date: string }
) {
  return apiRequest("/workout-logs", {
    method: "DELETE",
    token,
    body: payload
  });
}

export async function updateWorkoutLog(
  token: string,
  payload: { program_id: string; workout_name: string; date: string; duration: number; member_name?: string }
) {
  return apiRequest("/workout-logs", {
    method: "PUT",
    token,
    body: payload
  });
}
