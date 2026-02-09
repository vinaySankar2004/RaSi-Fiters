"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { fetchProgramMembers, type Member } from "@/lib/api/programs";
import {
  fetchMemberHealthLogs,
  fetchMemberHistory,
  fetchMemberMetrics,
  fetchMemberRecentWorkouts,
  fetchMemberStreaks,
  type MemberHealthItem,
  type MemberHistoryPoint,
  type MemberMetrics,
  type MemberRecentItem
} from "@/lib/api/members";
import { formatShortDate } from "@/lib/format";
import { useActiveProgram } from "@/lib/use-active-program";

export default function MembersPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = useActiveProgram();
  const programId = program?.id ?? "";

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;
  const canInvite = isProgramAdmin;
  const canViewAs = isProgramAdmin;
  const loggedInUserId = session?.user.id;

  const [showMemberPicker, setShowMemberPicker] = useState(false);
  const [adminSelectedMember, setAdminSelectedMember] = useState<Member | null>(null);

  const viewAsStorageKey = useMemo(() => {
    if (!programId || !loggedInUserId) return "";
    return `rf:members:view-as:${programId}:${loggedInUserId}`;
  }, [programId, loggedInUserId]);

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

  const membersQuery = useQuery({
    queryKey: ["members", "list", programId],
    queryFn: () => fetchProgramMembers(token, programId),
    enabled: !!token && !!programId
  });

  useEffect(() => {
    if (!canViewAs) return;
    if (!viewAsStorageKey) return;
    const stored = sessionStorage.getItem(viewAsStorageKey);
    if (!stored) return;
    if (stored === "none") {
      if (isGlobalAdmin) {
        setAdminSelectedMember(null);
      }
      return;
    }
    if (!membersQuery.data) return;
    if (adminSelectedMember?.id === stored) return;
    const match = membersQuery.data.find((member) => member.id === stored);
    if (match) {
      setAdminSelectedMember(match);
    }
  }, [canViewAs, viewAsStorageKey, membersQuery.data, adminSelectedMember?.id, isGlobalAdmin]);

  useEffect(() => {
    if (!canViewAs) return;
    if (isGlobalAdmin) return;
    if (!loggedInUserId) return;
    if (adminSelectedMember) return;
    if (viewAsStorageKey && sessionStorage.getItem(viewAsStorageKey)) return;
    const match = membersQuery.data?.find((member) => member.id === loggedInUserId);
    if (match) {
      setAdminSelectedMember(match);
      if (viewAsStorageKey) {
        sessionStorage.setItem(viewAsStorageKey, match.id);
      }
    }
  }, [canViewAs, isGlobalAdmin, loggedInUserId, membersQuery.data, adminSelectedMember, viewAsStorageKey]);

  const selectedMember: Member | null = useMemo(() => {
    if (canViewAs) return adminSelectedMember;
    if (!loggedInUserId) return null;
    return {
      id: loggedInUserId,
      member_name: session?.user.memberName ?? "Member"
    };
  }, [canViewAs, adminSelectedMember, loggedInUserId, session?.user.memberName]);

  const selectedMemberId = selectedMember?.id ?? "";

  const metricsPreviewQuery = useQuery({
    queryKey: ["members", "metrics", programId, "preview"],
    queryFn: () =>
      fetchMemberMetrics(token, programId, {
        sort: "workouts",
        direction: "desc"
      }),
    enabled: !!token && !!programId && canViewAs
  });

  const memberOverviewQuery = useQuery({
    queryKey: ["members", "overview", programId, selectedMemberId],
    queryFn: () =>
      fetchMemberMetrics(token, programId, {
        memberId: selectedMemberId
      }),
    enabled: !!token && !!programId && !!selectedMemberId
  });

  const memberHistoryQuery = useQuery({
    queryKey: ["members", "history", programId, selectedMemberId],
    queryFn: () => fetchMemberHistory(token, programId, selectedMemberId, "week"),
    enabled: !!token && !!programId && !!selectedMemberId
  });

  const memberStreakQuery = useQuery({
    queryKey: ["members", "streaks", programId, selectedMemberId],
    queryFn: () => fetchMemberStreaks(token, programId, selectedMemberId),
    enabled: !!token && !!programId && !!selectedMemberId
  });

  const memberRecentQuery = useQuery({
    queryKey: ["members", "recent", programId, selectedMemberId],
    queryFn: () =>
      fetchMemberRecentWorkouts(token, programId, selectedMemberId, {
        limit: 10,
        sortBy: "date",
        sortDir: "desc"
      }),
    enabled: !!token && !!programId && !!selectedMemberId
  });

  const memberHealthQuery = useQuery({
    queryKey: ["members", "health", programId, selectedMemberId],
    queryFn: () =>
      fetchMemberHealthLogs(token, programId, selectedMemberId, {
        limit: 10,
        sortBy: "date",
        sortDir: "desc"
      }),
    enabled: !!token && !!programId && !!selectedMemberId
  });

  const memberOverview = memberOverviewQuery.data?.members?.[0];

  const viewAsLabel = useMemo(() => {
    if (!canViewAs) return "";
    if (adminSelectedMember) return adminSelectedMember.member_name;
    if (isGlobalAdmin) return "None";
    return session?.user.memberName ?? "Member";
  }, [canViewAs, adminSelectedMember, isGlobalAdmin, session?.user.memberName]);

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <header className="flex items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-rf-text">Members</h1>
            <p className="mt-1 text-sm font-semibold text-rf-text-muted">{program?.name ?? "Program"}</p>
          </div>
          <div className="ml-auto flex items-center gap-3">
            {!canViewAs && (
              <button
                type="button"
                onClick={() => router.push("/members/list")}
              className="pill-button rounded-full px-4 py-2 text-xs font-semibold transition"
              >
                View Members
              </button>
            )}
            {canInvite && (
              <button
                type="button"
                onClick={() => router.push("/members/invite")}
                className="flex h-12 w-12 items-center justify-center rounded-full bg-rf-accent text-lg font-semibold text-black shadow"
                aria-label="Invite member"
              >
                <MailIcon className="h-6 w-6 text-black" />
              </button>
            )}
          </div>
        </header>

        {canViewAs && (
          <button
            type="button"
            onClick={() => router.push("/members/metrics")}
            className="glass-card group w-full rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-rf-text-muted">Member Performance Metrics</p>
                <p className="text-xs font-semibold text-rf-text-muted">
                  {metricsPreviewQuery.data ? `${metricsPreviewQuery.data.total} members` : "Loading..."}
                </p>
              </div>
              <span className="text-sm font-semibold text-rf-text-muted">›</span>
            </div>
            <div className="mt-4">
              {metricsPreviewQuery.isLoading && (
                <div className="rounded-2xl bg-rf-surface-muted px-4 py-6 text-sm text-rf-text-muted">
                  Loading metrics...
                </div>
              )}
              {metricsPreviewQuery.data && metricsPreviewQuery.data.members.length > 0 && (
                <MemberMetricsPreview metric={metricsPreviewQuery.data.members[0]} />
              )}
              {metricsPreviewQuery.data && metricsPreviewQuery.data.members.length === 0 && (
                <p className="text-sm text-rf-text-muted">No members to display yet.</p>
              )}
            </div>
          </button>
        )}

        {canViewAs && (
          <button
            type="button"
            onClick={() => setShowMemberPicker(true)}
            className="glass-card flex items-center gap-4 rounded-3xl px-5 py-4"
          >
            <p className="text-sm font-semibold text-rf-text">View as</p>
            <span className="ml-auto text-sm font-semibold text-rf-text-muted">{viewAsLabel}</span>
            <span className="text-xs text-rf-text-muted">⌄</span>
          </button>
        )}

        {!selectedMemberId && canViewAs && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">
            Select a member to view their performance cards.
          </div>
        )}

        {selectedMemberId && (
          <div className="grid gap-5">
            {canViewAs ? (
              <MemberOverviewCard
                metric={memberOverview}
                programStart={program?.start_date}
                programEnd={program?.end_date}
              />
            ) : (
              <div className="grid gap-5 md:grid-cols-2">
                <MemberOverviewCard
                  metric={memberOverview}
                  programStart={program?.start_date}
                  programEnd={program?.end_date}
                />
                {memberOverview && <MemberMetricsSingleCard metric={memberOverview} />}
              </div>
            )}

            <div className="grid gap-5 md:grid-cols-2">
              <MemberHistoryCard
                points={memberHistoryQuery.data?.buckets ?? []}
                label={memberHistoryQuery.data?.label ?? ""}
                dailyAverage={memberHistoryQuery.data?.daily_average ?? 0}
                onClick={() => router.push(`/members/history?memberId=${selectedMemberId}&name=${encodeURIComponent(selectedMember?.member_name ?? "")}`)}
              />
              <MemberStreakCard
                current={memberStreakQuery.data?.currentStreakDays ?? 0}
                longest={memberStreakQuery.data?.longestStreakDays ?? 0}
                onClick={() => router.push(`/members/streaks?memberId=${selectedMemberId}&name=${encodeURIComponent(selectedMember?.member_name ?? "")}`)}
              />
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <MemberRecentCard
                items={memberRecentQuery.data?.items ?? []}
                onClick={() => router.push(`/members/workouts?memberId=${selectedMemberId}&name=${encodeURIComponent(selectedMember?.member_name ?? "")}`)}
              />
              <MemberHealthCard
                items={memberHealthQuery.data?.items ?? []}
                onClick={() => router.push(`/members/health?memberId=${selectedMemberId}&name=${encodeURIComponent(selectedMember?.member_name ?? "")}`)}
              />
            </div>
          </div>
        )}
      </div>

      {showMemberPicker && (
        <MemberPickerModal
          members={membersQuery.data ?? []}
          selected={adminSelectedMember}
          allowNone={isGlobalAdmin}
          onClose={() => setShowMemberPicker(false)}
          onSelect={(member) => {
            setAdminSelectedMember(member);
            setShowMemberPicker(false);
            if (viewAsStorageKey) {
              sessionStorage.setItem(viewAsStorageKey, member ? member.id : "none");
            }
          }}
        />
      )}
    </div>
  );
}

