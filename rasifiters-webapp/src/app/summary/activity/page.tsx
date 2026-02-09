"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { fetchActivityTimeline } from "@/lib/api/summary";
import { BackButton } from "@/components/BackButton";
import { useActiveProgram } from "@/lib/use-active-program";

type PeriodKey = "week" | "month" | "year" | "program";

const PERIODS: { key: PeriodKey; label: string }[] = [
  { key: "week", label: "W" },
  { key: "month", label: "M" },
  { key: "year", label: "Y" },
  { key: "program", label: "P" }
];

export default function ActivityTimelinePage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = useActiveProgram();
  const [period, setPeriod] = useState<PeriodKey>("week");

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

  const timelineQuery = useQuery({
    queryKey: ["summary", "timeline", program?.id, period],
    queryFn: () => fetchActivityTimeline(session?.token ?? "", period, program?.id ?? ""),
    enabled: !!session?.token && !!program?.id
  });

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/summary" />
          <div>
            <h1 className="text-2xl font-bold">Workout Activity Timeline</h1>
            <p className="mt-2 text-sm text-rf-text-muted">Workouts · Active members</p>
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

        {timelineQuery.isLoading && (
          <div className="rounded-2xl bg-rf-surface-muted px-4 py-10 text-center text-sm text-rf-text-muted">
            Loading timeline...
          </div>
        )}

        {timelineQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(timelineQuery.error as Error).message}
          </div>
        )}

        {timelineQuery.data && (
          <div className="glass-card rounded-3xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-rf-text-muted">Range</p>
                <p className="text-lg font-semibold text-rf-text">{timelineQuery.data.label}</p>
              </div>
              <div className="text-right">
                <p className="text-xs text-rf-text-muted">Daily avg</p>
                <p className="text-base font-semibold text-rf-text">
                  {timelineQuery.data.daily_average.toFixed(1)}
                </p>
              </div>
            </div>

            <div className="mt-6 h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={timelineQuery.data.buckets}>
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
                    formatter={(value: number, name: string) => [
                      value,
                      name === "workouts" ? "Workouts" : "Active members"
                    ]}
                  />
                  <Bar dataKey="workouts" fill="#ff8b1f" radius={[8, 8, 0, 0]} />
                  <Bar dataKey="active_members" fill="#60a5fa" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
