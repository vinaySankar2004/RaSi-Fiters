"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { fetchDistributionByDay } from "@/lib/api/summary";
import { BackButton } from "@/components/BackButton";
import { useActiveProgram } from "@/lib/use-active-program";

export default function DistributionPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = useActiveProgram();

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

  const distributionQuery = useQuery({
    queryKey: ["summary", "distribution", program?.id],
    queryFn: () => fetchDistributionByDay(session?.token ?? "", program?.id ?? ""),
    enabled: !!session?.token && !!program?.id
  });

  const data = distributionQuery.data
    ? [
        { day: "Sun", value: distributionQuery.data.Sunday },
        { day: "Mon", value: distributionQuery.data.Monday },
        { day: "Tue", value: distributionQuery.data.Tuesday },
        { day: "Wed", value: distributionQuery.data.Wednesday },
        { day: "Thu", value: distributionQuery.data.Thursday },
        { day: "Fri", value: distributionQuery.data.Friday },
        { day: "Sat", value: distributionQuery.data.Saturday }
      ]
    : [];

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/summary" />
          <div>
            <h1 className="text-2xl font-bold">Workout Distribution by Day</h1>
            <p className="mt-2 text-sm text-rf-text-muted">Workouts</p>
          </div>
        </header>

        {distributionQuery.isLoading && (
          <div className="rounded-2xl bg-rf-surface-muted px-4 py-10 text-center text-sm text-rf-text-muted">
            Loading distribution...
          </div>
        )}

        {distributionQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(distributionQuery.error as Error).message}
          </div>
        )}

        {distributionQuery.data && (
          <div className="glass-card rounded-3xl p-6">
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
                  <XAxis dataKey="day" tick={{ fontSize: 11, fill: "var(--rf-text-muted)" }} />
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
                  <Bar dataKey="value" fill="#f59e0b" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
