import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/app/**/*.{ts,tsx}",
    "./src/components/**/*.{ts,tsx}",
    "./src/lib/**/*.{ts,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        "rf-bg": "var(--rf-bg)",
        "rf-surface": "var(--rf-surface)",
        "rf-surface-muted": "var(--rf-surface-muted)",
        "rf-border": "var(--rf-border)",
        "rf-text": "var(--rf-text)",
        "rf-text-muted": "var(--rf-text-muted)",
        "rf-accent": "var(--rf-accent)",
        "rf-accent-strong": "var(--rf-accent-strong)",
        "rf-success": "var(--rf-success)",
        "rf-danger": "var(--rf-danger)",
        "rf-shadow": "var(--rf-shadow)"
      },
      boxShadow: {
        "rf-soft": "0 12px 30px rgba(15, 18, 25, 0.08)",
        "rf-pill": "0 8px 18px rgba(17, 20, 26, 0.12)"
      },
      borderRadius: {
        "2xl": "1.25rem",
        "3xl": "1.75rem"
      },
      fontFamily: {
        sans: ["var(--font-sans)", "ui-sans-serif", "system-ui", "-apple-system", "Segoe UI", "sans-serif"]
      }
    }
  },
  plugins: []
};

export default config;
