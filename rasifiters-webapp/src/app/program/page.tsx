"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { clearActiveProgram } from "@/lib/storage";
import { fetchMembershipDetails, leaveProgram, type MembershipDetail } from "@/lib/api/programs";
import { fetchProgramWorkouts } from "@/lib/api/program-workouts";
import { formatDateRange } from "@/lib/format";
import { useActiveProgram } from "@/lib/use-active-program";

export default function ProgramPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { session, isBootstrapping, signOut } = useAuth();
  const token = session?.token ?? "";
  const program = useActiveProgram();
  const programId = program?.id ?? "";

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;
  const canInvite = isProgramAdmin;
  const canManageRoles = isProgramAdmin;
  const canLeaveProgram = !isGlobalAdmin;

  const [showLeaveConfirm, setShowLeaveConfirm] = useState(false);

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

  const membershipQuery = useQuery({
    queryKey: ["program", "membership-details", programId],
    queryFn: () => fetchMembershipDetails(token, programId),
    enabled: !!token && !!programId
  });

  const workoutsQuery = useQuery({
    queryKey: ["program", "workouts", programId],
    queryFn: () => fetchProgramWorkouts(token, programId),
    enabled: !!token && !!programId
  });

  const leaveMutation = useMutation({
    mutationFn: () => leaveProgram(token, programId),
    onSuccess: async () => {
      clearActiveProgram();
      await queryClient.invalidateQueries({ queryKey: ["programs"] });
      router.push("/programs");
    }
  });

  const initials = useMemo(() => {
    const name = session?.user.memberName ?? session?.user.username ?? "U";
    return name
      .split(" ")
      .filter(Boolean)
      .map((part) => part[0]?.toUpperCase())
      .slice(0, 2)
      .join("");
  }, [session?.user.memberName, session?.user.username]);

  const membershipDetails = membershipQuery.data ?? [];
  const activeMembers = membershipDetails.filter((member) => member.is_active).length;

  const admins = membershipDetails.filter((member) => member.program_role === "admin");
  const loggers = membershipDetails.filter((member) => member.program_role === "logger");

  const workoutData = workoutsQuery.data ?? [];
  const visibleWorkouts = workoutData.filter((workout) => !workout.is_hidden);
  const customWorkouts = workoutData.filter((workout) => workout.source === "custom");

  const progress = useMemo(() => {
    return computeProgramProgress(program?.start_date ?? null, program?.end_date ?? null);
  }, [program?.start_date, program?.end_date]);

  const errorMessage = leaveMutation.isError ? (leaveMutation.error as Error).message : null;

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <header className="flex items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-rf-text">Program</h1>
            <p className="mt-1 text-sm font-semibold text-rf-text-muted">{program?.name ?? "Program"}</p>
          </div>
          <div className="ml-auto flex h-12 w-12 items-center justify-center rounded-full bg-rf-accent text-base font-bold text-black">
            {initials || "RF"}
          </div>
        </header>

        {errorMessage && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {errorMessage}
          </div>
        )}

        {isProgramAdmin ? (
          <div className="space-y-5">
            <SectionCard title="Program Info" icon={<IconInfo className="h-4 w-4" />}>
              <div className="space-y-3">
                <button
                  type="button"
                  onClick={() => router.push("/programs")}
                  className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
                    ⇄
                  </span>
                  <div>
                    <p>Select Program</p>
                    <p className="text-xs text-rf-text-muted">Switch to a different program</p>
                  </div>
                  <span className="ml-auto text-rf-text-muted">›</span>
                </button>

                <button
                  type="button"
                  onClick={() => router.push("/program/edit")}
                  className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600">
                    ✎
                  </span>
                  <div>
                    <p>Edit Program Details</p>
                    <p className="text-xs text-rf-text-muted">
                      {(program?.status ?? "active").toUpperCase()} • {formatDateRange(program?.start_date, program?.end_date)}
                    </p>
                  </div>
                  <span className="ml-auto text-rf-text-muted">›</span>
                </button>
              </div>
            </SectionCard>

            <SectionCard title="Members" icon={<IconUsers className="h-4 w-4" />}>
              <div className="space-y-3">
                <button
                  type="button"
                  onClick={() => router.push("/members/list")}
                  className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                >
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                      <IconUser className="h-5 w-5" />
                    </span>
                  <div>
                    <p>View Members</p>
                    <p className="text-xs text-rf-text-muted">
                      {membershipQuery.isLoading ? "Loading..." : `${activeMembers} active`}
                    </p>
                  </div>
                  <span className="ml-auto text-rf-text-muted">›</span>
                </button>

                {canInvite && (
                  <button
                    type="button"
                    onClick={() => router.push("/members/invite")}
                    className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                  >
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600">
                      <IconMail className="h-5 w-5" />
                    </span>
                    <div>
                      <p>Invite Member</p>
                      <p className="text-xs text-rf-text-muted">Send program invitation</p>
                    </div>
                    <span className="ml-auto text-rf-text-muted">›</span>
                  </button>
                )}
              </div>
            </SectionCard>

            {canManageRoles && (
              <SectionCard title="Role Management" icon={<IconKey className="h-4 w-4" />}>
                <div className="space-y-4">
                  {membershipQuery.isLoading && (
                    <div className="rounded-2xl bg-rf-surface-muted px-4 py-3 text-sm text-rf-text-muted">
                      Loading roles...
                    </div>
                  )}

                  {!membershipQuery.isLoading && admins.length === 0 && loggers.length === 0 && (
                    <div className="rounded-2xl bg-rf-surface-muted px-4 py-3 text-sm text-rf-text-muted">
                      No admins or loggers assigned.
                    </div>
                  )}

                  {admins.length > 0 && (
                    <RoleList title="Admins" members={admins} accent="text-amber-600" />
                  )}

                  {loggers.length > 0 && (
                    <RoleList title="Loggers" members={loggers} accent="text-blue-600" />
                  )}

                  <button
                    type="button"
                    onClick={() => router.push("/program/roles")}
                    className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                  >
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 text-purple-600">
                      <IconSettings className="h-5 w-5" />
                    </span>
                    <div>
                      <p>Manage Roles</p>
                      <p className="text-xs text-rf-text-muted">Set admin, logger, or member roles</p>
                    </div>
                    <span className="ml-auto text-rf-text-muted">›</span>
                  </button>
                </div>
              </SectionCard>
            )}

            <SectionCard title="Workout Types" icon={<IconDumbbell className="h-4 w-4" />}>
              <div className="space-y-3">
                <button
                  type="button"
                  onClick={() => router.push("/lifestyle/workouts")}
                  className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 text-purple-600">
                    ☰
                  </span>
                  <div>
                    <p>Workout Types</p>
                    <p className="text-xs text-rf-text-muted">
                      {workoutsQuery.isLoading
                        ? "Loading..."
                        : customWorkouts.length > 0
                          ? `${visibleWorkouts.length} available, ${customWorkouts.length} custom`
                          : `${visibleWorkouts.length} types available`}
                    </p>
                  </div>
                  <span className="ml-auto text-rf-text-muted">›</span>
                </button>
              </div>
            </SectionCard>

            <MyAccountSection onSignOut={signOut} />
          </div>
        ) : (
          <div className="space-y-5">
            <div className="glass-card rounded-3xl p-6">
              <div className="flex items-center gap-2 text-sm font-semibold text-rf-text">
                <span className="text-blue-600">
                  <IconInfo className="h-4 w-4" />
                </span>
                Program Info
              </div>

              <div className="mt-4 space-y-4 rounded-2xl border border-rf-border bg-rf-surface-muted p-4 text-sm">
                <InfoRow label="Name" value={program?.name ?? "Program"} />
                <Divider />
                <InfoRow
                  label="Status"
                  value={<StatusPill status={program?.status ?? "active"} />}
                  alignEnd
                />
                <Divider />
                <InfoRow
                  label="Duration"
                  value={formatDateRange(program?.start_date ?? null, program?.end_date ?? null)}
                  alignEnd
                />
                <Divider />
                <div>
                  <div className="flex items-center justify-between text-xs font-semibold text-rf-text-muted">
                    <span>Progress</span>
                    <span className="text-rf-text">{progress.percent}%</span>
                  </div>
                  <div className="progress-track mt-2 h-2 w-full overflow-hidden rounded-full">
                    <div
                      className="h-full rounded-full bg-rf-accent"
                      style={{ width: `${progress.percent}%` }}
                    />
                  </div>
                  <div className="mt-2 flex items-center justify-between text-xs text-rf-text-muted">
                    <span>{progress.elapsedDays} days elapsed</span>
                    <span>{progress.remainingDays} days remaining</span>
                  </div>
                </div>
                <Divider />
                <InfoRow
                  label="Active Members"
                  value={membershipQuery.isLoading ? "—" : `${activeMembers}`}
                  alignEnd
                />
              </div>
            </div>

            <button
              type="button"
              onClick={() => router.push("/programs")}
              className="flex w-full items-center gap-4 rounded-3xl border border-rf-border bg-rf-surface-muted px-5 py-4 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
            >
              <span className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
                ⇄
              </span>
              <div>
                <p>Switch Program</p>
                <p className="text-xs text-rf-text-muted">View a different program</p>
              </div>
              <span className="ml-auto text-rf-text-muted">›</span>
            </button>

            {canLeaveProgram && (
              <button
                type="button"
                onClick={() => setShowLeaveConfirm(true)}
                className="flex w-full items-center gap-4 rounded-3xl border border-rf-border bg-rf-surface-muted px-5 py-4 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
              >
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-200 text-gray-600">
                  ↩︎
                </span>
                <div>
                  <p>Leave Program</p>
                  <p className="text-xs text-rf-text-muted">Your data will be preserved</p>
                </div>
                <span className="ml-auto text-rf-text-muted">›</span>
              </button>
            )}

            <MyAccountSection onSignOut={signOut} />
          </div>
        )}
      </div>

      <ConfirmModal
        open={showLeaveConfirm}
        title="Leave Program?"
        description={`You will no longer have access to ${program?.name ?? "this program"}. Your data will be preserved and restored if you rejoin. If you're the last member, the program will be deleted automatically.`}
        confirmLabel={leaveMutation.isPending ? "Leaving..." : "Leave"}
        onConfirm={() => leaveMutation.mutate()}
        onClose={() => setShowLeaveConfirm(false)}
      />
    </div>
  );
}