function MemberMetricsPreview({ metric }: { metric: MemberMetrics }) {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="metric-pill flex h-12 w-12 items-center justify-center rounded-full text-sm font-semibold text-rf-text">
            {initials(metric.member_name)}
          </div>
          <div>
            <p className="text-base font-semibold text-rf-text">{metric.member_name}</p>
            <p className="text-xs text-rf-text-muted">Active days {metric.active_days}</p>
          </div>
        </div>
        <div className="text-right">
          <p className="text-xl font-bold text-rf-accent">{metric.workouts}</p>
          <p className="text-xs text-rf-text-muted">Workouts</p>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-3 text-xs text-rf-text-muted">
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.workouts}</p>
          <p>Workouts</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.total_duration}</p>
          <p>Total mins</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.workout_types}</p>
          <p>Types</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.avg_sleep_hours?.toFixed(1) ?? "—"}</p>
          <p>Avg sleep</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.avg_food_quality?.toFixed(1) ?? "—"}</p>
          <p>Avg diet</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.longest_streak}d</p>
          <p>Longest streak</p>
        </div>
      </div>
      <div className="mt-3">
        <span className="inline-flex items-center gap-2 rounded-full bg-amber-200/70 px-3 py-1 text-xs font-semibold text-amber-900">
          <FlameIcon className="h-3.5 w-3.5" /> Current streak {metric.current_streak}d
        </span>
      </div>
    </div>
  );
}

