"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { saveActiveProgram } from "@/lib/storage";
import { updateProgram } from "@/lib/api/programs";
import { Select } from "@/components/Select";
import { useAuthGuard } from "@/lib/hooks/use-auth-guard";
import { PageShell } from "@/components/ui/PageShell";
import { PageHeader } from "@/components/ui/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";

const STATUS_OPTIONS = [
  { value: "planned", label: "Planned" },
  { value: "active", label: "Active" },
  { value: "completed", label: "Completed" }
];

export default function ProgramEditPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { session, program, token, programId } = useAuthGuard();
  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;

  const [name, setName] = useState("");
  const [status, setStatus] = useState("active");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [adminOnlyDataEntry, setAdminOnlyDataEntry] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (program?.id && !isProgramAdmin) {
      router.push("/program");
    }
  }, [program?.id, isProgramAdmin, router]);

  useEffect(() => {
    if (!program) return;
    setName(program.name ?? "");
    setStatus(program.status ?? "active");
    setStartDate(program.start_date ?? "");
    setEndDate(program.end_date ?? "");
    setAdminOnlyDataEntry(!!program.admin_only_data_entry);
  }, [program]);

  const updateMutation = useMutation({
    mutationFn: () =>
      updateProgram(token, programId, {
        name: name.trim(),
        status,
        start_date: startDate || null,
        end_date: endDate || null,
        admin_only_data_entry: adminOnlyDataEntry
      }),
    onSuccess: async () => {
      saveActiveProgram({
        id: programId,
        name: name.trim(),
        status,
        start_date: startDate || null,
        end_date: endDate || null,
        my_role: program?.my_role ?? null,
        my_status: program?.my_status ?? null,
        admin_only_data_entry: adminOnlyDataEntry
      });
      await queryClient.invalidateQueries({ queryKey: ["programs"] });
      router.push("/program");
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to update program.");
    }
  });

  const canSave = name.trim().length > 0 && !updateMutation.isPending;

  return (
    <PageShell maxWidth="2xl">
      <PageHeader
        title="Edit Program"
        subtitle="Update the program details."
        backHref="/program"
      />

      <GlassCard padding="lg" className="space-y-5">
        <div>
          <label className="text-sm font-semibold text-rf-text">Program name</label>
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
            className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
            placeholder="Program name"
          />
        </div>

        <Select
          label="Status"
          value={status}
          options={STATUS_OPTIONS}
          onChange={setStatus}
        />

        <div className="grid gap-4 sm:grid-cols-2">
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
        </div>

        <div className="subtle-divider" />

        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-sm font-semibold text-rf-text">Admin-only data entry</p>
            <p className="mt-1 text-xs text-rf-text-muted">
              When on, only admins can add, edit, or delete workouts and health logs. Loggers and members
              are blocked.
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={adminOnlyDataEntry}
            aria-label="Admin-only data entry"
            onClick={() => setAdminOnlyDataEntry((value) => !value)}
            className={`relative mt-0.5 inline-flex h-7 w-12 shrink-0 items-center rounded-full transition-colors ${
              adminOnlyDataEntry ? "bg-rf-accent" : "bg-rf-border"
            }`}
          >
            <span
              className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform ${
                adminOnlyDataEntry ? "translate-x-6" : "translate-x-1"
              }`}
            />
          </button>
        </div>

        {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}

        <button
          type="button"
          disabled={!canSave}
          onClick={() => {
            setErrorMessage(null);
            updateMutation.mutate();
          }}
          className="w-full rounded-2xl bg-rf-accent px-4 py-3 text-sm font-semibold text-black disabled:opacity-50"
        >
          {updateMutation.isPending ? "Saving..." : "Save changes"}
        </button>
      </GlassCard>
    </PageShell>
  );
}