function SectionCard({ title, icon, children }: { title: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="glass-card rounded-3xl p-6">
      <div className="flex items-center gap-2 text-sm font-semibold text-rf-text">
        <span className="text-rf-text">{icon}</span>
        {title}
      </div>
      <div className="mt-4">{children}</div>
    </div>
  );
}

function RoleList({
  title,
  members,
  accent
}: {
  title: string;
  members: MembershipDetail[];
  accent: string;
}) {
  return (
    <div>
      <p className={`text-xs font-semibold uppercase tracking-wide ${accent}`}>{title}</p>
      <div className="mt-2 grid gap-2">
        {members.map((member) => (
          <div
            key={member.member_id}
            className="flex items-center gap-3 rounded-2xl bg-rf-surface-muted px-3 py-2 text-sm"
          >
            <div className="metric-pill flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold text-rf-text">
              {initials(member.member_name)}
            </div>
            <div>
              <p className="font-semibold text-rf-text">{member.member_name}</p>
              {member.global_role === "global_admin" && (
                <p className="text-xs text-rf-text-muted">Global Admin</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function InfoRow({
  label,
  value,
  alignEnd
}: {
  label: string;
  value: React.ReactNode;
  alignEnd?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <span className="text-xs font-semibold text-rf-text-muted">{label}</span>
      <span className={`text-sm font-semibold text-rf-text ${alignEnd ? "text-right" : ""}`}>{value}</span>
    </div>
  );
}

function Divider() {
  return <div className="subtle-divider" />;
}

function StatusPill({ status }: { status: string }) {
  const normalized = status?.toLowerCase() ?? "active";
  const styles = {
    active: "bg-amber-500 text-black",
    planned: "bg-blue-500 text-white",
    completed: "bg-emerald-500 text-white"
  } as Record<string, string>;
  const className = styles[normalized] ?? styles.active;
  return (
    <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ${className}`}>
      {normalized}
    </span>
  );
}

function computeProgramProgress(startDate: string | null, endDate: string | null) {
  if (!startDate || !endDate) {
    return { totalDays: 0, elapsedDays: 0, remainingDays: 0, percent: 0 };
  }
  const start = new Date(startDate);
  const end = new Date(endDate);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end <= start) {
    return { totalDays: 0, elapsedDays: 0, remainingDays: 0, percent: 0 };
  }
  const msInDay = 1000 * 60 * 60 * 24;
  const totalDays = Math.max(Math.round((end.getTime() - start.getTime()) / msInDay), 0);
  const today = new Date();
  const elapsedDays = Math.min(
    Math.max(Math.round((today.getTime() - start.getTime()) / msInDay), 0),
    totalDays
  );
  const remainingDays = Math.max(totalDays - elapsedDays, 0);
  const percent = totalDays > 0 ? Math.round((elapsedDays / totalDays) * 100) : 0;
  return { totalDays, elapsedDays, remainingDays, percent };
}

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((part) => part[0]?.toUpperCase())
    .slice(0, 2)
    .join("");
}

function ConfirmModal({
  open,
  title,
  description,
  confirmLabel,
  onConfirm,
  onClose
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel: string;
  onConfirm: () => void;
  onClose: () => void;
}) {
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
      <div className="modal-surface relative z-10 w-full max-w-md rounded-3xl p-6">
        <h3 className="text-lg font-semibold text-rf-text">{title}</h3>
        <p className="mt-2 text-sm text-rf-text-muted">{description}</p>
        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={onClose}
            className="pill-button rounded-2xl px-4 py-3 text-sm font-semibold"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className="danger-pill rounded-2xl px-4 py-3 text-sm font-semibold"
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

function IconInfo({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <circle cx="10" cy="10" r="8" />
      <line x1="10" y1="9" x2="10" y2="14" strokeLinecap="round" />
      <circle cx="10" cy="6" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

function IconUsers({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <circle cx="6.5" cy="7" r="3" />
      <circle cx="14.5" cy="8" r="2.5" />
      <path d="M2.5 17c0-2.6 2.3-4.6 5.1-4.6S12.7 14.4 12.7 17" strokeLinecap="round" />
      <path d="M11.8 16.5c.3-1.8 1.9-3.1 3.8-3.1 1.8 0 3.4 1.3 3.7 3.1" strokeLinecap="round" />
    </svg>
  );
}

function IconKey({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <circle cx="7" cy="9" r="3.5" />
      <path d="M10 9h7M14 9v3M16 9v2" strokeLinecap="round" />
    </svg>
  );
}

function IconDumbbell({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="2" y="7" width="3" height="6" rx="1" />
      <rect x="15" y="7" width="3" height="6" rx="1" />
      <rect x="5.5" y="8" width="3" height="4" rx="1" />
      <rect x="11.5" y="8" width="3" height="4" rx="1" />
      <path d="M8.5 10h3" strokeLinecap="round" />
    </svg>
  );
}

function IconUser({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <circle cx="10" cy="7" r="3.2" />
      <path d="M4 17c0-3 2.7-5.2 6-5.2s6 2.2 6 5.2" strokeLinecap="round" />
    </svg>
  );
}

function IconMail({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="3" y="5" width="14" height="10" rx="2" />
      <path d="M4 6l6 4 6-4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function IconSettings({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path
        d="M10 3.5l1 1.7 2-.2.9 1.8-1.4 1.3.4 2-1.8 1-1 1.7-2-.3-1.7 1-1.6-1.3.3-2-1.3-1.5 1-1.8 2 .2 1-1.7z"
        strokeLinejoin="round"
      />
      <circle cx="10" cy="10" r="2.2" />
    </svg>
  );
}

function IconLock({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="4" y="9" width="12" height="8" rx="2" />
      <path d="M7 9V7a3 3 0 0 1 6 0v2" strokeLinecap="round" />
    </svg>
  );
}

function IconPalette({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M10 3.5a6.5 6.5 0 1 0 0 13h1.2c1 0 1.8-.8 1.8-1.8v-.5c0-.7.6-1.3 1.3-1.3h1.3A3.4 3.4 0 0 0 18 9.6 6.5 6.5 0 0 0 10 3.5z" />
      <circle cx="7" cy="8" r="0.8" fill="currentColor" stroke="none" />
      <circle cx="10.5" cy="6.8" r="0.8" fill="currentColor" stroke="none" />
      <circle cx="6.5" cy="11" r="0.8" fill="currentColor" stroke="none" />
    </svg>
  );
}

function IconDocument({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M6 3h6l4 4v10a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 17V4.5A1.5 1.5 0 0 1 6 3z" />
      <path d="M12 3v4h4" />
      <path d="M7 11h6M7 14h6" strokeLinecap="round" />
    </svg>
  );
}

function IconLogout({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M4 4h6a2 2 0 0 1 2 2v2" strokeLinecap="round" />
      <path d="M10 16H6a2 2 0 0 1-2-2V6" strokeLinecap="round" />
      <path d="M11 10h7" strokeLinecap="round" />
      <path d="M15 7l3 3-3 3" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function MyAccountSection({ onSignOut }: { onSignOut: () => Promise<void> }) {
  const router = useRouter();
  const [appearance, setAppearance] = useState("System");

  useEffect(() => {
    if (typeof window === "undefined") return;
    const stored = window.localStorage.getItem("rf:appearance") ?? "system";
    setAppearance(stored === "dark" ? "Dark" : stored === "light" ? "Light" : "System");
  }, []);
  return (
    <SectionCard title="My Account" icon={<IconUser className="h-4 w-4" />}>
      <div className="space-y-3">
        <button
          type="button"
          onClick={() => router.push("/program/profile")}
          className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
        >
          <span className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <IconUser className="h-5 w-5" />
          </span>
          <div>
            <p>My Profile</p>
            <p className="text-xs text-rf-text-muted">Update your personal info</p>
          </div>
          <span className="ml-auto text-rf-text-muted">›</span>
        </button>

        <button
          type="button"
          onClick={() => router.push("/program/password")}
          className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
        >
          <span className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <IconLock className="h-5 w-5" />
          </span>
          <div>
            <p>Change Password</p>
            <p className="text-xs text-rf-text-muted">Update your account password</p>
          </div>
          <span className="ml-auto text-rf-text-muted">›</span>
        </button>

        <button
          type="button"
          onClick={() => router.push("/program/appearance")}
          className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
        >
          <span className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 text-purple-600">
            <IconPalette className="h-5 w-5" />
          </span>
          <div>
            <p>Appearance</p>
            <p className="text-xs text-rf-text-muted">{appearance}</p>
          </div>
          <span className="ml-auto text-rf-text-muted">›</span>
        </button>

        <button
          type="button"
          onClick={() => router.push("/program/privacy")}
          className="flex w-full items-center gap-4 rounded-2xl border border-rf-border bg-rf-surface-muted px-4 py-3 text-left text-sm font-semibold text-rf-text shadow-sm transition hover:border-rf-text"
        >
          <span className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <IconDocument className="h-5 w-5" />
          </span>
          <div>
            <p>Privacy Policy</p>
            <p className="text-xs text-rf-text-muted">Learn how we handle your data</p>
          </div>
          <span className="ml-auto text-rf-text-muted">›</span>
        </button>

        <button
          type="button"
          onClick={() => onSignOut()}
          className="danger-row flex w-full items-center gap-4 rounded-2xl px-4 py-3 text-left text-sm font-semibold shadow-sm"
        >
          <span className="danger-icon flex h-10 w-10 items-center justify-center rounded-full">
            <IconLogout className="h-5 w-5" />
          </span>
          Sign Out
        </button>
      </div>
    </SectionCard>
  );
}
