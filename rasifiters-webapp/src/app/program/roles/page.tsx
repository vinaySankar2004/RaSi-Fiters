"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMembershipDetails, updateMembership, type MembershipDetail } from "@/lib/api/programs";
import { BackButton } from "@/components/BackButton";

export default function ManageRolesPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const programId = program?.id ?? "";

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const isProgramAdmin = program?.my_role === "admin" || isGlobalAdmin;

  const [updatingId, setUpdatingId] = useState<string | null>(null);
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
    if (program?.id && !isProgramAdmin) {
      router.push("/program");
    }
  }, [program?.id, isProgramAdmin, router]);

  const membersQuery = useQuery({
    queryKey: ["program", "roles", programId],
    queryFn: () => fetchMembershipDetails(token, programId),
    enabled: !!token && !!programId && isProgramAdmin
  });

  const activeAdminCount = useMemo(() => {
    return (membersQuery.data ?? []).filter(
      (member) => member.program_role === "admin" && member.status === "active"
    ).length;
  }, [membersQuery.data]);

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
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/program" />
          <h1 className="text-2xl font-bold">Manage Roles</h1>
          <p className="text-sm text-rf-text-muted">Assign admin, logger, or member roles.</p>
        </header>

        {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}

        {membersQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading roles...</div>
        )}

        {membersQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(membersQuery.error as Error).message}
          </div>
        )}

        {membersQuery.data && (
          <div className="space-y-4">
            {membersQuery.data.map((member) => {
              const isLastActiveAdmin =
                member.program_role === "admin" && member.status === "active" && activeAdminCount <= 1;
              return (
                <div key={member.member_id} className="glass-card rounded-3xl p-5">
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
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
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

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((part) => part[0]?.toUpperCase())
    .slice(0, 2)
    .join("");
}
