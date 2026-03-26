const KEY = "tai.models.enabled_ids";

export type EnabledConfig =
  | { mode: "all" }
  | { mode: "custom"; ids: Set<string> };

// Missing key => all enabled. Present key => custom list (can be empty => none).
export function getEnabledConfig(): EnabledConfig {
  if (typeof window === "undefined") return { mode: "all" };
  const raw = localStorage.getItem(KEY);
  if (raw === null) return { mode: "all" };
  try {
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return { mode: "all" };
    const ids = new Set(arr.filter((x) => typeof x === "string"));
    return { mode: "custom", ids };
  } catch {
    return { mode: "all" };
  }
}

export function setCustomEnabledIds(ids: Iterable<string>) {
  if (typeof window === "undefined") return;
  const arr = Array.from(new Set(Array.from(ids)));
  localStorage.setItem(KEY, JSON.stringify(arr));
}

export function enableAllModels() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(KEY);
}