function MemberOverviewCard({
  metric,
  programStart,
  programEnd
}: {
  metric?: MemberMetrics;
  programStart?: string | null;
  programEnd?: string | null;
}) {
  const totalDays = useMemo(() => {
    if (!programStart || !programEnd) return 0;
    const start = new Date(programStart);
    const end = new Date(programEnd);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return 0;
    const days = Math.max(1, Math.floor((end.getTime() - start.getTime()) / 86400000) + 1);
    return days;
  }, [programStart, programEnd]);

  const progressPct = metric && totalDays ? Math.round((metric.active_days / totalDays) * 100) : 0;

  return (
    <div className="glass-card rounded-3xl p-5">
      <p className="text-sm font-semibold text-rf-text-muted">Member Overview</p>
      {metric ? (
        <>
          <div className="mt-3 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="metric-pill flex h-12 w-12 items-center justify-center rounded-full text-sm font-semibold text-rf-text">
                {initials(metric.member_name)}
              </div>
              <div>
                <p className="text-base font-semibold text-rf-text">{metric.member_name}</p>
                <p className="text-xs text-rf-text-muted">MTD Workouts: {metric.mtd_workouts ?? 0}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-xl font-bold text-rf-accent">{progressPct}%</p>
              <p className="text-xs text-rf-text-muted">PTD MP %</p>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-2 gap-3">
                <div className="metric-pill rounded-2xl px-3 py-2">
                  <p className="text-xs text-rf-text-muted">Total Time</p>
                  <p className="text-sm font-semibold text-rf-text">
                    {metric.total_hours ?? Math.round(metric.total_duration / 60)} hrs
                  </p>
                </div>
                <div className="metric-pill rounded-2xl px-3 py-2">
                  <p className="text-xs text-rf-text-muted">Favorite</p>
                  <p className="text-sm font-semibold text-rf-text">{metric.favorite_workout ?? "—"}</p>
                </div>
          </div>
          <div className="mt-4">
            <p className="text-xs font-semibold text-rf-text-muted">PTD - Member Progress</p>
            <div className="progress-track mt-2 h-2 w-full overflow-hidden rounded-full">
              <div className="h-full rounded-full bg-rf-accent" style={{ width: `${progressPct}%` }} />
            </div>
            <p className="mt-2 text-xs text-rf-text-muted">
              {metric.active_days} / {totalDays} days
            </p>
          </div>
        </>
      ) : (
        <p className="mt-3 text-sm text-rf-text-muted">No workouts logged yet.</p>
      )}
    </div>
  );
}

