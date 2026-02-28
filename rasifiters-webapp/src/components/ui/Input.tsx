"use client";

import { cn } from "@/lib/utils";
import { forwardRef } from "react";

type InputProps = {
  label?: string;
  error?: string;
  wrapperClassName?: string;
} & React.InputHTMLAttributes<HTMLInputElement>;

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, error, wrapperClassName, className, ...rest },
  ref
) {
  return (
    <div className={wrapperClassName}>
      {label && (
        <label className="text-sm font-semibold text-rf-text">{label}</label>
      )}
      <input
        ref={ref}
        className={cn(
          "input-shell w-full rounded-2xl px-4 py-3 text-sm font-medium",
          label && "mt-2",
          className
        )}
        {...rest}
      />
      {error && (
        <p className="mt-2 text-xs font-semibold text-rf-danger">{error}</p>
      )}
    </div>
  );
});
