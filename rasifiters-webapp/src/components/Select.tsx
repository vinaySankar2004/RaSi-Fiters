"use client";

import { useEffect, useMemo, useRef, useState } from "react";

type Option = {
  value: string;
  label: string;
};

type SelectProps = {
  label?: string;
  value: string;
  options: Option[];
  onChange: (value: string) => void;
  disabled?: boolean;
  placeholder?: string;
  className?: string;
  searchable?: boolean;
};

export function Select({
  label,
  value,
  options,
  onChange,
  disabled,
  placeholder = "Select option",
  className,
  searchable
}: SelectProps) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapperRef = useRef<HTMLDivElement | null>(null);
  const searchRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    const handler = (event: MouseEvent) => {
      if (!wrapperRef.current || !(event.target instanceof Node)) return;
      if (!wrapperRef.current.contains(event.target)) {
        setOpen(false);
        setSearch("");
      }
    };

    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  useEffect(() => {
    if (open && searchable) {
      requestAnimationFrame(() => searchRef.current?.focus());
    }
  }, [open, searchable]);

  const selected = options.find((option) => option.value === value);

  const filtered = useMemo(() => {
    if (!searchable || !search.trim()) return options;
    const q = search.trim().toLowerCase();
    return options.filter((option) => option.label.toLowerCase().includes(q));
  }, [options, search, searchable]);

  return (
    <div ref={wrapperRef} className={`relative ${className ?? ""}`}>
      {label && <p className="text-sm font-semibold text-rf-text">{label}</p>}
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((prev) => !prev)}
        className="input-shell mt-2 flex w-full items-center justify-between rounded-2xl px-4 py-3 text-sm font-medium text-rf-text"
      >
        <span className={`capitalize ${!value ? "text-rf-text-muted" : ""}`}>
          {value ? selected?.label ?? value : placeholder}
        </span>
        <span className={`text-xs ${open ? "rotate-180" : ""} transition`}>⌄</span>
      </button>

      {open && (
        <div className="absolute z-20 mt-2 w-full rounded-2xl border border-rf-border bg-rf-surface text-rf-text shadow-2xl">
          {searchable && (
            <div className="border-b border-rf-border px-3 py-2">
              <input
                ref={searchRef}
                type="text"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Search..."
                className="w-full bg-transparent text-sm font-medium text-rf-text outline-none placeholder:text-rf-text-muted"
              />
            </div>
          )}
          <div className="max-h-60 overflow-auto overscroll-contain py-1">
            {filtered.length === 0 ? (
              <p className="px-4 py-3 text-sm text-rf-text-muted">No results</p>
            ) : (
              filtered.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => {
                    onChange(option.value);
                    setOpen(false);
                    setSearch("");
                  }}
                  className={`flex w-full items-center px-4 py-3 text-left text-sm font-semibold capitalize transition ${
                    option.value === value
                      ? "bg-rf-accent/15 text-rf-text"
                      : "text-rf-text-muted hover:bg-rf-surface-muted"
                  }`}
                >
                  {option.label}
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
