import type { LocalChat, ChatMsg } from "@/lib/chats/store";
import type { OWModel, OWUser } from "@/lib/owui/client";

export type TAISettings = {
  theme?: string | null;
  language?: string | null;
  notificationsEnabled?: boolean;
  voiceSessionEnabled?: boolean;
};

export type BootstrapResponse = {
  user: OWUser;
  models: any[];
  chats: any[];
  settings: TAISettings;
};

export type FolderRecord = {
  id: string;
  name: string;
  color?: string | null;
  createdAt: string;
  updatedAt: string;
};

function parseJson(text: string) {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function requestJson<T>(input: RequestInfo, init?: RequestInit): Promise<T> {
  const resolvedInput =
    typeof input === "string" ? resolveAPIURL(input) : input;
  const res = await fetch(resolvedInput, {
    credentials: "include",
    cache: "no-store",
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {})
    }
  });
  const raw = await res.text();
  const data = parseJson(raw);
  if (!res.ok) {
    throw new Error(typeof data === "string" ? data : data?.error ?? "Request failed.");
  }
  return data as T;
}

export function getAPIBaseURL() {
  const runtime =
    typeof window !== "undefined" && typeof (window as typeof window & { __TAI_API_BASE_URL__?: string }).__TAI_API_BASE_URL__ === "string"
      ? (window as typeof window & { __TAI_API_BASE_URL__?: string }).__TAI_API_BASE_URL__
      : "";
  const raw = runtime || process.env.NEXT_PUBLIC_TAI_API_BASE_URL || process.env.TAI_API_BASE_URL || "";
  return raw.replace(/\/+$/, "");
}

