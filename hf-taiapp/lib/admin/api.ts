import { resolveAPIURL } from "@/lib/tai/client";

export async function adminFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const res = await fetch(resolveAPIURL(path), { credentials: "include", ...opts });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error ?? `Request failed (${res.status})`);
  return data;
}

export async function adminPost<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return adminFetch(path, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
}

export async function adminPatch<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return adminFetch(path, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
}

export async function adminPut<T>(path: string, body: Record<string, unknown>): Promise<T> {
  return adminFetch(path, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
}

export async function adminDelete(path: string): Promise<void> {
  await adminFetch(path, { method: "DELETE" });
}
