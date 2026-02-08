"use client";

export const dynamic = "force-dynamic";

import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMembershipDetails, removeMembership, updateMembership, type MembershipDetail } from "@/lib/api/programs";
import { BackButton } from "@/components/BackButton";

export default function MemberDetailPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const memberId = searchParams.get("memberId") ?? "";
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const programId = program?.id ?? "";
  const isGlobalAdmin = session?.user.globalRole === "global_admin";

  const [joinedAt, setJoinedAt] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
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
    if (!isGlobalAdmin) {
      router.push("/members");
    }
  }, [isGlobalAdmin, router]);

  const membersQuery = useQuery({
    queryKey: ["members", "details", programId],
    queryFn: () => fetchMembershipDetails(token, programId),
    enabled: !!token && !!programId && !!memberId
  });

  const member = useMemo(() => {
    return membersQuery.data?.find((item) => item.member_id === memberId) ?? null;
  }, [membersQuery.data, memberId]);

  useEffect(() => {
    if (!member) return;
    setJoinedAt(member.joined_at ?? "");
    setIsActive(member.is_active ?? true);
  }, [member]);

  const handleSave = async () => {
    if (!member) return;
    setIsSaving(true);
    setErrorMessage(null);
    try {
      await updateMembership(token, {
        program_id: programId,
        member_id: member.member_id,
        joined_at: joinedAt || null,
        is_active: isActive
      });
      router.push("/members/list");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Unable to save changes.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleRemove = async () => {
    if (!member) return;
    const confirmed = window.confirm(`Remove ${member.member_name} from the program?`);
    if (!confirmed) return;
    setIsSaving(true);
    setErrorMessage(null);
    try {
      await removeMembership(token, { program_id: programId, member_id: member.member_id });
      router.push("/members/list");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Unable to remove member.");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members/list" />
          <h1 className="text-2xl font-bold">Member Details</h1>
        </header>

        {membersQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading member...</div>
        )}

        {membersQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(membersQuery.error as Error).message}
          </div>
        )}

        {member && (
          <div className="glass-card rounded-3xl p-6">
            <div className="flex items-center gap-4">
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-rf-surface-muted text-lg font-semibold">
                {initials(member.member_name)}
              </div>
              <div>
                <p className="text-lg font-semibold text-rf-text">{member.member_name}</p>
                <p className="text-sm text-rf-text-muted">@{member.username ?? ""}</p>
                {member.program_role === "admin" && (
                  <p className="text-xs font-semibold text-rf-accent">Program Admin</p>
                )}
              </div>
            </div>

            <div className="mt-6 grid gap-3 text-sm text-rf-text-muted">
              {member.gender && <p>Gender: {member.gender}</p>}
              {member.date_joined && <p>Account Created: {member.date_joined}</p>}
            </div>

            <div className="mt-6 space-y-4">
              <div>
                <label className="text-sm font-semibold text-rf-text">Joined Program</label>
                <input
                  type="date"
                  value={joinedAt}
                  onChange={(event) => setJoinedAt(event.target.value)}
                  className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
                />
              </div>

              <label className="flex items-center gap-3 text-sm font-semibold text-rf-text">
                <input
                  type="checkbox"
                  checked={isActive}
                  onChange={(event) => setIsActive(event.target.checked)}
                />
                Active Membership
              </label>
            </div>

            {errorMessage && <p className="mt-4 text-sm font-semibold text-rf-danger">{errorMessage}</p>}

            <div className="mt-6 grid gap-3 sm:grid-cols-2">
              <button
                type="button"
                onClick={handleSave}
                disabled={isSaving}
                className="rounded-2xl bg-rf-accent px-4 py-3 text-sm font-semibold text-black disabled:opacity-50"
              >
                {isSaving ? "Saving..." : "Save changes"}
              </button>
              <button
                type="button"
                onClick={handleRemove}
                disabled={isSaving}
                className="rounded-2xl bg-red-100 px-4 py-3 text-sm font-semibold text-red-600 disabled:opacity-50"
              >
                Remove from program
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((part) => part[0]?.toUpperCase())
    .slice(0, 2)
    .join("");
}
