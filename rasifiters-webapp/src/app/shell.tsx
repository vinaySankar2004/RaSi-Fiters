"use client";

import Link from "next/link";
import { useEffect } from "react";
import { usePathname } from "next/navigation";

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const showNav = ["/summary", "/members", "/lifestyle", "/program"].includes(pathname);

  useEffect(() => {
    const body = document.body;
    body.classList.remove("modal-open");
    body.style.overflow = "";
  }, [pathname]);

  return (
    <div className="app-bg">
      <div
        className="app-glow"
        style={{
          top: "18%",
          left: "12%",
          width: 260,
          height: 260,
          opacity: 0.22,
          background: "radial-gradient(circle, rgba(255, 182, 120, 0.7), transparent 70%)"
        }}
      />
      <div
        className="app-glow"
        style={{
          bottom: "20%",
          right: "16%",
          width: 300,
          height: 300,
          opacity: 0.18,
          background: "radial-gradient(circle, rgba(156, 190, 255, 0.6), transparent 70%)"
        }}
      />
      <main className={`relative z-10 min-h-screen ${showNav ? "pb-28" : ""}`}>
        {children}
      </main>

      {showNav && (
        <nav className="bottom-nav fixed bottom-6 left-1/2 z-20 w-[min(92vw,520px)] -translate-x-1/2 rounded-3xl bg-white/90 px-4 py-3 shadow-2xl backdrop-blur">
          <div className="flex items-center justify-between">
            {[
              { href: "/summary", label: "Summary", icon: SummaryIcon },
              { href: "/members", label: "Members", icon: MembersIcon },
              { href: "/lifestyle", label: "Lifestyle", icon: LifestyleIcon },
              { href: "/program", label: "Program", icon: ProgramIcon }
            ].map((tab) => {
              const active = pathname.startsWith(tab.href);
              const Icon = tab.icon;
              return (
                <Link
                  key={tab.href}
                  href={tab.href}
                  className={`flex w-20 flex-col items-center gap-1 rounded-2xl px-3 py-2 text-xs font-semibold transition ${
                    active ? "bg-rf-surface-muted text-rf-accent" : "text-rf-text-muted hover:text-rf-text"
                  }`}
                >
                  <Icon active={active} />
                  {tab.label}
                </Link>
              );
            })}
          </div>
        </nav>
      )}
    </div>
  );
}

function SummaryIcon({ active }: { active: boolean }) {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
      <rect x="2" y="9" width="3" height="7" rx="1.2" fill={active ? "#ff8b1f" : "#9aa0aa"} />
      <rect x="8.5" y="6" width="3" height="10" rx="1.2" fill={active ? "#ff8b1f" : "#9aa0aa"} />
      <rect x="15" y="3" width="3" height="13" rx="1.2" fill={active ? "#ff8b1f" : "#9aa0aa"} />
    </svg>
  );
}

function MembersIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="20" viewBox="0 0 22 20" fill="none" aria-hidden="true">
      <circle cx="7" cy="6" r="3" fill={active ? "#ff8b1f" : "#9aa0aa"} />
      <circle cx="15.5" cy="7" r="2.6" fill={active ? "#ff8b1f" : "#9aa0aa"} opacity="0.8" />
      <path
        d="M2 18c0-2.8 2.6-5 5.8-5s5.8 2.2 5.8 5"
        stroke={active ? "#ff8b1f" : "#9aa0aa"}
        strokeWidth="2"
        strokeLinecap="round"
      />
      <path
        d="M12 17c.4-1.8 2-3.2 4.1-3.2 2.2 0 3.9 1.4 4 3.2"
        stroke={active ? "#ff8b1f" : "#9aa0aa"}
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

function LifestyleIcon({ active }: { active: boolean }) {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
      <path
        d="M15.5 4.5c-4.7.4-8.8 3.2-10.5 8.1 3.3-.2 6-1.1 8-2.8 2.4-2 3.2-4.4 2.5-5.3z"
        fill={active ? "#ff8b1f" : "#9aa0aa"}
      />
      <path
        d="M6.2 15.5c2.3.6 4.6-.2 6.2-1.8"
        stroke={active ? "#ff8b1f" : "#9aa0aa"}
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  );
}

function ProgramIcon({ active }: { active: boolean }) {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
      <rect x="2" y="2" width="7" height="7" rx="2" fill={active ? "#ff8b1f" : "#9aa0aa"} />
      <rect x="11" y="2" width="7" height="7" rx="2" fill={active ? "#ff8b1f" : "#9aa0aa"} opacity="0.85" />
      <rect x="2" y="11" width="7" height="7" rx="2" fill={active ? "#ff8b1f" : "#9aa0aa"} opacity="0.85" />
      <rect x="11" y="11" width="7" height="7" rx="2" fill={active ? "#ff8b1f" : "#9aa0aa"} />
    </svg>
  );
}
