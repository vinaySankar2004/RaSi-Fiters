"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { clearSession, loadSession, saveSession, type SessionState } from "@/lib/auth/session";
import { clearActiveProgram } from "@/lib/storage";
import { decodeJwtPayload, resolveGlobalRole, type DecodedAuthToken } from "@/lib/auth/jwt";

type AuthContextValue = {
  session: SessionState | null;
  setSession: (session: SessionState | null) => void;
  signOut: () => Promise<void>;
  isBootstrapping: boolean;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSessionState] = useState<SessionState | null>(null);
  const [isBootstrapping, setIsBootstrapping] = useState(true);

  useEffect(() => {
    const stored = loadSession();
    if (stored) {
      const hydrated = hydrateSessionFromToken(stored);
      setSessionState(hydrated);
      saveSession(hydrated);
    }
    setIsBootstrapping(false);
  }, []);

  const setSession = (next: SessionState | null) => {
    const hydrated = next ? hydrateSessionFromToken(next) : null;
    const currentUserId = session?.user.id;
    const nextUserId = hydrated?.user.id;
    if (!hydrated || (currentUserId && nextUserId && currentUserId !== nextUserId)) {
      clearActiveProgram();
    }
    if (hydrated) {
      saveSession(hydrated);
      setSessionState(hydrated);
    } else {
      clearSession();
      setSessionState(null);
    }
  };

  const signOut = async () => {
    setSession(null);
  };

  const value = useMemo<AuthContextValue>(
    () => ({ session, setSession, signOut, isBootstrapping }),
    [session, isBootstrapping]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
}

function hydrateSessionFromToken(session: SessionState): SessionState {
  const decoded = decodeJwtPayload<DecodedAuthToken>(session.token);
  if (!decoded) return session;
  const globalRole = resolveGlobalRole({
    tokenGlobalRole: decoded.global_role,
    tokenRole: decoded.role,
    responseGlobalRole: session.user.globalRole,
    fallback: session.user.globalRole ?? "standard"
  });
  return {
    ...session,
    user: {
      id: decoded.id ?? session.user.id,
      username: decoded.username ?? session.user.username,
      memberName: decoded.member_name ?? session.user.memberName,
      globalRole
    }
  };
}
