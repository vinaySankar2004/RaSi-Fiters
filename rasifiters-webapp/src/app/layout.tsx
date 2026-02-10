import type { Metadata } from "next";
import { Manrope } from "next/font/google";
import "./globals.css";
import { AppProviders } from "@/app/providers";
import { AppShell } from "@/app/shell";

const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap"
});

export const metadata: Metadata = {
  title: "RaSi Fiters",
  description: "RaSi Fiters web app",
  icons: {
    icon: [
      { url: "/brand/app-icon.png", media: "(prefers-color-scheme: light)" },
      { url: "/brand/app-icon-dark.png", media: "(prefers-color-scheme: dark)" }
    ],
    apple: [
      { url: "/brand/app-icon.png", media: "(prefers-color-scheme: light)" },
      { url: "/brand/app-icon-dark.png", media: "(prefers-color-scheme: dark)" }
    ]
  }
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={manrope.variable}>
      <body>
        <AppProviders>
          <AppShell>{children}</AppShell>
        </AppProviders>
      </body>
    </html>
  );
}
