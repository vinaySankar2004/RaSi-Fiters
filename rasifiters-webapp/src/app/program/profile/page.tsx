"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { deleteAccount as deleteAccountApi } from "@/lib/api/auth";
import { fetchMemberProfile, updateMemberProfile } from "@/lib/api/members";
import { BackButton } from "@/components/BackButton";

const GENDER_OPTIONS = ["Male", "Female", "Non-binary", "Prefer not to say"] as const;

export default function ProfilePage() {
  const router = useRouter();
  const { session, isBootstrapping, setSession, signOut } = useAuth();
  const token = session?.token ?? "";
  const program = loadActiveProgram();
  const fallbackHref = program?.id ? "/program" : "/programs";

  const isGlobalAdmin = session?.user.globalRole === "global_admin";
  const roleLabel = isGlobalAdmin
    ? "Global Admin"
    : program?.my_role === "admin"
      ? "Program Admin"
      : "Member";

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [gender, setGender] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showSuccess, setShowSuccess] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  useEffect(() => {
    if (!isBootstrapping && !session?.token) {
      router.push("/login");
    }
  }, [isBootstrapping, session?.token, router]);

  const profileQuery = useQuery({
    queryKey: ["account", "profile", session?.user.id],
    queryFn: () => fetchMemberProfile(token, session?.user.id ?? ""),
    enabled: !!token && !!session?.user.id
  });

  useEffect(() => {
    if (!profileQuery.data) return;
    const fullName = profileQuery.data.member_name ?? session?.user.memberName ?? "";
    const parts = fullName.split(" ").filter(Boolean);
    setFirstName(parts[0] ?? "");
    setLastName(parts.slice(1).join(" ") ?? "");
    setGender(profileQuery.data.gender ?? "");
  }, [profileQuery.data, session?.user.memberName]);

  const updateMutation = useMutation({
    mutationFn: () =>
      updateMemberProfile(token, session?.user.id ?? "", {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        gender: gender || null
      }),
    onSuccess: (data) => {
      setShowSuccess(true);
      if (session) {
        const updatedName = data.member_name ?? `${firstName.trim()} ${lastName.trim()}`.trim();
        setSession({
          ...session,
          user: {
            ...session.user,
            memberName: updatedName
          }
        });
      }
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to save changes.");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteAccountApi(token),
    onSuccess: async () => {
      await signOut();
      router.push("/login");
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to delete account.");
    }
  });

  const initials = useMemo(() => {
    const name = `${firstName} ${lastName}`.trim() || session?.user.memberName || session?.user.username || "U";
    return name
      .split(" ")
      .filter(Boolean)
      .map((part) => part[0]?.toUpperCase())
      .slice(0, 2)
      .join("");
  }, [firstName, lastName, session?.user.memberName, session?.user.username]);

  const canSave = firstName.trim().length > 0 && lastName.trim().length > 0 && !updateMutation.isPending;

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref={fallbackHref} />
          <h1 className="text-2xl font-bold">My Profile</h1>
        </header>

        <div className="glass-card rounded-3xl p-6 space-y-6">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-amber-100 text-lg font-semibold text-amber-600">
              {initials}
            </div>
            <div>
              <p className="text-lg font-semibold text-rf-text">
                {`${firstName} ${lastName}`.trim() || session?.user.memberName}
              </p>
              <p className="text-sm text-rf-text-muted">@{session?.user.username ?? ""}</p>
              <p className="text-xs font-semibold text-amber-600">{roleLabel}</p>
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="text-sm font-semibold text-rf-text">First name</label>
              <input
                value={firstName}
                onChange={(event) => setFirstName(event.target.value)}
                className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
                placeholder="First name"
              />
            </div>
            <div>
              <label className="text-sm font-semibold text-rf-text">Last name</label>
              <input
                value={lastName}
                onChange={(event) => setLastName(event.target.value)}
                className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
                placeholder="Last name"
              />
            </div>
          </div>

          <div>
            <label className="text-sm font-semibold text-rf-text">Gender</label>
            <select
              value={gender}
              onChange={(event) => setGender(event.target.value)}
              className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
            >
              <option value="">Select gender</option>
              {GENDER_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>

          {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}
          {showSuccess && (
            <p className="text-sm font-semibold text-emerald-600">Profile updated successfully.</p>
          )}

          <button
            type="button"
            disabled={!canSave}
            onClick={() => {
              setErrorMessage(null);
              setShowSuccess(false);
              updateMutation.mutate();
            }}
            className="w-full rounded-2xl bg-rf-accent px-4 py-3 text-sm font-semibold text-black disabled:opacity-50"
          >
            {updateMutation.isPending ? "Saving..." : "Save changes"}
          </button>

          {!isGlobalAdmin && (
            <div className="pt-4 border-t border-rf-border">
              <button
                type="button"
                onClick={() => setShowDeleteConfirm(true)}
                className="w-full rounded-2xl border border-rf-danger px-4 py-3 text-sm font-semibold text-rf-danger"
              >
                Delete Account
              </button>
              <p className="mt-2 text-xs text-rf-text-muted">
                This will permanently delete your account and all associated data.
              </p>
            </div>
          )}
        </div>
      </div>

      <ConfirmModal
        open={showDeleteConfirm}
        title="Delete Account?"
        description="This action cannot be undone. All your data, including workout logs, health logs, and program memberships will be permanently deleted."
        confirmLabel={deleteMutation.isPending ? "Deleting..." : "Delete"}
        onConfirm={() => deleteMutation.mutate()}
        onClose={() => setShowDeleteConfirm(false)}
      />
    </div>
  );
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
