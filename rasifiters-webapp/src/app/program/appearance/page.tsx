"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth/auth-provider";
import { loadActiveProgram } from "@/lib/storage";
import { applyTheme, getStoredTheme, setStoredTheme, type ThemePreference } from "@/lib/theme";
import { BackButton } from "@/components/BackButton";

const OPTIONS: { value: ThemePreference; title: string; description: string; icon: React.ReactNode }[] = [
  {
    value: "system",
    title: "System",
    description: "Follows your device settings",
    icon: <IconMonitor className="h-5 w-5" />
  },
  {
    value: "light",
    title: "Light",
    description: "Always use light appearance",
    icon: <IconSun className="h-5 w-5" />
  },
  {
    value: "dark",
    title: "Dark",
    description: "Always use dark appearance",
    icon: <IconMoon className="h-5 w-5" />
  }
];

export default function AppearancePage() {
  const router = useRouter();
  const { session, isBootstrapping } = useAuth();
  const program = loadActiveProgram();
  const fallbackHref = program?.id ? "/program" : "/programs";
  const [selection, setSelection] = useState<ThemePreference>("system");

  useEffect(() => {
    if (!isBootstrapping && !session?.token) {
      router.push("/login");
    }
  }, [isBootstrapping, session?.token, router]);

  useEffect(() => {
    const stored = getStoredTheme();
    setSelection(stored);
    applyTheme(stored);
  }, []);

  const handleSelect = (value: ThemePreference) => {
    setSelection(value);
    setStoredTheme(value);
  };

  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <header className="space-y-2">
          <BackButton fallbackHref={fallbackHref} />
          <h1 className="text-2xl font-bold">Appearance</h1>
          <p className="text-sm text-rf-text-muted">Choose how RaSi Fiters looks to you.</p>
        </header>

        <div className="glass-card rounded-3xl p-6 space-y-4">
          {OPTIONS.map((option) => (
            <button
              key={option.value}
              type="button"
              onClick={() => handleSelect(option.value)}
              className={`flex w-full items-center gap-4 rounded-2xl border px-4 py-3 text-left text-sm font-semibold transition ${
                selection === option.value
                  ? "border-rf-accent bg-rf-accent/10 text-rf-text"
                  : "border-rf-border bg-rf-surface-muted text-rf-text-muted"
              }`}
            >
              <span className="metric-pill flex h-10 w-10 items-center justify-center rounded-full text-rf-text">
                {option.icon}
              </span>
              <div>
                <p className="text-rf-text">{option.title}</p>
                <p className="text-xs text-rf-text-muted">{option.description}</p>
              </div>
              {selection === option.value && <span className="ml-auto">✓</span>}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function IconMonitor({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <rect x="3" y="4" width="14" height="9" rx="2" />
      <path d="M7 16h6M9 13v3" strokeLinecap="round" />
    </svg>
  );
}

function IconSun({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <circle cx="10" cy="10" r="3.5" />
      <path d="M10 3v2.2M10 14.8V17M3 10h2.2M14.8 10H17M5 5l1.6 1.6M13.4 13.4L15 15M15 5l-1.6 1.6M5 15l1.6-1.6" strokeLinecap="round" />
    </svg>
  );
}

function IconMoon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path
        d="M12.5 3.5a6.5 6.5 0 1 0 4 11.5 6 6 0 0 1-4-11.5z"
        strokeLinejoin="round"
      />
    </svg>
  );
}
