"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchMembershipDetails, updateMembership, type MembershipDetail } from "@/lib/api/programs";
import { initials } from "@/lib/format";
import { useAuthGuard } from "@/lib/hooks/use-auth-guard";
import { PageShell } from "@/components/ui/PageShell";
import { PageHeader } from "@/components/ui/PageHeader";
import { GlassCard } from "@/components/ui/GlassCard";
import { LoadingState } from "@/components/ui/LoadingState";
import { ErrorState } from "@/components/ui/ErrorState";

export default function ManageRolesPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { session, program, token, programId } = useAuthGuard();

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;

  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (program?.id && !isProgramAdmin) {
      router.push("/program");
    }
  }, [program?.id, isProgramAdmin, router]);

  const membersQuery = useQuery({
    queryKey: ["program", "roles", programId],
    queryFn: () => fetchMembershipDetails(token, programId),
    enabled: !!token && !!programId && isProgramAdmin
  });

  const activeMembers = useMemo(() => {
    return (membersQuery.data ?? []).filter((member) => member.status === "active");
  }, [membersQuery.data]);

  const activeAdminCount = useMemo(() => {
    return activeMembers.filter((member) => member.program_role === "admin").length;
  }, [activeMembers]);

  const updateMutation = useMutation({
    mutationFn: (payload: { memberId: string; role: string }) =>
      updateMembership(token, {
        program_id: programId,
        member_id: payload.memberId,
        role: payload.role
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["program", "roles", programId] });
      await queryClient.invalidateQueries({ queryKey: ["program", "membership-details", programId] });
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to update role.");
    },
    onSettled: () => {
      setUpdatingId(null);
    }
  });

  const handleRoleChange = async (member: MembershipDetail, role: "admin" | "logger" | "member") => {
    if (member.program_role === role || updatingId) return;
    setErrorMessage(null);
    setUpdatingId(member.member_id);
    updateMutation.mutate({ memberId: member.member_id, role });
  };

  return (
    <PageShell maxWidth="3xl">
      <PageHeader
        title="Manage Roles"
        subtitle="Assign admin, logger, or member roles."
        backHref="/program"
      />

      {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}

      {membersQuery.isLoading && <LoadingState message="Loading roles..." />}

      {membersQuery.isError && <ErrorState message={(membersQuery.error as Error).message} />}

      {membersQuery.data && (
        <div className="space-y-4">
          {activeMembers.map((member) => {
            const isLastActiveAdmin =
              member.program_role === "admin" && member.status === "active" && activeAdminCount <= 1;
            return (
              <GlassCard key={member.member_id} padding="md">
                <div className="flex items-center gap-4">
                  <div className="metric-pill flex h-12 w-12 items-center justify-center rounded-full text-sm font-semibold text-rf-text">
                    {initials(member.member_name)}
                  </div>
                  <div>
                    <p className="text-base font-semibold text-rf-text">{member.member_name}</p>
                    <p className="text-xs text-rf-text-muted">
                      {roleLabel(member.program_role)}
                      {member.global_role === "global_admin" ? " • Global Admin" : ""}
                    </p>
                  </div>
                  {updatingId === member.member_id && (
                    <span className="ml-auto text-xs text-rf-text-muted">Updating...</span>
                  )}
                </div>

                <div className="mt-4 grid gap-2 sm:grid-cols-3">
                  <RoleButton
                    label="Admin"
                    active={member.program_role === "admin"}
                    disabled={isLastActiveAdmin}
                    onClick={() => handleRoleChange(member, "admin")}
                    tone="admin"
                  />
                  <RoleButton
                    label="Logger"
                    active={member.program_role === "logger"}
                    disabled={isLastActiveAdmin}
                    onClick={() => handleRoleChange(member, "logger")}
                    tone="logger"
                  />
                  <RoleButton
                    label="Member"
                    active={member.program_role === "member"}
                    disabled={isLastActiveAdmin}
                    onClick={() => handleRoleChange(member, "member")}
                    tone="member"
                  />
                </div>

                {isLastActiveAdmin && (
                  <p className="mt-3 text-xs text-rf-text-muted">
                    You cannot remove the last active admin from the program.
                  </p>
                )}
              </GlassCard>
            );
          })}
        </div>
      )}
    </PageShell>
  );
}

type RoleTone = "admin" | "logger" | "member";

const ROLE_TONES: Record<RoleTone, { color: string; text: string }> = {
  admin: { color: "#f59e0b", text: "#111827" },
  logger: { color: "#3b82f6", text: "#ffffff" },
  member: { color: "#6b7280", text: "#ffffff" }
};

function RoleButton({
  label,
  active,
  disabled,
  onClick,
  tone
}: {
  label: string;
  active: boolean;
  disabled: boolean;
  onClick: () => void;
  tone: RoleTone;
}) {
  const toneConfig = ROLE_TONES[tone];
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={active || disabled}
      className={`rounded-full px-4 py-2 text-xs font-semibold transition border ${
        active ? "" : "bg-rf-surface-muted text-rf-text-muted"
      } ${disabled && !active ? "opacity-50" : ""}`}
      style={
        active
          ? { backgroundColor: toneConfig.color, color: toneConfig.text, borderColor: toneConfig.color }
          : { borderColor: toneConfig.color }
      }
    >
      {active ? "✓ " : ""}
      {label}
    </button>
  );
}

function roleLabel(role?: string | null) {
  switch (role) {
    case "admin":
      return "Program Admin";
    case "logger":
      return "Logger";
    default:
      return "Member";
  }
}
