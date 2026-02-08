"use client";

export const dynamic = "force-dynamic";

import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMemberRecentWorkouts, type MemberRecentItem } from "@/lib/api/members";
import { deleteWorkoutLog } from "@/lib/api/logs";
import { Select } from "@/components/Select";
import { BackButton } from "@/components/BackButton";

const SORT_FIELDS = [
  { value: "date", label: "Date" },
  { value: "duration", label: "Duration" },
  { value: "workoutType", label: "Workout Type" }
];

const SORT_DIRS = [
  { value: "desc", label: "Descending" },
  { value: "asc", label: "Ascending" }
];

export default function MemberWorkoutsPage() {
  const router = useRouter();
  const params = useSearchParams();
  const memberId = params.get("memberId") ?? "";
  const memberName = params.get("name") ?? "Member";
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const programId = program?.id ?? "";
  const queryClient = useQueryClient();

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const canViewAny = isGlobalAdmin || program?.my_role === "admin" || program?.my_role === "logger";
  const loggedInUserId = session?.user.id;
  const canDelete = isGlobalAdmin || memberId === loggedInUserId;

  const [sortField, setSortField] = useState("date");
  const [sortDir, setSortDir] = useState("desc");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [showFilter, setShowFilter] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

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

  const workoutsQuery = useQuery({
    queryKey: ["members", "workouts", programId, memberId, sortField, sortDir, startDate, endDate],
    queryFn: () =>
      fetchMemberRecentWorkouts(token, programId, memberId, {
        limit: 0,
        sortBy: sortField,
        sortDir,
        startDate: startDate || undefined,
        endDate: endDate || undefined
      }),
    enabled: !!token && !!programId && !!memberId
  });

  const deleteMutation = useMutation({
    mutationFn: (item: MemberRecentItem) =>
      deleteWorkoutLog(token, {
        program_id: programId,
        member_id: memberId,
        workout_name: item.workoutType,
        date: item.workoutDate
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["members", "workouts", programId, memberId] });
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to delete workout.");
    }
  });

  const handleExport = () => {
    if (!workoutsQuery.data || workoutsQuery.data.items.length === 0) return;
    const filename = `Workouts_${memberName.replace(/\s+/g, "")}_${startDate || "all"}_to_${endDate || "today"}.csv`;
    let csv = "Workout Type,Date,Duration (min)\n";
    workoutsQuery.data.items.forEach((item) => {
      csv += `${escapeCsv(item.workoutType)},${item.workoutDate},${item.durationMinutes}\n`;
    });
    downloadCsv(filename, csv);
  };

  const formattedFilters = useMemo(() => {
    if (!startDate && !endDate) return null;
    return `${startDate || "Start"} – ${endDate || "End"}`;
  }, [startDate, endDate]);

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members" />
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold">View Workouts</h1>
              <p className="text-sm text-rf-text-muted">{memberName}</p>
            </div>
            <button
              type="button"
              onClick={handleExport}
              disabled={!workoutsQuery.data || workoutsQuery.data.items.length === 0}
              className="pill-button rounded-full px-4 py-2 text-xs font-semibold transition disabled:opacity-40"
            >
              Export CSV
            </button>
          </div>
        </header>

        <div className="glass-card relative z-30 rounded-3xl p-5">
          <div className="grid gap-4 md:grid-cols-[1fr,200px,200px,140px]">
            <Select value={sortField} options={SORT_FIELDS} onChange={setSortField} placeholder="Sort" />
            <Select value={sortDir} options={SORT_DIRS} onChange={setSortDir} placeholder="Direction" />
            <button
              type="button"
              onClick={() => setShowFilter(true)}
              className="mt-2 rounded-2xl bg-rf-surface-muted px-4 py-3 text-sm font-semibold text-rf-text-muted"
            >
              Filter
            </button>
            {formattedFilters && (
              <div className="rounded-2xl bg-rf-surface-muted px-4 py-3 text-xs text-rf-text-muted">
                {formattedFilters}
              </div>
            )}
          </div>
        </div>

        {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}

        {workoutsQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading workouts...</div>
        )}

        {workoutsQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(workoutsQuery.error as Error).message}
          </div>
        )}

        {workoutsQuery.data && workoutsQuery.data.items.length === 0 && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">No workouts found.</div>
        )}

        {workoutsQuery.data && workoutsQuery.data.items.length > 0 && (
          <div className="grid gap-3">
            {workoutsQuery.data.items.map((item) => (
              <div key={item.id} className="glass-card rounded-3xl p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-base font-semibold text-rf-text">{item.workoutType}</p>
                    <p className="text-xs text-rf-text-muted">{item.workoutDate}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-rf-text">{item.durationMinutes} min</p>
                  </div>
                </div>
                {canDelete && (
                  <button
                    type="button"
                    onClick={() => {
                      const confirmed = window.confirm("Delete this workout log?");
                      if (!confirmed) return;
                      deleteMutation.mutate(item);
                    }}
                    className="mt-3 rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-600"
                  >
                    Delete
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <Modal open={showFilter} onClose={() => setShowFilter(false)}>
        <div className="modal-surface w-full max-w-md rounded-3xl p-6">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-rf-text">Filter</h2>
            <button
              type="button"
              onClick={() => setShowFilter(false)}
              className="rounded-full bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted"
            >
              Done
            </button>
          </div>
          <div className="mt-4 space-y-4">
            <div>
              <label className="text-sm font-semibold text-rf-text">Start date</label>
              <input
                type="date"
                value={startDate}
                onChange={(event) => setStartDate(event.target.value)}
                className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
              />
            </div>
            <div>
              <label className="text-sm font-semibold text-rf-text">End date</label>
              <input
                type="date"
                value={endDate}
                onChange={(event) => setEndDate(event.target.value)}
                className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
              />
            </div>
            <button
              type="button"
              onClick={() => {
                setStartDate("");
                setEndDate("");
              }}
              className="rounded-full bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted"
            >
              Clear dates
            </button>
          </div>
        </div>
      </Modal>
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
      <div className="relative z-10 flex w-full justify-center overflow-visible">{children}</div>
    </div>
  );
}

function escapeCsv(value: string) {
  return `"${value.replace(/"/g, '""')}"`;
}

function downloadCsv(filename: string, data: string) {
  const blob = new Blob([data], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}
