"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth/auth-provider";
import { useActiveProgram } from "@/lib/use-active-program";

export function useAuthGuard() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = useActiveProgram();

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

  const token = session?.token ?? "";
  const programId = program?.id ?? "";
  const isReady = !!token && !!programId;

  return { session, program, token, programId, isReady, isBootstrapping };
}
