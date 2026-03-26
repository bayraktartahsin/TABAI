"use client";

import type { LocalChat } from "@/lib/chats/store";
import type { OWUser } from "@/lib/owui/client";
import type { TAISettings } from "@/lib/tai/client";

type BootstrapCacheRecord = {
  user: OWUser | null;
  chats: LocalChat[];
  settings: TAISettings | null;
  models: unknown[];
  updatedAt: number;
};

const DB_NAME = "tai-cache";
const STORE_NAME = "bootstrap";
const CACHE_KEY = "latest";

function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => {
      request.result.createObjectStore(STORE_NAME);
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error ?? new Error("IndexedDB open failed."));
  });
}

export async function loadBootstrapCache(): Promise<BootstrapCacheRecord | null> {
  if (typeof window === "undefined" || typeof indexedDB === "undefined") return null;
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, "readonly");
    const store = tx.objectStore(STORE_NAME);
    const request = store.get(CACHE_KEY);
    request.onsuccess = () => resolve((request.result as BootstrapCacheRecord | undefined) ?? null);
    request.onerror = () => reject(request.error ?? new Error("IndexedDB read failed."));
  });
}

export async function saveBootstrapCache(record: BootstrapCacheRecord) {
  if (typeof window === "undefined" || typeof indexedDB === "undefined") return;
  const db = await openDB();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, "readwrite");
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error ?? new Error("IndexedDB write failed."));
    tx.objectStore(STORE_NAME).put(record, CACHE_KEY);
  });
}

export async function clearBootstrapCache() {
  if (typeof window === "undefined" || typeof indexedDB === "undefined") return;
  const db = await openDB();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, "readwrite");
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error ?? new Error("IndexedDB delete failed."));
    tx.objectStore(STORE_NAME).delete(CACHE_KEY);
  });
}
