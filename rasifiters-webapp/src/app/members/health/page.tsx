"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMemberHealthLogs, type MemberHealthItem } from "@/lib/api/members";
import { deleteDailyHealthLog, updateDailyHealthLog } from "@/lib/api/logs";
import { Select } from "@/components/Select";
import { formatShortDate } from "@/lib/format";
import { BackButton } from "@/components/BackButton";

const SORT_FIELDS = [
  { value: "date", label: "Date" },
  { value: "sleep_hours", label: "Sleep hours" },
  { value: "food_quality", label: "Diet quality" }
];

const SORT_DIRS = [
  { value: "desc", label: "Descending" },
  { value: "asc", label: "Ascending" }
];

const DIET_OPTIONS = ["", "1", "2", "3", "4", "5"].map((value) => ({
  value,
  label: value ? `${value}` : "Not set"
}));

export default function MemberHealthPage() {
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
  const isProgramAdmin = program?.my_role === "admin" || program?.my_role === "logger";
  const loggedInUserId = session?.user.id;
  const canViewAny = isGlobalAdmin || isProgramAdmin;
  const canEdit = canViewAny || memberId === loggedInUserId;

  const [sortField, setSortField] = useState("date");
  const [sortDir, setSortDir] = useState("desc");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [showFilter, setShowFilter] = useState(false);
  const [editTarget, setEditTarget] = useState<MemberHealthItem | null>(null);
  const [editSleep, setEditSleep] = useState("");
  const [editDiet, setEditDiet] = useState("");
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

  const healthQuery = useQuery({
    queryKey: ["members", "health", programId, memberId, sortField, sortDir, startDate, endDate],
    queryFn: () =>
      fetchMemberHealthLogs(token, programId, memberId, {
        limit: 0,
        sortBy: sortField,
        sortDir,
        startDate: startDate || undefined,
        endDate: endDate || undefined
      }),
    enabled: !!token && !!programId && !!memberId
  });

  const updateMutation = useMutation({
    mutationFn: (payload: { sleep_hours?: number | null; food_quality?: number | null }) =>
      updateDailyHealthLog(token, {
        program_id: programId,
        member_id: memberId,
        log_date: editTarget?.logDate ?? "",
        ...payload
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["members", "health", programId, memberId] });
      setEditTarget(null);
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to update daily health log.");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (item: MemberHealthItem) =>
      deleteDailyHealthLog(token, {
        program_id: programId,
        member_id: memberId,
        log_date: item.logDate
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["members", "health", programId, memberId] });
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to delete daily health log.");
    }
  });

  const formattedFilters = useMemo(() => {
    if (!startDate && !endDate) return null;
    return `${startDate || "Start"} – ${endDate || "End"}`;
  }, [startDate, endDate]);

  const handleExport = () => {
    if (!healthQuery.data || healthQuery.data.items.length === 0) return;
    const filename = `Health_${memberName.replace(/\s+/g, "")}_${startDate || "all"}_to_${endDate || "today"}.csv`;
    let csv = "Date,Sleep hours,Diet quality\n";
    healthQuery.data.items.forEach((item) => {
      csv += `${item.logDate},${item.sleepHours ?? ""},${item.foodQuality ?? ""}\n`;
    });
    downloadCsv(filename, csv);
  };

  const openEdit = (item: MemberHealthItem) => {
    setEditTarget(item);
    setEditSleep(item.sleepHours !== null && item.sleepHours !== undefined ? String(item.sleepHours) : "");
    setEditDiet(item.foodQuality !== null && item.foodQuality !== undefined ? String(item.foodQuality) : "");
    setErrorMessage(null);
  };

  const submitEdit = () => {
    if (!editTarget) return;
    const sleepValue = editSleep.trim() === "" ? null : Number(editSleep);
    const dietValue = editDiet.trim() === "" ? null : Number(editDiet);
    if (
      (sleepValue === null || Number.isNaN(sleepValue)) &&
      (dietValue === null || Number.isNaN(dietValue))
    ) {
      setErrorMessage("Provide sleep hours or diet quality before saving.");
      return;
    }
    updateMutation.mutate({
      sleep_hours: Number.isNaN(sleepValue) ? null : sleepValue,
      food_quality: Number.isNaN(dietValue) ? null : dietValue
    });
  };

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members" />
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold">View Health</h1>
              <p className="text-sm text-rf-text-muted">{memberName}</p>
            </div>
            <button
              type="button"
              onClick={handleExport}
              disabled={!healthQuery.data || healthQuery.data.items.length === 0}
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

        {healthQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading daily health logs...</div>
        )}

        {healthQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(healthQuery.error as Error).message}
          </div>
        )}

        {healthQuery.data && healthQuery.data.items.length === 0 && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">No daily health logs found.</div>
        )}

        {healthQuery.data && healthQuery.data.items.length > 0 && (
          <div className="grid gap-3">
            {healthQuery.data.items.map((item) => (
              <div key={item.id} className="glass-card rounded-3xl p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-base font-semibold text-rf-text">Sleep {sleepLabel(item.sleepHours)}</p>
                    <p className="text-xs text-rf-text-muted">{item.logDate}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-rf-text">Diet {dietLabel(item.foodQuality)}</p>
                  </div>
                </div>
                {canEdit && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    <button
                      type="button"
                      onClick={() => openEdit(item)}
                      className="rounded-full bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        const confirmed = window.confirm("Delete this daily health log?");
                        if (!confirmed) return;
                        deleteMutation.mutate(item);
                      }}
                      className="rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-600"
                    >
                      Delete
                    </button>
                  </div>
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

      <Modal open={!!editTarget} onClose={() => setEditTarget(null)}>
        {editTarget && (
          <div className="modal-surface w-full max-w-md rounded-3xl p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-rf-text">Edit Daily Health</h2>
              <button
                type="button"
                onClick={() => setEditTarget(null)}
                className="rounded-full bg-rf-surface-muted px-3 py-1 text-xs font-semibold text-rf-text-muted"
              >
                Close
              </button>
            </div>
            <div className="mt-4 space-y-4">
              <div>
                <label className="text-sm font-semibold text-rf-text">Date</label>
                <input
                  type="date"
                  value={editTarget.logDate}
                  disabled
                  className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium opacity-60"
                />
              </div>
              <div>
                <label className="text-sm font-semibold text-rf-text">Sleep hours</label>
                <input
                  type="number"
                  step="0.1"
                  min="0"
                  max="24"
                  value={editSleep}
                  onChange={(event) => setEditSleep(event.target.value)}
                  placeholder="e.g. 7.5"
                  className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
                />
              </div>
              <Select
                label="Diet quality"
                value={editDiet}
                options={DIET_OPTIONS}
                onChange={setEditDiet}
                placeholder="Select Rating (1-5)"
              />
            </div>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setEditTarget(null)}
                className="rounded-full bg-rf-surface-muted px-4 py-2 text-xs font-semibold text-rf-text-muted"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={submitEdit}
                disabled={updateMutation.isPending}
                className="button-primary rounded-full px-5 py-2 text-xs font-semibold"
              >
                Save
              </button>
            </div>
          </div>
        )}
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

function sleepLabel(value: number | null) {
  if (value === null || value === undefined) return "—";
  return `${value.toFixed(1)} hrs`;
}

function dietLabel(value: number | null) {
  if (value === null || value === undefined) return "—";
  return `${value}/5`;
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
