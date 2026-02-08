"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { fetchMembershipDetails, type MembershipDetail } from "@/lib/api/programs";
import { BackButton } from "@/components/BackButton";

export default function MembersListPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const programId = program?.id ?? "";
  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const [search, setSearch] = useState("");

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

  const membersQuery = useQuery({
    queryKey: ["members", "details", programId],
    queryFn: () => fetchMembershipDetails(token, programId),
    enabled: !!token && !!programId
  });

  const filtered = useMemo(() => {
    if (!membersQuery.data) return [];
    if (!search.trim()) return membersQuery.data;
    const query = search.trim().toLowerCase();
    return membersQuery.data.filter((member) => member.member_name.toLowerCase().includes(query));
  }, [membersQuery.data, search]);

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref="/members" />
          <div>
            <h1 className="text-2xl font-bold">Members</h1>
            <p className="mt-1 text-sm text-rf-text-muted">{program?.name ?? "Program"}</p>
          </div>
        </header>

        <div className="glass-card rounded-3xl p-5">
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search members"
            className="input-shell w-full rounded-2xl px-4 py-3 text-sm font-medium"
          />
        </div>

        {membersQuery.isLoading && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">Loading members...</div>
        )}

        {membersQuery.isError && (
          <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-rf-danger">
            {(membersQuery.error as Error).message}
          </div>
        )}

        {membersQuery.data && filtered.length === 0 && (
          <div className="glass-card rounded-3xl p-6 text-sm text-rf-text-muted">No members found.</div>
        )}

        {membersQuery.data && filtered.length > 0 && (
          <div className="grid gap-3">
            {filtered.map((member) => (
              <MemberRow
                key={member.member_id}
                member={member}
                canEdit={isGlobalAdmin}
                onClick={() => router.push(`/members/detail?memberId=${member.member_id}`)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function MemberRow({
  member,
  canEdit,
  onClick
}: {
  member: MembershipDetail;
  canEdit: boolean;
  onClick: () => void;
}) {
  const content = (
    <div className="glass-card rounded-3xl p-4">
      <div className="flex items-center gap-4">
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-rf-surface-muted text-sm font-semibold">
          {initials(member.member_name)}
        </div>
        <div>
          <div className="flex items-center gap-2">
            <p className="text-base font-semibold text-rf-text">{member.member_name}</p>
            {member.program_role === "admin" && <span className="text-xs text-rf-accent">★</span>}
          </div>
          <p className="text-xs text-rf-text-muted">@{member.username ?? ""}</p>
        </div>
        <div className="ml-auto text-right">
          {!member.is_active && (
            <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-semibold text-red-600">
              Inactive
            </span>
          )}
        </div>
      </div>
    </div>
  );

  if (!canEdit) return content;
  return (
    <button type="button" onClick={onClick} className="text-left">
      {content}
    </button>
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