function MemberMetricsSingleCard({ metric }: { metric: MemberMetrics }) {
  return (
    <div className="glass-card rounded-3xl p-5">
      <p className="text-sm font-semibold text-rf-text-muted">Member Performance Metrics</p>
      <div className="mt-3 flex items-center justify-between">
        <div>
          <p className="text-base font-semibold text-rf-text">{metric.member_name}</p>
          <p className="text-xs text-rf-text-muted">Active days {metric.active_days}</p>
        </div>
        <div className="text-right">
          <p className="text-xl font-bold text-rf-accent">{metric.workouts}</p>
          <p className="text-xs text-rf-text-muted">Workouts</p>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-3 gap-3 text-xs text-rf-text-muted">
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.total_duration}</p>
          <p>Total mins</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.avg_duration}</p>
          <p>Avg mins</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.workout_types}</p>
          <p>Types</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.avg_sleep_hours?.toFixed(1) ?? "—"}</p>
          <p>Avg sleep</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.avg_food_quality?.toFixed(1) ?? "—"}</p>
          <p>Avg diet</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-2">
          <p className="font-semibold text-rf-text">{metric.longest_streak}d</p>
          <p>Longest streak</p>
        </div>
      </div>
      <div className="mt-3">
        <span className="inline-flex items-center gap-2 rounded-full bg-amber-200/70 px-3 py-1 text-xs font-semibold text-amber-900">
          <FlameIcon className="h-3.5 w-3.5" /> Current streak {metric.current_streak}d
        </span>
      </div>
    </div>
  );
}

