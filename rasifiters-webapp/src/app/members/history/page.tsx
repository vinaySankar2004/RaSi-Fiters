"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMemberHistory } from "@/lib/api/members";
import { BackButton } from "@/components/BackButton";

const PERIODS = [
  { key: "week", label: "W" },
  { key: "month", label: "M" },
  { key: "year", label: "Y" },
  { key: "program", label: "P" }
];

export default function MemberHistoryPage() {
  const router = useRouter();
  const params = useSearchParams();
  const memberId = params.get("memberId") ?? "";
  const memberName = params.get("name") ?? "Member";
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const programId = program?.id ?? "";
  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const canViewAny = isGlobalAdmin || program?.my_role === "admin" || program?.my_role === "logger";
  const loggedInUserId = session?.user.id;
  const [period, setPeriod] = useState("week");

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

  useEffect(() => {
    if (!memberId) return;
    if (!canViewAny && memberId !== loggedInUserId) {
      router.push("/members");
    }
  }, [memberId, canViewAny, loggedInUserId, router]);

  const historyQuery = useQuery({
    queryKey: ["members", "history", programId, memberId, period],
    queryFn: () => fetchMemberHistory(token, programId, memberId, period),
    enabled: !!token && !!programId && !!memberId
  });

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members" />
          <div>
            <h1 className="text-2xl font-bold">Workout History</h1>
            <p className="text-sm text-rf-text-muted">{memberName}</p>
          </div>
        </header>

        <div className="segmented-control flex rounded-full p-1">
          {PERIODS.map((item) => (
            <button
              key={item.key}
              onClick={() => setPeriod(item.key)}
              data-active={period === item.key}
              className="flex-1 rounded-full px-3 py-2 text-sm font-semibold transition"
            >
              {item.label}
            </button>
          ))}
        </div>

        {historyQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading timeline...</div>
        )}

        {historyQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(historyQuery.error as Error).message}
          </div>
        )}

        {historyQuery.data && (
          <div className="glass-card rounded-3xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-rf-text-muted">Range</p>
                <p className="text-lg font-semibold text-rf-text">{historyQuery.data.label}</p>
              </div>
              <div className="text-right">
                <p className="text-xs text-rf-text-muted">Daily avg</p>
                <p className="text-base font-semibold text-rf-text">
                  {historyQuery.data.daily_average.toFixed(1)}
                </p>
              </div>
            </div>
            <div className="mt-6 h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={historyQuery.data.buckets}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: "var(--rf-text-muted)" }} />
                  <YAxis tick={{ fontSize: 11, fill: "var(--rf-text-muted)" }} />
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
          </div>
        )}
      </div>
    </div>
  );
}
