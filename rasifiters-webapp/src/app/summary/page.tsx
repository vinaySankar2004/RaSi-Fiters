"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchProgramMembers, fetchWorkouts } from "@/lib/api/programs";
import {
  fetchActivityTimeline,
  fetchAnalyticsSummary,
  fetchAvgDurationMTD,
  fetchDistributionByDay,
  fetchMTDParticipation,
  fetchTotalDurationMTD,
  fetchTotalWorkoutsMTD,
  fetchWorkoutTypes,
  ActivityTimelinePoint,
  WorkoutType
} from "@/lib/api/summary";
import { addDailyHealthLog, addWorkoutLog } from "@/lib/api/logs";
import { Select } from "@/components/Select";

type PeriodKey = "week" | "month" | "year" | "program";

export default function SummaryPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();

  const summaryPeriod: PeriodKey = "week";
  const [showWorkoutForm, setShowWorkoutForm] = useState(false);
  const [showHealthForm, setShowHealthForm] = useState(false);

  useEffect(() => {
    if (!isBootstrapping && !session?.token) {
      router.push("/login");
    }
  }, [isBootstrapping, session?.token, router]);

  useEffect(() => {
    if (!program?.id) {
      router.push("/programs");
    }
  }, [program?.id, router]);

  const programId = program?.id ?? "";
  const canLogForAny =
    session?.user.globalRole === "global_admin" ||
    program?.my_role === "admin" ||
    program?.my_role === "logger";

  const analyticsQuery = useQuery({
    queryKey: ["summary", programId, summaryPeriod],
    queryFn: () => fetchAnalyticsSummary(token, summaryPeriod, programId),
    enabled: !!token && !!programId
  });

  const mtdParticipationQuery = useQuery({
    queryKey: ["summary", "mtdParticipation", programId],
    queryFn: () => fetchMTDParticipation(token, programId),
    enabled: !!token && !!programId
  });

  const totalWorkoutsQuery = useQuery({
    queryKey: ["summary", "totalWorkouts", programId],
    queryFn: () => fetchTotalWorkoutsMTD(token, programId),
    enabled: !!token && !!programId
  });

  const totalDurationQuery = useQuery({
    queryKey: ["summary", "totalDuration", programId],
    queryFn: () => fetchTotalDurationMTD(token, programId),
    enabled: !!token && !!programId
  });

  const avgDurationQuery = useQuery({
    queryKey: ["summary", "avgDuration", programId],
    queryFn: () => fetchAvgDurationMTD(token, programId),
    enabled: !!token && !!programId
  });

  const activityTimelineQuery = useQuery({
    queryKey: ["summary", "timeline", programId, summaryPeriod],
    queryFn: () => fetchActivityTimeline(token, summaryPeriod, programId),
    enabled: !!token && !!programId
  });

  const distributionQuery = useQuery({
    queryKey: ["summary", "distribution", programId],
    queryFn: () => fetchDistributionByDay(token, programId),
    enabled: !!token && !!programId
  });

  const workoutTypesQuery = useQuery({
    queryKey: ["summary", "workoutTypes", programId],
    queryFn: () => fetchWorkoutTypes(token, programId, 50),
    enabled: !!token && !!programId
  });


  const workoutLogMutation = useMutation({
    mutationFn: (payload: {
      member_id?: string;
      member_name?: string;
      workout_name: string;
      date: string;
      duration: number;
    }) => {
      return addWorkoutLog(token, {
        program_id: programId,
        ...payload
      });
    },
    onSuccess: async () => {
      await refreshSummaryQueries(queryClient);
      setShowWorkoutForm(false);
    }
  });

  const dailyHealthMutation = useMutation({
    mutationFn: (payload: { member_id?: string; log_date: string; sleep_hours?: number | null; food_quality?: number | null }) => {
      return addDailyHealthLog(token, {
        program_id: programId,
        ...payload
      });
    },
    onSuccess: async () => {
      await refreshSummaryQueries(queryClient);
      setShowHealthForm(false);
    }
  });

  const activityData = activityTimelineQuery.data?.buckets ?? [];
  const distributionPoints = useMemo(() => {
    const data = distributionQuery.data;
    if (!data) return [];
    return [
      { day: "Sun", value: data.Sunday },
      { day: "Mon", value: data.Monday },
      { day: "Tue", value: data.Tuesday },
      { day: "Wed", value: data.Wednesday },
      { day: "Thu", value: data.Thursday },
      { day: "Fri", value: data.Friday },
      { day: "Sat", value: data.Saturday }
    ];
  }, [distributionQuery.data]);

  const topWorkoutTypes = useMemo(() => {
    const types = workoutTypesQuery.data ?? [];
    return [...types].sort((a, b) => b.sessions - a.sessions).slice(0, 6);
  }, [workoutTypesQuery.data]);

  const userInitials = useMemo(() => {
    const name = session?.user.memberName ?? session?.user.username ?? "U";
    return name
      .split(" ")
      .filter(Boolean)
      .map((part) => part[0]?.toUpperCase())
      .slice(0, 2)
      .join("");
  }, [session?.user.memberName, session?.user.username]);

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <SummaryHeader title="Summary" subtitle={program?.name ?? "Program"} initials={userInitials || "RF"} />

        {analyticsQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(analyticsQuery.error as Error).message}
          </div>
        )}

        <div className="grid gap-5">
          <div className="grid gap-5 md:grid-cols-2">
            <ProgramProgressCard summary={analyticsQuery.data} />
            <ActivityTimelineCard
              label={activityTimelineQuery.data?.label ?? "Activity"}
              dailyAverage={activityTimelineQuery.data?.daily_average ?? 0}
              points={activityData}
              onClick={() => router.push("/summary/activity")}
            />
          </div>

          <div className="grid gap-5 md:grid-cols-2">
            <AddWorkoutCard onClick={() => setShowWorkoutForm(true)} />
            <AddHealthCard onClick={() => setShowHealthForm(true)} />
          </div>

          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              title="MTD Participation"
              value={
                mtdParticipationQuery.data
                  ? `${mtdParticipationQuery.data.participation_pct.toFixed(1)}%`
                  : "—"
              }
              subtitle={
                mtdParticipationQuery.data
                  ? `${mtdParticipationQuery.data.active_members} / ${mtdParticipationQuery.data.total_members} members`
                  : "Loading..."
              }
              delta={mtdParticipationQuery.data?.change_pct}
            />
            <StatCard
              title="Total Workouts"
              value={totalWorkoutsQuery.data ? `${totalWorkoutsQuery.data.total_workouts}` : "—"}
              subtitle="Month to date"
              delta={totalWorkoutsQuery.data?.change_pct}
            />
            <StatCard
              title="Total Duration"
              value={
                totalDurationQuery.data
                  ? `${(totalDurationQuery.data.total_minutes / 60).toFixed(1)} hrs`
                  : "—"
              }
              subtitle="Month to date"
              delta={totalDurationQuery.data?.change_pct}
            />
            <StatCard
              title="Avg Duration"
              value={avgDurationQuery.data ? `${avgDurationQuery.data.avg_minutes} min` : "—"}
              subtitle="Month to date"
              delta={avgDurationQuery.data?.change_pct}
            />
          </div>

          <div className="grid gap-5 md:grid-cols-2">
            <DistributionCard points={distributionPoints} onClick={() => router.push("/summary/distribution")} />
            <WorkoutTypesCard types={topWorkoutTypes} onClick={() => router.push("/summary/workout-types")} />
          </div>
        </div>
      </div>

      <Modal open={showWorkoutForm} onClose={() => setShowWorkoutForm(false)}>
        <LogWorkoutForm
          canSelectAnyMember={canLogForAny}
          programId={programId}
          token={token}
          userId={session?.user.id}
          onClose={() => setShowWorkoutForm(false)}
          onSubmit={(payload) => workoutLogMutation.mutate(payload)}
          isSaving={workoutLogMutation.isPending}
          errorMessage={workoutLogMutation.isError ? (workoutLogMutation.error as Error).message : null}
        />
      </Modal>

      <Modal open={showHealthForm} onClose={() => setShowHealthForm(false)}>
        <LogDailyHealthForm
          canSelectAnyMember={canLogForAny}
          programId={programId}
          token={token}
          userId={session?.user.id}
          onClose={() => setShowHealthForm(false)}
          onSubmit={(payload) => dailyHealthMutation.mutate(payload)}
          isSaving={dailyHealthMutation.isPending}
          errorMessage={dailyHealthMutation.isError ? (dailyHealthMutation.error as Error).message : null}
        />
      </Modal>
    </div>
  );
}

