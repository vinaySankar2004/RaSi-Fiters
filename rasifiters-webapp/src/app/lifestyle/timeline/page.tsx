"use client";

export const dynamic = "force-dynamic";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bar, CartesianGrid, ComposedChart, Line, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchHealthTimeline } from "@/lib/api/lifestyle";
import { BackButton } from "@/components/BackButton";
import { useClientSearchParams } from "@/lib/use-client-search-params";

type PeriodKey = "week" | "month" | "year" | "program";

const PERIODS: { key: PeriodKey; label: string }[] = [
  { key: "week", label: "W" },
  { key: "month", label: "M" },
  { key: "year", label: "Y" },
  { key: "program", label: "P" }
];

export default function LifestyleTimelinePage() {
  const router = useRouter();
  const params = useClientSearchParams();
  const memberIdParam = params.get("memberId");
  const { session, isBootstrapping } = useAuth();
  const program = loadActiveProgram();
  const programId = program?.id ?? "";

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;
  const canViewAs = isProgramAdmin;

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

  const resolvedMemberId = useMemo(() => {
    if (memberIdParam) return memberIdParam;
    if (canViewAs) return undefined;
    return session?.user.id;
  }, [memberIdParam, canViewAs, session?.user.id]);

  const timelineQuery = useQuery({
    queryKey: ["lifestyle", "timeline", programId, resolvedMemberId ?? "program", period],
    queryFn: () => fetchHealthTimeline(session?.token ?? "", period, programId, resolvedMemberId),
    enabled: !!session?.token && !!programId && (!!resolvedMemberId || canViewAs)
  });

  const points = timelineQuery.data?.buckets ?? [];
  const yMax = Math.max(1, ...points.map((point) => Math.max(point.sleep_hours, point.food_quality)));

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/lifestyle" />
          <div>
            <h1 className="text-2xl font-bold">Lifestyle Timeline</h1>
            <p className="mt-2 text-sm text-rf-text-muted">Sleep · Diet quality</p>
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
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="text-sm font-semibold text-rf-text-muted">Range</p>
                <p className="text-lg font-semibold text-rf-text">{timelineQuery.data.label}</p>
              </div>
              <div className="flex items-center gap-6 text-right">
                <div>
                  <p className="text-xs text-rf-text-muted">Daily avg sleep</p>
                  <p className="text-base font-semibold text-rf-text">
                    {timelineQuery.data.daily_average_sleep.toFixed(1)} hrs
                  </p>
                </div>
                <div>
                  <p className="text-xs text-rf-text-muted">Daily avg diet</p>
                  <p className="text-base font-semibold text-rf-text">
                    {timelineQuery.data.daily_average_food.toFixed(1)} / 5
                  </p>
                </div>
              </div>
            </div>

            <div className="mt-6 h-72">
              {points.length === 0 ? (
                <div className="rounded-2xl bg-rf-surface-muted px-4 py-10 text-center text-sm text-rf-text-muted">
                  No data for this range yet.
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={points}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
                    <XAxis dataKey="label" tick={{ fontSize: 10, fill: "var(--rf-text-muted)" }} />
                    <YAxis domain={[0, yMax * 1.1]} tick={{ fontSize: 11, fill: "var(--rf-text-muted)" }} />
                    <Tooltip
                      contentStyle={{
                        borderRadius: 12,
                        border: "1px solid var(--rf-border)",
                        backgroundColor: "var(--rf-surface)",
                        color: "var(--rf-text)",
                        boxShadow: "0 14px 24px rgba(0, 0, 0, 0.25)"
                      }}
                      labelStyle={{ color: "var(--rf-text-muted)" }}
                      formatter={(value: number, name: string) => {
                        if (name === "sleep_hours") return [`${value} hrs`, "Sleep"];
                        return [`${value} / 5`, "Diet"];
                      }}
                    />
                    <Bar dataKey="sleep_hours" fill="#60a5fa" radius={[8, 8, 0, 0]} />
                    <Line type="monotone" dataKey="food_quality" stroke="#22c55e" strokeWidth={2} dot={{ r: 3 }} />
                  </ComposedChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
