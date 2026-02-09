"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth/auth-provider";
import { changePassword } from "@/lib/api/auth";
import { BackButton } from "@/components/BackButton";
import { useActiveProgram } from "@/lib/use-active-program";

export default function ChangePasswordPage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const program = useActiveProgram();
  const fallbackHref = program?.id ? "/program" : "/programs";

  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isBootstrapping && !session?.token) {
      router.push("/login");
    }
  }, [isBootstrapping, session?.token, router]);

  const validation = useMemo(() => validatePassword(newPassword, confirmPassword), [newPassword, confirmPassword]);

  const mutation = useMutation({
    mutationFn: () => changePassword(token, newPassword),
    onSuccess: () => {
      setSuccessMessage("Password updated successfully.");
      setNewPassword("");
      setConfirmPassword("");
    },
    onError: (error) => {
      setErrorMessage(error instanceof Error ? error.message : "Unable to update password.");
    }
  });

  const canSubmit = validation.isValid && !mutation.isPending;

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref={fallbackHref} />
          <h1 className="text-2xl font-bold">Change Password</h1>
          <p className="text-sm text-rf-text-muted">Enter a new password for your account.</p>
        </header>

        <div className="glass-card rounded-3xl p-6 space-y-5">
          <div>
            <label className="text-sm font-semibold text-rf-text">New password</label>
            <div className="input-shell mt-2 flex items-center gap-2 rounded-2xl px-4 py-3">
              <input
                type={showPassword ? "text" : "password"}
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                placeholder="••••••••"
                className="w-full bg-transparent text-sm font-medium outline-none"
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                className="text-xs font-semibold text-rf-text-muted"
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
          </div>

          <div>
            <label className="text-sm font-semibold text-rf-text">Confirm password</label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              placeholder="••••••••"
              className="input-shell mt-2 w-full rounded-2xl px-4 py-3 text-sm font-medium"
            />
          </div>

          <div className="space-y-1 text-xs text-rf-text-muted">
            <p className={validation.hasLength ? "text-emerald-600" : ""}>• At least 8 characters</p>
            <p className={validation.hasUpper ? "text-emerald-600" : ""}>• One uppercase letter</p>
            <p className={validation.hasLower ? "text-emerald-600" : ""}>• One lowercase letter</p>
            <p className={validation.hasNumber ? "text-emerald-600" : ""}>• One number</p>
            <p className={validation.matches ? "text-emerald-600" : ""}>• Passwords match</p>
          </div>

          {errorMessage && <p className="text-sm font-semibold text-rf-danger">{errorMessage}</p>}
          {successMessage && <p className="text-sm font-semibold text-emerald-600">{successMessage}</p>}

          <button
            type="button"
            disabled={!canSubmit}
            onClick={() => {
              setErrorMessage(null);
              setSuccessMessage(null);
              mutation.mutate();
            }}
            className="w-full rounded-2xl bg-rf-accent px-4 py-3 text-sm font-semibold text-black disabled:opacity-50"
          >
            {mutation.isPending ? "Updating..." : "Update Password"}
          </button>
        </div>
      </div>
    </div>
  );
}

function validatePassword(password: string, confirm: string) {
  const hasLength = password.length >= 8;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const matches = password.length > 0 && password === confirm;
  return {
    hasLength,
    hasUpper,
    hasLower,
    hasNumber,
    matches,
    isValid: hasLength && hasUpper && hasLower && hasNumber && matches
  };
}