async function refreshSummaryQueries(queryClient: ReturnType<typeof useQueryClient>) {
  await queryClient.invalidateQueries({ queryKey: ["summary"] });
}

function SummaryHeader({
  title,
  subtitle,
  initials
}: {
  title: string;
  subtitle: string;
  initials: string;
}) {
  return (
    <div className="flex items-center gap-6">
      <div>
        <h1 className="text-3xl font-bold text-rf-text">{title}</h1>
        <p className="mt-1 text-sm font-semibold text-rf-text-muted">{subtitle}</p>
      </div>
      <div className="ml-auto flex items-center gap-3">
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-rf-accent text-base font-bold text-black">
          {initials}
        </div>
      </div>
    </div>
  );
}

function ProgramProgressCard({ summary }: { summary?: any }) {
  const progress = summary?.program_progress;
  const percent = progress?.progress_percent ?? 0;
  const elapsed = progress?.elapsed_days ?? 0;
  const total = progress?.total_days ?? 0;
  const size = 120;
  const stroke = 10;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - percent / 100);

  return (
    <div className="glass-card w-full rounded-3xl p-6">
      <h3 className="text-left text-lg font-semibold text-rf-text">Program Progress</h3>
      <div className="mt-6 flex flex-col items-center gap-4 text-center">
        <div className="relative flex items-center justify-center" style={{ width: size, height: size }}>
          <svg width={size} height={size} className="absolute inset-0">
            <circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke="var(--rf-border)"
              strokeWidth={stroke}
              fill="none"
            />
            <circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke="#ff8b1f"
              strokeWidth={stroke}
              fill="none"
              strokeDasharray={circumference}
              strokeDashoffset={offset}
              strokeLinecap="round"
              style={{ transform: "rotate(-90deg)", transformOrigin: "50% 50%" }}
            />
          </svg>
          <div className="relative z-10 text-center">
            <p className="text-2xl font-bold">{percent}%</p>
            <p className="text-xs text-rf-text-muted">
              {elapsed}/{total} days
            </p>
          </div>
        </div>
        <StatusPill status={progress?.status ?? "active"} />
        <div className="flex flex-wrap items-center justify-center gap-6">
          <div>
            <p className="text-sm text-rf-text-muted">Elapsed</p>
            <p className="text-lg font-semibold text-rf-text">{elapsed} days</p>
          </div>
          <div>
            <p className="text-sm text-rf-text-muted">Remaining</p>
            <p className="text-lg font-semibold text-rf-text">{progress?.remaining_days ?? 0} days</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function AddWorkoutCard({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="h-full rounded-3xl bg-gradient-to-br from-orange-300 via-orange-400 to-orange-500 p-6 text-left text-black shadow-lg"
    >
      <div className="flex items-center justify-between">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white/25 text-lg font-bold">+</div>
        <span className="text-sm font-semibold">›</span>
      </div>
      <h3 className="mt-4 text-xl font-bold">Add workout</h3>
      <p className="mt-2 text-sm text-black/70">Quick add a session and keep progress up to date.</p>
      <div className="mt-6 inline-flex items-center rounded-full bg-black/15 px-4 py-2 text-sm font-semibold">
        Log session
      </div>
    </button>
  );
}

function AddHealthCard({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="h-full rounded-3xl bg-gradient-to-br from-sky-400 via-sky-500 to-blue-600 p-6 text-left text-white shadow-lg"
    >
      <div className="flex items-center justify-between">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white/25 text-lg font-bold">✦</div>
        <span className="text-sm font-semibold">›</span>
      </div>
      <h3 className="mt-4 text-xl font-bold">Log daily health</h3>
      <p className="mt-2 text-sm text-white/80">Track sleep hours and diet quality for the day.</p>
      <div className="mt-6 inline-flex items-center rounded-full bg-white/20 px-4 py-2 text-sm font-semibold">
        Log day
      </div>
    </button>
  );
}

function StatCard({
  title,
  value,
  subtitle,
  delta
}: {
  title: string;
  value: string;
  subtitle: string;
  delta?: number;
}) {
  return (
    <div className="glass-card rounded-3xl p-5">
      <p className="text-sm font-semibold text-rf-text-muted">{title}</p>
      <p className="mt-3 text-2xl font-bold text-rf-text">{value}</p>
      <div className="mt-2 flex items-center justify-between text-xs text-rf-text-muted">
        <span>{subtitle}</span>
        {delta !== undefined && (
          <span className={delta >= 0 ? "text-emerald-600" : "text-rf-danger"}>
            {delta >= 0 ? "+" : ""}
            {delta.toFixed(1)}%
          </span>
        )}
      </div>
    </div>
  );
}

function ActivityTimelineCard({
  label,
  dailyAverage,
  points,
  onClick
}: {
  label: string;
  dailyAverage: number;
  points: ActivityTimelinePoint[];
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
      aria-label="View activity timeline"
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">Activity Timeline</p>
          <p className="text-lg font-semibold text-rf-text">{label}</p>
        </div>
        <div className="text-right">
          <span className="text-lg font-semibold text-rf-text-muted">&gt;</span>
          <p className="mt-1 text-xs text-rf-text-muted">Daily avg</p>
          <p className="text-base font-semibold text-rf-text">{dailyAverage.toFixed(1)}</p>
        </div>
      </div>
      <div className="mt-4 h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={points}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
            <XAxis dataKey="label" tick={{ fontSize: 10, fill: "var(--rf-text-muted)" }} />
            <YAxis hide />
            <Tooltip
              contentStyle={{
                borderRadius: 12,
                border: "1px solid var(--rf-border)",
                backgroundColor: "var(--rf-surface)",
                color: "var(--rf-text)",
                boxShadow: "0 14px 24px rgba(0, 0, 0, 0.25)"
              }}
              labelStyle={{ color: "var(--rf-text-muted)" }}
              formatter={(value: number, name: string) => [value, name === "workouts" ? "Workouts" : "Active members"]}
            />
            <Bar dataKey="workouts" fill="#ff8b1f" radius={[8, 8, 0, 0]} />
            <Bar dataKey="active_members" fill="#60a5fa" radius={[8, 8, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </button>
  );
}

function DistributionCard({
  points,
  onClick
}: {
  points: { day: string; value: number }[];
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
      aria-label="View workout distribution"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">Workout Distribution</p>
          <p className="text-lg font-semibold text-rf-text">By day of week</p>
        </div>
        <span className="text-sm font-semibold text-rf-text-muted opacity-60 transition group-hover:opacity-100">›</span>
      </div>
      <div className="mt-4 h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={points}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
            <XAxis dataKey="day" tick={{ fontSize: 10, fill: "var(--rf-text-muted)" }} />
            <YAxis hide />
            <Tooltip
              contentStyle={{
                borderRadius: 12,
                border: "1px solid var(--rf-border)",
                backgroundColor: "var(--rf-surface)",
                color: "var(--rf-text)",
                boxShadow: "0 14px 24px rgba(0, 0, 0, 0.25)"
              }}
              labelStyle={{ color: "var(--rf-text-muted)" }}
              formatter={(value: number) => [value, "Workouts"]}
            />
            <Bar dataKey="value" fill="#f59e0b" radius={[8, 8, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </button>
  );
}

function WorkoutTypesCard({ types, onClick }: { types: WorkoutType[]; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
      aria-label="View workout types"
    >
      <div className="flex items-center justify-between">
        <p className="text-sm font-semibold text-rf-text-muted">Workout Types</p>
        <span className="text-sm font-semibold text-rf-text-muted opacity-60 transition group-hover:opacity-100">›</span>
      </div>
      {types.length === 0 ? (
        <p className="mt-4 text-sm text-rf-text-muted">No workouts logged yet.</p>
      ) : (
        <ul className="mt-4 space-y-2 text-sm">
          {types.map((type) => (
            <li key={type.workout_name} className="flex items-center justify-between">
              <span className="font-semibold text-rf-text">{type.workout_name}</span>
              <span className="text-rf-text-muted">{type.sessions} sessions</span>
            </li>
          ))}
        </ul>
      )}
    </button>
  );
}

function StatusPill({ status }: { status: string }) {
  const color = statusColor(status);
  return (
    <span
      className="rounded-full px-3 py-1 text-[11px] font-semibold uppercase"
      style={{ background: `${color}22`, color }}
    >
      {status}
    </span>
  );
}

function statusColor(status?: string | null) {
  switch ((status ?? "").toLowerCase()) {
    case "completed":
      return "#2fb861";
    case "planned":
      return "#3b82f6";
    default:
      return "#ff8b1f";
  }
}

function LogWorkoutForm({
  canSelectAnyMember,
  programId,
  token,
  userId,
  onClose,
  onSubmit,
  isSaving,
  errorMessage
}: {
  canSelectAnyMember: boolean;
  programId: string;
  token: string;
  userId?: string;
  onClose: () => void;
  onSubmit: (payload: { member_id?: string; member_name?: string; workout_name: string; date: string; duration: number }) => void;
  isSaving: boolean;
  errorMessage: string | null;
}) {
  const [members, setMembers] = useState<{ id: string; member_name: string }[]>([]);
  const [workouts, setWorkouts] = useState<{ workout_name: string }[]>([]);
  const [memberId, setMemberId] = useState("");
  const [workoutName, setWorkoutName] = useState("");
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [duration, setDuration] = useState("");

  useEffect(() => {
    const loadLookups = async () => {
      if (!token || !programId) return;
      const membersData = await fetchProgramMembers(token, programId);
      const workoutsData = await fetchWorkouts(token);
      setMembers(membersData);
      setWorkouts(workoutsData);
      if (!canSelectAnyMember && userId) {
        setMemberId(userId);
      }
    };
    loadLookups();
  }, [token, programId, canSelectAnyMember, userId]);

  const canSubmit =
    workoutName.trim().length > 0 && date.trim().length > 0 && duration.trim().length > 0 && (!canSelectAnyMember || memberId);

  return (
    <div className="modal-surface w-full max-w-lg rounded-3xl p-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold text-rf-text">Log workout</h2>
          <p className="mt-1 text-sm text-rf-text-muted">Pick member, workout, date, and duration.</p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-full border border-transparent bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted transition hover:bg-rf-surface"
          aria-label="Close form"
        >
          Close
        </button>
      </div>

      <div className="mt-4 space-y-4">
        {canSelectAnyMember ? (
          <Select
            label="Member"
            value={memberId}
            options={members.map((m) => ({ value: m.id, label: m.member_name }))}
            onChange={setMemberId}
            placeholder="Select member"
          />
        ) : (
          <div>
            <p className="text-sm font-semibold text-rf-text">Member</p>
            <div className="mt-2 rounded-2xl bg-rf-surface-muted px-4 py-3 text-sm text-rf-text-muted">
              You
            </div>
          </div>
        )}

        <Select
          label="Workout type"
          value={workoutName}
          options={workouts.map((w) => ({ value: w.workout_name, label: w.workout_name }))}
          onChange={setWorkoutName}
          placeholder="Select workout"
        />

        <div>
          <label className="text-sm font-semibold text-rf-text">Date</label>
          <input
            type="date"
            value={date}
            onChange={(event) => setDate(event.target.value)}
            className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
          />
        </div>

        <div>
          <label className="text-sm font-semibold text-rf-text">Duration (mins)</label>
          <input
            value={duration}
            onChange={(event) => setDuration(event.target.value)}
            className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
            placeholder="e.g. 45"
          />
        </div>
      </div>

      {errorMessage && <p className="mt-3 text-sm font-semibold text-rf-danger">{errorMessage}</p>}

      <button
        type="button"
        disabled={!canSubmit || isSaving}
        onClick={() =>
          onSubmit({
            member_id: canSelectAnyMember ? memberId || undefined : userId,
            workout_name: workoutName,
            date,
            duration: Number(duration)
          })
        }
        className="mt-5 w-full rounded-2xl bg-rf-accent px-4 py-3 text-sm font-semibold text-black"
      >
        {isSaving ? "Saving…" : "Save workout"}
      </button>
    </div>
  );
}

function LogDailyHealthForm({
  canSelectAnyMember,
  programId,
  token,
  userId,
  onClose,
  onSubmit,
  isSaving,
  errorMessage
}: {
  canSelectAnyMember: boolean;
  programId: string;
  token: string;
  userId?: string;
  onClose: () => void;
  onSubmit: (payload: { member_id?: string; log_date: string; sleep_hours?: number | null; food_quality?: number | null }) => void;
  isSaving: boolean;
  errorMessage: string | null;
}) {
  const [members, setMembers] = useState<{ id: string; member_name: string }[]>([]);
  const [memberId, setMemberId] = useState("");
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [sleepHours, setSleepHours] = useState("");
  const [foodQuality, setFoodQuality] = useState("");

  useEffect(() => {
    const loadLookups = async () => {
      if (!token || !programId) return;
      const membersData = await fetchProgramMembers(token, programId);
      setMembers(membersData);
      if (!canSelectAnyMember && userId) {
        setMemberId(userId);
      }
    };
    loadLookups();
  }, [token, programId, canSelectAnyMember, userId]);

  const sleepValue = sleepHours.trim() === "" ? null : Number(sleepHours);
  const foodValue = foodQuality.trim() === "" ? null : Number(foodQuality);
  const hasMetric = sleepValue !== null || foodValue !== null;
  const sleepValid = sleepValue === null || (sleepValue >= 0 && sleepValue <= 24);

  const canSubmit = hasMetric && sleepValid && (!canSelectAnyMember || memberId);

  return (
    <div className="modal-surface w-full max-w-lg rounded-3xl p-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold text-rf-text">Log daily health</h2>
          <p className="mt-1 text-sm text-rf-text-muted">Track sleep hours and diet quality for the day.</p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-full border border-transparent bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted transition hover:bg-rf-surface"
          aria-label="Close form"
        >
          Close
        </button>
      </div>

      <div className="mt-4 space-y-4">
        {canSelectAnyMember ? (
          <Select
            label="Member"
            value={memberId}
            options={members.map((m) => ({ value: m.id, label: m.member_name }))}
            onChange={setMemberId}
            placeholder="Select member"
          />
        ) : (
          <div>
            <p className="text-sm font-semibold text-rf-text">Member</p>
            <div className="mt-2 rounded-2xl bg-rf-surface-muted px-4 py-3 text-sm text-rf-text-muted">
              You
            </div>
          </div>
        )}

        <div>
          <label className="text-sm font-semibold text-rf-text">Date</label>
          <input
            type="date"
            value={date}
            onChange={(event) => setDate(event.target.value)}
            className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
          />
        </div>

        <div>
          <label className="text-sm font-semibold text-rf-text">Sleep hours</label>
          <input
            value={sleepHours}
            onChange={(event) => setSleepHours(event.target.value)}
            className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
            placeholder="e.g. 7.5"
          />
          {!sleepValid && <p className="mt-2 text-xs font-semibold text-rf-danger">Sleep hours must be between 0 and 24.</p>}
        </div>

        <Select
          label="Diet quality"
          value={foodQuality}
          options={[1, 2, 3, 4, 5].map((val) => ({ value: String(val), label: String(val) }))}
          onChange={setFoodQuality}
          placeholder="Select rating (1-5)"
        />
      </div>

      {errorMessage && <p className="mt-3 text-sm font-semibold text-rf-danger">{errorMessage}</p>}

      <button
        type="button"
        disabled={!canSubmit || isSaving}
        onClick={() =>
          onSubmit({
            member_id: canSelectAnyMember ? memberId || undefined : userId,
            log_date: date,
            sleep_hours: sleepValue,
            food_quality: foodValue
          })
        }
        className="mt-5 w-full rounded-2xl bg-sky-500 px-4 py-3 text-sm font-semibold text-white"
      >
        {isSaving ? "Saving…" : "Save daily log"}
      </button>
    </div>
  );
}

function Modal({ open, onClose, children }: { open: boolean; onClose: () => void; children: React.ReactNode }) {
  useEffect(() => {
    if (!open) return;
    const body = document.body;
    const previousOverflow = body.style.overflow;
    body.style.overflow = "hidden";
    body.classList.add("modal-open");
    return () => {
      body.style.overflow = previousOverflow;
      body.classList.remove("modal-open");
    };
  }, [open]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative z-10 flex w-full max-h-[90vh] justify-center overflow-auto">{children}</div>
    </div>
  );
}