function MemberHistoryCard({
  points,
  label,
  dailyAverage,
  onClick
}: {
  points: MemberHistoryPoint[];
  label: string;
  dailyAverage: number;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">Workout Activity</p>
          <p className="text-lg font-semibold text-rf-text">{label || "Last 7 days"}</p>
        </div>
        <div className="text-right">
          <p className="text-xs text-rf-text-muted">Daily avg</p>
          <p className="text-base font-semibold text-rf-text">{dailyAverage.toFixed(1)}</p>
        </div>
      </div>
      <div className="mt-4 h-36">
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
              formatter={(value: number) => [value, "Workouts"]}
            />
            <Bar dataKey="workouts" fill="#ff8b1f" radius={[8, 8, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </button>
  );
}

function MemberStreakCard({ current, longest, onClick }: { current: number; longest: number; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl px-5 pb-5 pt-3 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">Streak Stats</p>
          <p className="text-lg font-semibold text-rf-text">Current and longest</p>
        </div>
        <span className="text-sm font-semibold text-rf-text-muted">›</span>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-3">
        <div className="metric-pill rounded-2xl px-3 py-3">
          <p className="text-xs text-rf-text-muted">Current</p>
          <p className="text-base font-semibold text-rf-text">{current} days</p>
        </div>
        <div className="metric-pill rounded-2xl px-3 py-3">
          <p className="text-xs text-rf-text-muted">Longest</p>
          <p className="text-base font-semibold text-rf-text">{longest} days</p>
        </div>
      </div>
    </button>
  );
}

function MemberRecentCard({ items, onClick }: { items: MemberRecentItem[]; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">View Workouts</p>
          <p className="text-lg font-semibold text-rf-text">All workouts</p>
        </div>
        <span className="text-sm font-semibold text-rf-text-muted">›</span>
      </div>
      <div className="mt-4 space-y-2 text-sm">
        {items.length === 0 && <p className="text-sm text-rf-text-muted">No workouts logged yet.</p>}
        {items.slice(0, 3).map((item) => (
          <div key={item.id} className="flex items-center justify-between">
            <div>
              <p className="font-semibold text-rf-text">{item.workoutType}</p>
              <p className="text-xs text-rf-text-muted">{formatShortDate(item.workoutDate) ?? item.workoutDate}</p>
            </div>
            <p className="font-semibold text-rf-text">{item.durationMinutes} min</p>
          </div>
        ))}
      </div>
    </button>
  );
}

function MemberHealthCard({ items, onClick }: { items: MemberHealthItem[]; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="glass-card group rounded-3xl p-5 text-left transition hover:-translate-y-0.5 hover:shadow-lg"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-semibold text-rf-text-muted">View Health</p>
          <p className="text-lg font-semibold text-rf-text">Daily health logs</p>
        </div>
        <span className="text-sm font-semibold text-rf-text-muted">›</span>
      </div>
      <div className="mt-4 space-y-2 text-sm">
        {items.length === 0 && <p className="text-sm text-rf-text-muted">No daily health logs yet.</p>}
        {items.slice(0, 3).map((item) => (
          <div key={item.id} className="flex items-center justify-between">
            <div>
              <p className="font-semibold text-rf-text">Sleep {sleepLabel(item.sleepHours)}</p>
              <p className="text-xs text-rf-text-muted">{formatShortDate(item.logDate) ?? item.logDate}</p>
            </div>
            <p className="font-semibold text-rf-text">Diet {dietLabel(item.foodQuality)}</p>
          </div>
        ))}
      </div>
    </button>
  );
}

function MemberPickerModal({
  members,
  selected,
  allowNone,
  onClose,
  onSelect
}: {
  members: Member[];
  selected: Member | null;
  allowNone: boolean;
  onClose: () => void;
  onSelect: (member: Member | null) => void;
}) {
  const [search, setSearch] = useState("");
  const filtered = members.filter((member) =>
    member.member_name.toLowerCase().includes(search.trim().toLowerCase())
  );

  useEffect(() => {
    const body = document.body;
    const previousOverflow = body.style.overflow;
    body.style.overflow = "hidden";
    body.classList.add("modal-open");
    return () => {
      body.style.overflow = previousOverflow;
      body.classList.remove("modal-open");
    };
  }, []);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="modal-surface relative z-10 w-full max-w-lg rounded-3xl p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-rf-text">View as</h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted"
          >
            Done
          </button>
        </div>
        <div className="mt-4">
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search member"
            className="input-shell w-full rounded-2xl px-4 py-3 text-sm font-medium"
          />
        </div>
        <div className="mt-4 max-h-72 overflow-auto">
          {allowNone && (
            <button
              type="button"
              onClick={() => onSelect(null)}
              className={`flex w-full items-center justify-between px-3 py-2 text-left text-sm font-semibold ${
                selected === null ? "text-rf-text" : "text-rf-text-muted"
              }`}
            >
              None
            </button>
          )}
          {filtered.map((member) => (
            <button
              key={member.id}
              type="button"
              onClick={() => onSelect(member)}
              className="flex w-full items-center justify-between px-3 py-2 text-left text-sm font-semibold text-rf-text"
            >
              <span>{member.member_name}</span>
              {selected?.id === member.id && <span className="text-rf-accent">✓</span>}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((part) => part[0]?.toUpperCase())
    .slice(0, 2)
    .join("");
}

function sleepLabel(value: number | null) {
  if (value === null || value === undefined) return "—";
  return `${value.toFixed(1)} hrs`;
}

function dietLabel(value: number | null) {
  if (value === null || value === undefined) return "—";
  return `${value}/5`;
}

function FlameIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path
        d="M10 2.8c1.6 2 1.2 3.6.2 4.8-1.1 1.4-2.7 2.1-2.7 4a2.9 2.9 0 0 0 5.8 0c0-1.8-.8-3.1-1.6-4.2-.5-.7-1-1.4-1.7-2.6z"
        strokeLinejoin="round"
      />
      <path
        d="M6.5 12.6c-.1 2.8 2 4.6 3.5 4.6 1.6 0 3.7-1.8 3.6-4.6"
        strokeLinecap="round"
      />
    </svg>
  );
}

function MailIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="3" y="5" width="14" height="10" rx="2" />
      <path d="M4 6l6 4 6-4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
