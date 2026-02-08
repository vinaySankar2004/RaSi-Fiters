export function formatDateRange(start?: string | null, end?: string | null) {
  const startText = formatShortDate(start) ?? "Start";
  const endText = formatShortDate(end) ?? "End";
  return `${startText} – ${endText}`;
}

export function formatShortDate(dateString?: string | null) {
  if (!dateString) return null;
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

export function formatInviteDate(dateString?: string | null) {
  if (!dateString) return "Invited recently";
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return "Invited recently";
  return `Invited on ${date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  })}`;
}
