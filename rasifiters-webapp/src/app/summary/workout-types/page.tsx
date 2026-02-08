"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchWorkoutTypes } from "@/lib/api/summary";
import { BackButton } from "@/components/BackButton";

export default function WorkoutTypesPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = loadActiveProgram();

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

  const typesQuery = useQuery({
    queryKey: ["summary", "workoutTypes", program?.id],
    queryFn: () => fetchWorkoutTypes(session?.token ?? "", program?.id ?? "", 100),
    enabled: !!session?.token && !!program?.id
  });

  const data = typesQuery.data ?? [];

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/summary" />
          <div>
            <h1 className="text-2xl font-bold">Workout Types</h1>
            <p className="mt-2 text-sm text-rf-text-muted">Program to date</p>
          </div>
        </header>

        {typesQuery.isLoading && (
          <div className="rounded-2xl bg-rf-surface-muted px-4 py-10 text-center text-sm text-rf-text-muted">
            Loading workout types...
          </div>
        )}

        {typesQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(typesQuery.error as Error).message}
          </div>
        )}

        {typesQuery.data && (
          <div className="glass-card rounded-3xl p-6">
            {data.length === 0 ? (
              <p className="text-sm text-rf-text-muted">No workouts logged yet.</p>
            ) : (
              <>
                <div className="h-80">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={data}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--rf-border)" />
                      <XAxis dataKey="workout_name" tick={false} axisLine={false} tickLine={false} />
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
                        formatter={(value: number) => [value, "Sessions"]}
                      />
                      <Bar dataKey="sessions" fill="#ff8b1f" radius={[8, 8, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>

                <ul className="mt-6 space-y-2 text-sm">
                  {data.map((type) => (
                    <li key={type.workout_name} className="flex items-center justify-between">
                      <span className="font-semibold text-rf-text">{type.workout_name}</span>
                      <span className="text-rf-text-muted">
                        {type.sessions} sessions · avg {type.avg_duration_minutes} min
                      </span>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
