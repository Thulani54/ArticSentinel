export const priorities = ["low", "normal", "high", "critical", "emergency"];
export const statuses = [
  "scheduled",
  "in_progress",
  "completed",
  "cancelled",
  "overdue",
];
export const frequencies = [
  "daily",
  "weekly",
  "monthly",
  "quarterly",
  "semi_annual",
  "annual",
  "custom",
];
export const outcomes = ["successful", "partial", "failed", "needs_follow_up"];
export const observationCategories = [
  "general",
  "safety",
  "performance",
  "issue",
  "recommendation",
  "follow_up",
  "quality",
  "compliance",
];
export function localDateTime(value) {
  if (!value) return "";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "";
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
}
export function maintenancePayload(form) {
  const result = { ...form };
  for (const key of [
    "device_id",
    "assigned_to_id",
    "performed_by_id",
    "auto_assign_to_id",
    "estimated_cost",
    "actual_cost",
    "estimated_duration_hours",
    "custom_frequency_days",
  ]) {
    if (key in result)
      result[key] =
        result[key] === "" || result[key] == null ? null : Number(result[key]);
  }
  for (const key of ["scheduled_date", "actual_start_date", "actual_end_date"])
    if (result[key]) result[key] = new Date(result[key]).toISOString();
  for (const key of ["parts_used", "materials_used"])
    if (typeof result[key] === "string")
      result[key] = result[key]
        .split("\n")
        .map((s) => s.trim())
        .filter(Boolean);
  if ("checklist" in result) {
    result.checklist_items = result.checklist
      .split("\n")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((description) => ({ description }));
    delete result.checklist;
  }
  if (result.frequency === "custom" && !(result.custom_frequency_days > 0))
    throw new Error("Custom frequency must be at least one day.");
  if (
    result.end_date &&
    result.start_date &&
    result.end_date < result.start_date
  )
    throw new Error("End date must be on or after the start date.");
  return result;
}
export function mediaUrl(value) {
  try {
    const url = new URL(
      typeof value === "string" ? value : value?.url,
      "https://api.articsentinel.com",
    );
    return ["https:", "http:"].includes(url.protocol) ? url.href : null;
  } catch {
    return null;
  }
}