export function resolveAPIURL(path: string) {
  if (/^https?:\/\//i.test(path)) return path;
  const base = getAPIBaseURL();
  if (!base) return path;
  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}

function normalizeChat(chat: any): LocalChat {
  return {
    id: String(chat.id),
    title: String(chat.title ?? "New chat"),
    updatedAt: new Date(chat.updatedAt ?? Date.now()).getTime(),
    createdAt: new Date(chat.createdAt ?? Date.now()).getTime(),
    folderId: typeof chat.folderId === "string" ? chat.folderId : null,
    modelId: typeof chat.modelId === "string" ? chat.modelId : null,
    modelName: typeof chat.model?.displayName === "string"
      ? chat.model.displayName
      : typeof chat.model?.name === "string"
        ? chat.model.name
        : typeof chat.displayModelName === "string"
          ? chat.displayModelName
          : null,
    modelVendor:
      typeof chat.model?.vendor === "string"
        ? chat.model.vendor
        : typeof chat.model?.provider?.slug === "string"
          ? chat.model.provider.slug
          : null,
    modelLogoUrl:
      typeof chat.model?.logoUrl === "string"
        ? chat.model.logoUrl
        : typeof chat.displayModelLogoUrl === "string"
          ? chat.displayModelLogoUrl
          : null,
    isDeleted: !!chat.isDeleted,
    messages: Array.isArray(chat.messages)
      ? chat.messages.map(normalizeMessage)
      : []
  };
}

function normalizeMessage(message: any): ChatMsg {
  return {
    id: String(message.id),
    role: String(message.role ?? "USER").toLowerCase() as ChatMsg["role"],
    content: String(message.content ?? ""),
    sequence: typeof message.sequence === "number" ? message.sequence : undefined,
    isDeleted: !!message.isDeleted
  };
}

function normalizeModel(model: any): OWModel {
  return {
    id: String(model.id),
    name: String(model.displayName ?? model.name ?? model.slug ?? model.providerModelId ?? model.id),
    displayName: typeof model.displayName === "string" ? model.displayName : undefined,
    providerModelId: typeof model.providerModelId === "string" ? model.providerModelId : undefined,
    logoUrl: typeof model.logoUrl === "string" ? model.logoUrl : undefined,
    vendor: typeof model.vendor === "string" ? model.vendor : undefined,
    capabilities: Array.isArray(model.capabilities) ? model.capabilities.filter((value: unknown) => typeof value === "string") : [],
    verified: model.verified === true,
    verificationStatus:
      model.verificationStatus === "verified" || model.verificationStatus === "failed" || model.verificationStatus === "unverified"
        ? model.verificationStatus
        : undefined,
    pricingTier: model.pricingTier === "free" || model.pricingTier === "paid" ? model.pricingTier : undefined,
    category: typeof model.category === "string" ? model.category : undefined,
    requiredPlanTier:
      model.requiredPlanTier === "free" || model.requiredPlanTier === "starter" || model.requiredPlanTier === "pro" || model.requiredPlanTier === "power"
        ? model.requiredPlanTier
        : undefined,
    canAccess: typeof model.canAccess === "boolean" ? model.canAccess : undefined,
    lockReason: typeof model.lockReason === "string" ? model.lockReason : null,
    contextLength: typeof model.contextLength === "number" ? model.contextLength : null,
    supportsStreaming: !!model.supportsStreaming,
    supportsVision: !!model.supportsVision,
    supportsReasoning: !!model.supportsReasoning,
    supportsImageGeneration: !!model.supportsImageGeneration,
    supportsTextChat: model.supportsTextChat !== false,
    provider: model.provider
      ? {
        id: String(model.provider.id),
        name: String(model.provider.name),
        slug: String(model.provider.slug),
        type: String(model.provider.type),
        endpointUrl: model.provider.endpointUrl ?? null
      }
      : undefined,
    meta: {
      profile_image_url: typeof model.logoUrl === "string" ? model.logoUrl : undefined,
      provider: typeof model.vendor === "string" ? model.vendor : model.provider?.slug
    }
  };
}

export async function getCurrentUserProfile() {
  const data = await requestJson<{ user: OWUser | null }>("/api/auth/me", {
    method: "GET"
  });
  return data.user;
}

export async function getBootstrap() {
  const data = await requestJson<BootstrapResponse>("/api/bootstrap", {
    method: "GET"
  });
  return {
    user: data.user,
    models: Array.isArray(data.models) ? data.models.map(normalizeModel) : [],
    chats: data.chats.map(normalizeChat),
    settings: data.settings
  };
}

export async function listChats() {
  const data = await requestJson<{ chats: any[] }>("/api/chats", { method: "GET" });
  return data.chats.map(normalizeChat);
}

export async function createChat(input: { title?: string; folderId?: string | null; modelId?: string | null }) {
  const data = await requestJson<{ chat: any }>("/api/chats", {
    method: "POST",
    body: JSON.stringify(input)
  });
  return normalizeChat(data.chat);
}

export async function updateChat(chatId: string, input: { title?: string; folderId?: string | null; modelId?: string | null; isPinned?: boolean }) {
  const data = await requestJson<{ chat: any }>(`/api/chats/${chatId}`, {
    method: "PATCH",
    body: JSON.stringify(input)
  });
  return normalizeChat(data.chat);
}

export async function deleteChat(chatId: string, purge = false) {
  return requestJson<{ ok: boolean; deleted: string }>(`/api/chats/${chatId}${purge ? "?purge=1" : ""}`, {
    method: "DELETE"
  });
}

export async function listMessages(chatId: string) {
  const data = await requestJson<{ messages: any[] }>(`/api/chats/${chatId}/messages`, {
    method: "GET"
  });
  return data.messages.map(normalizeMessage);
}

export async function createMessage(chatId: string, input: {
  role: "SYSTEM" | "USER" | "ASSISTANT" | "TOOL";
  content: string;
  editedFromId?: string | null;
  parentMessageId?: string | null;
  metadata?: unknown;
}) {
  const data = await requestJson<{ message: any }>(`/api/chats/${chatId}/messages`, {
    method: "POST",
    body: JSON.stringify(input)
  });
  return normalizeMessage(data.message);
}

export async function listFolders() {
  const data = await requestJson<{ folders: FolderRecord[] }>("/api/folders", { method: "GET" });
  return data.folders;
}

export async function createFolder(input: { name: string; color?: string }) {
  const data = await requestJson<{ folder: FolderRecord }>("/api/folders", {
    method: "POST",
    body: JSON.stringify(input)
  });
  return data.folder;
}

export async function updateFolder(folderId: string, input: { name: string; color?: string | null }) {
  const data = await requestJson<{ folder: FolderRecord }>(`/api/folders/${folderId}`, {
    method: "PATCH",
    body: JSON.stringify(input)
  });
  return data.folder;
}

export async function deleteFolder(folderId: string) {
  return requestJson<{ ok: boolean }>(`/api/folders/${folderId}`, {
    method: "DELETE"
  });
}
