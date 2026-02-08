"use client";

export const dynamic = "force-dynamic";

import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMemberStreaks } from "@/lib/api/members";
import { BackButton } from "@/components/BackButton";

export default function MemberStreaksPage() {
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

  const streaksQuery = useQuery({
    queryKey: ["members", "streaks", programId, memberId],
    queryFn: () => fetchMemberStreaks(token, programId, memberId),
    enabled: !!token && !!programId && !!memberId
  });

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members" />
          <div>
            <h1 className="text-2xl font-bold">Streak Stats</h1>
            <p className="text-sm text-rf-text-muted">{memberName}</p>
          </div>
        </header>

        {streaksQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading streaks...</div>
        )}

        {streaksQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(streaksQuery.error as Error).message}
          </div>
        )}

        {streaksQuery.data && (
          <div className="glass-card rounded-3xl p-6">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="metric-pill rounded-2xl px-4 py-4">
                <p className="text-xs text-rf-text-muted">Current</p>
                <p className="text-xl font-semibold text-rf-text">
                  {streaksQuery.data.currentStreakDays} days
                </p>
              </div>
              <div className="metric-pill rounded-2xl px-4 py-4">
                <p className="text-xs text-rf-text-muted">Longest</p>
                <p className="text-xl font-semibold text-rf-text">
                  {streaksQuery.data.longestStreakDays} days
                </p>
              </div>
            </div>

            <div className="mt-6">
              <p className="text-sm font-semibold text-rf-text">Milestones</p>
              <div className="mt-3 flex flex-wrap gap-2">
                {streaksQuery.data.milestones.map((milestone) => (
                  <span
                    key={milestone.dayValue}
                    className={`metric-pill rounded-full px-3 py-1 text-xs font-semibold ${
                      milestone.achieved ? "text-rf-accent" : "text-rf-text-muted"
                    }`}
                  >
                    {milestone.dayValue}d
                  </span>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
