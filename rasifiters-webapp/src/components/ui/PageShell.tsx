"use client";

import { cn } from "@/lib/utils";

const maxWidthMap = {
  md: "max-w-md",
  "2xl": "max-w-2xl",
  "3xl": "max-w-3xl",
  "4xl": "max-w-4xl",
  "5xl": "max-w-5xl"
} as const;

type MaxWidth = keyof typeof maxWidthMap;

export function PageShell({
  maxWidth = "5xl",
  className,
  children
}: {
  maxWidth?: MaxWidth;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen px-6 pb-16 pt-10 text-rf-text sm:px-10">
      <div className={cn("mx-auto w-full space-y-6", maxWidthMap[maxWidth], className)}>
        {children}
      </div>
    </div>
  );
}
