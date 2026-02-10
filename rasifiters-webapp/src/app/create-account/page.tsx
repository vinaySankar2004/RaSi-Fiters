"use client";

export const dynamic = "force-dynamic";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { BrandMark } from "@/components/BrandMark";
import { Select } from "@/components/Select";
import { login, registerAccount } from "@/lib/api/auth";
import { useAuth } from "@/lib/auth/auth-provider";
import { decodeJwtPayload, resolveGlobalRole, type DecodedAuthToken } from "@/lib/auth/jwt";
import { PRIVACY_POLICY_URL } from "@/lib/config";

const genderOptions = [
  { value: "Female", label: "Female" },
  { value: "Male", label: "Male" },
  { value: "Non-binary", label: "Non-binary" },
  { value: "Prefer not to say", label: "Prefer not to say" }
];

export default function CreateAccountPage() {
  const router = useRouter();
  const { setSession } = useAuth();
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [gender, setGender] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const passwordMeetsPolicy = useMemo(() => {
    if (password.length < 8) return false;
    const hasUpper = /[A-Z]/.test(password);
    const hasLower = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    return hasUpper && hasLower && hasNumber;
  }, [password]);

  const canSubmit = useMemo(() => {
    return (
      firstName.trim().length > 0 &&
      lastName.trim().length > 0 &&
      username.trim().length > 0 &&
      email.trim().length > 0 &&
      passwordMeetsPolicy &&
      password === confirmPassword
    );
  }, [firstName, lastName, username, email, passwordMeetsPolicy, password, confirmPassword]);

  const handleCreateAccount = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!canSubmit || isLoading) return;
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const payload = {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        username: username.trim(),
        email: email.trim(),
        password,
        ...(gender.trim().length > 0 ? { gender: gender.trim() } : {})
      };

      await registerAccount(payload);

      const response = await login(username.trim(), password);
      const decoded = decodeJwtPayload<DecodedAuthToken>(response.token);
      const resolvedGlobalRole = resolveGlobalRole({
        tokenGlobalRole: decoded?.global_role,
        tokenRole: decoded?.role,
        responseGlobalRole: response.global_role,
        responseRole: (response as { role?: string }).role
      });
      const nextSession = {
        token: response.token,
        refreshToken: response.refresh_token,
        user: {
          id: decoded?.id ?? response.member_id,
          username: decoded?.username ?? response.username,
          memberName: decoded?.member_name ?? response.member_name,
          globalRole: resolvedGlobalRole
        }
      };
      setSession(nextSession);
      router.push("/programs");
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Unable to create account. Try again.";
      setErrorMessage(message);
    } finally {
      setIsLoading(false);
    }
  };

  const showMismatch = confirmPassword.length > 0 && confirmPassword !== password;

  return (
    <div className="relative flex min-h-screen flex-col items-center px-6 pb-12 pt-14 sm:px-10 sm:pt-20">
      <motion.div
        className="flex w-full max-w-md flex-col items-center"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
      >
        <BrandMark size={128} />

        <div className="mt-8 text-center">
          <h1 className="text-2xl font-semibold text-rf-text sm:text-3xl">Create Account</h1>
          <p className="mt-2 text-sm font-semibold text-rf-text-muted sm:text-base">
            Start tracking your fitness journey
          </p>
        </div>

        <form
          onSubmit={handleCreateAccount}
          className="mt-10 flex w-full flex-col gap-4"
        >
          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type="text"
              placeholder="First Name"
              value={firstName}
              onChange={(event) => setFirstName(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="given-name"
            />
          </label>

          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type="text"
              placeholder="Last Name"
              value={lastName}
              onChange={(event) => setLastName(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="family-name"
            />
          </label>

          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type="text"
              placeholder="Username"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="username"
            />
          </label>

          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="email"
            />
          </label>

          <Select
            value={gender}
            options={genderOptions}
            onChange={setGender}
            placeholder="Gender (optional)"
            className="w-full"
          />

          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type={showPassword ? "text" : "password"}
              placeholder="Password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="new-password"
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              className="text-xs font-semibold text-rf-text-muted transition hover:text-rf-text sm:text-sm"
            >
              {showPassword ? "Hide" : "Show"}
            </button>
          </label>

          <label className="input-shell flex items-center gap-3 rounded-2xl px-4 py-3">
            <input
              type={showConfirmPassword ? "text" : "password"}
              placeholder="Confirm Password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              className="w-full bg-transparent text-sm font-medium text-rf-text placeholder:text-rf-text-muted focus:outline-none sm:text-base"
              autoComplete="new-password"
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword((prev) => !prev)}
              className="text-xs font-semibold text-rf-text-muted transition hover:text-rf-text sm:text-sm"
            >
              {showConfirmPassword ? "Hide" : "Show"}
            </button>
          </label>

          <div className="space-y-2 text-left text-xs sm:text-sm">
            <p className="text-rf-text-muted">
              Password must be at least 8 characters and include upper, lower, and a number.
            </p>
            {showMismatch && (
              <p className="font-semibold text-red-600">Passwords do not match.</p>
            )}
          </div>

          {errorMessage && (
            <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-600">
              {errorMessage}
            </div>
          )}

          <button
            type="submit"
            disabled={!canSubmit || isLoading}
            className="button-primary button-primary--dark-white mt-2 inline-flex min-h-[50px] items-center justify-center rounded-full px-8 text-base font-semibold"
          >
            {isLoading ? "Creating account..." : "Create Account"}
          </button>
        </form>

        <div className="mt-6 flex items-center gap-2 text-sm text-rf-text-muted sm:text-base">
          <span>Already have an account?</span>
          <Link
            href="/login"
            className="font-semibold text-rf-accent transition hover:text-rf-accent-strong"
          >
            Sign in
          </Link>
        </div>

        <div className="mt-8 text-center text-xs text-rf-text-muted sm:text-sm">
          <p>By creating an account, you accept our</p>
          <Link
            href={PRIVACY_POLICY_URL}
            className="mt-1 inline-block font-semibold text-rf-accent"
          >
            Privacy Policy
          </Link>
        </div>
      </motion.div>
    </div>
  );
}
