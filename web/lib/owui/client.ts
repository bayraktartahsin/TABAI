export type TAIUser = {
  id: string;
  email: string;
  username: string;
  displayName?: string | null;
  role: "ADMIN" | "USER";
  status: "ENABLED" | "FROZEN" | "DELETED";
};

export type OWUser = {
  id: string;
  email?: string;
  name?: string;
  role?: string;
  username?: string;
  status?: string;
  planTier?: "free" | "starter" | "pro" | "power";
  emailVerified?: boolean;
  verificationRequired?: boolean;
  entitlement?: {
    id: string;
    userId: string;
    planTier: "free" | "starter" | "pro" | "power";
    source: "free" | "apple" | "google" | "admin" | "web";
    status: "active" | "inactive" | "grace" | "cancelled" | "expired";
    startAt: string;
    expiresAt: string | null;
    autoRenew: boolean;
    externalProductId: string | null;
    externalOriginalTransactionId: string | null;
    lastValidatedAt: string | null;
    updatedAt: string;
  } | null;
};

export type OWModel = {
  id: string;
  name: string;
  displayName?: string;
  providerModelId?: string;
  logoUrl?: string;
  vendor?: string;
  capabilities?: string[];
  verified?: boolean;
  verificationStatus?: "verified" | "unverified" | "failed";
  pricingTier?: "free" | "paid";
  category?: string;
  requiredPlanTier?: "free" | "starter" | "pro" | "power";
  canAccess?: boolean;
  lockReason?: string | null;
  supportsTextChat?: boolean;
  supportsImageGeneration?: boolean;
  contextLength?: number | null;
  meta?: {
    profile_image_url?: string;
    provider?: string;
  };
  provider?: {
    id: string;
    name: string;
    slug: string;
    type: string;
    endpointUrl?: string | null;
  };
  supportsStreaming?: boolean;
  supportsVision?: boolean;
  supportsReasoning?: boolean;
};

export type OWMessage = { role: "system" | "user" | "assistant"; content: string };
export type StreamEvent = { event: string; data: any };

function getAPIBaseURL() {
  if (typeof window !== "undefined") {
    const meta = document.querySelector('meta[name="tai-api-base"]');
    if (meta) {
      const val = meta.getAttribute("content") || "";
      if (val) return val.replace(/\/+$/, "");
    }
  }
  const raw = process.env.NEXT_PUBLIC_TAI_API_BASE_URL || process.env.TAI_API_BASE_URL || "";
  return raw.replace(/\/+$/, "");
}

function resolveAPIURL(path: string) {
  if (/^https?:\/\//i.test(path)) return path;
  const base = getAPIBaseURL();
  if (!base) return path;
  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}

function getCsrfToken(): string {
  if (typeof document === "undefined") return "";
  const match = document.cookie.match(/tai_csrf=([^;]+)/);
  return match?.[1] ?? "";
}

async function readJsonOrThrow(res: Response): Promise<any> {
  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(text.trim() || "Unexpected non-JSON response.");
  }
}

function parseMaybeJson(value: string): any {
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function normalizeUser(input: any): OWUser | null {
  const user = input?.user ?? input;
  if (!user || typeof user !== "object") return null;
  return {
    id: String(user.id ?? ""),
    email: typeof user.email === "string" ? user.email : undefined,
    name:
      typeof user.displayName === "string"
        ? user.displayName
        : typeof user.name === "string"
          ? user.name
          : undefined,
    username: typeof user.username === "string" ? user.username : undefined,
    role: typeof user.role === "string" ? user.role : undefined,
    status: typeof user.status === "string" ? user.status : undefined,
    planTier:
      user.planTier === "free" || user.planTier === "starter" || user.planTier === "pro" || user.planTier === "power"
        ? user.planTier
        : undefined,
    emailVerified: user.emailVerified === true,
    verificationRequired: user.verificationRequired === true,
    entitlement:
      user.entitlement && typeof user.entitlement === "object"
        ? {
          id: String(user.entitlement.id ?? ""),
          userId: String(user.entitlement.userId ?? ""),
          planTier:
            user.entitlement.planTier === "free" || user.entitlement.planTier === "starter" || user.entitlement.planTier === "pro" || user.entitlement.planTier === "power"
              ? user.entitlement.planTier
              : "free",
          source:
            user.entitlement.source === "apple" || user.entitlement.source === "google" || user.entitlement.source === "admin" || user.entitlement.source === "web" || user.entitlement.source === "free"
              ? user.entitlement.source
              : "free",
          status:
            user.entitlement.status === "active" || user.entitlement.status === "inactive" || user.entitlement.status === "grace" || user.entitlement.status === "cancelled" || user.entitlement.status === "expired"
              ? user.entitlement.status
              : "inactive",
          startAt: String(user.entitlement.startAt ?? ""),
          expiresAt: typeof user.entitlement.expiresAt === "string" ? user.entitlement.expiresAt : null,
          autoRenew: user.entitlement.autoRenew === true,
          externalProductId: typeof user.entitlement.externalProductId === "string" ? user.entitlement.externalProductId : null,
          externalOriginalTransactionId: typeof user.entitlement.externalOriginalTransactionId === "string" ? user.entitlement.externalOriginalTransactionId : null,
          lastValidatedAt: typeof user.entitlement.lastValidatedAt === "string" ? user.entitlement.lastValidatedAt : null,
          updatedAt: String(user.entitlement.updatedAt ?? "")
        }
        : null
  };
}

export async function signup(input: { email: string; password: string; username?: string; displayName?: string }) {
  const res = await fetch(resolveAPIURL("/api/auth/signup"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify(input)
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) {
    const err = new Error(data?.error ?? "Sign up failed.") as Error & { code?: string };
    err.code = typeof data?.code === "string" ? data.code : undefined;
    throw err;
  }
  return data;
}

export async function requestVerification(email: string) {
  const res = await fetch(resolveAPIURL("/api/auth/verify/request"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify({ email })
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) throw new Error(data?.error ?? "Verification request failed.");
  return data;
}

export async function confirmVerification(token: string) {
  const res = await fetch(resolveAPIURL("/api/auth/verify/confirm"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify({ token })
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) {
    const err = new Error(data?.error ?? "Verification failed.") as Error & { code?: string };
    err.code = typeof data?.code === "string" ? data.code : undefined;
    throw err;
  }
  return data;
}

export async function requestPasswordReset(email: string) {
  const res = await fetch(resolveAPIURL("/api/auth/password-reset/request"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify({ email })
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) throw new Error(data?.error ?? "Password reset request failed.");
  return data;
}

export async function confirmPasswordReset(token: string, newPassword: string) {
  const res = await fetch(resolveAPIURL("/api/auth/password-reset/confirm"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify({ token, newPassword })
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) {
    const err = new Error(data?.error ?? "Password reset failed.") as Error & { code?: string };
    err.code = typeof data?.code === "string" ? data.code : undefined;
    throw err;
  }
  return data;
}

export async function signin(email: string, password: string): Promise<string> {
  const res = await fetch(resolveAPIURL("/api/auth/signin"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    body: JSON.stringify({ email, password })
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) {
    const err = new Error(data?.error ?? "Sign in failed.") as Error & { code?: string };
    err.code = typeof data?.code === "string" ? data.code : undefined;
    throw err;
  }
  return "session";
}

export async function signout(): Promise<void> {
  const res = await fetch(resolveAPIURL("/api/auth/signout"), {
    method: "POST",
    headers: { "X-CSRF-Token": getCsrfToken() },
    credentials: "include"
  });
  if (!res.ok) {
    const data = await readJsonOrThrow(res);
    throw new Error(data?.error ?? "Sign out failed.");
  }
}

export async function getMe(): Promise<OWUser | null> {
  const res = await fetch(resolveAPIURL("/api/auth/me"), {
    credentials: "include",
    cache: "no-store"
  });
  if (res.status === 401) return null;
  const data = await readJsonOrThrow(res);
  if (!res.ok) throw new Error(data?.error ?? "Failed to load session.");
  return normalizeUser(data);
}

export async function listModels(): Promise<OWModel[]> {
  const res = await fetch(resolveAPIURL("/api/models"), {
    credentials: "include",
    cache: "no-store"
  });
  const data = await readJsonOrThrow(res);
  if (!res.ok) throw new Error(data?.error ?? "Failed to load models.");
  const items = Array.isArray(data?.models) ? data.models : [];
  return items.map((item: any) => ({
    id: String(item.id),
    name: String(item.displayName ?? item.name ?? item.slug ?? item.providerModelId ?? item.id),
    displayName: typeof item.displayName === "string" ? item.displayName : undefined,
    providerModelId: typeof item.providerModelId === "string" ? item.providerModelId : undefined,
    logoUrl: typeof item.logoUrl === "string" ? item.logoUrl : undefined,
    vendor: typeof item.vendor === "string" ? item.vendor : undefined,
    capabilities: Array.isArray(item.capabilities) ? item.capabilities.filter((value: unknown) => typeof value === "string") : [],
    verified: item.verified === true,
    verificationStatus:
      item.verificationStatus === "verified" || item.verificationStatus === "failed" || item.verificationStatus === "unverified"
        ? item.verificationStatus
        : undefined,
    pricingTier: item.pricingTier === "free" || item.pricingTier === "paid" ? item.pricingTier : undefined,
    category: typeof item.category === "string" ? item.category : undefined,
    requiredPlanTier:
      item.requiredPlanTier === "free" || item.requiredPlanTier === "starter" || item.requiredPlanTier === "pro" || item.requiredPlanTier === "power"
        ? item.requiredPlanTier
        : undefined,
    canAccess: typeof item.canAccess === "boolean" ? item.canAccess : undefined,
    lockReason: typeof item.lockReason === "string" ? item.lockReason : null,
    contextLength: typeof item.contextLength === "number" ? item.contextLength : null,
    supportsStreaming: !!item.supportsStreaming,
    supportsVision: !!item.supportsVision,
    supportsReasoning: !!item.supportsReasoning,
    supportsImageGeneration: !!item.supportsImageGeneration,
    supportsTextChat: item.supportsTextChat !== false,
    provider: item.provider
      ? {
        id: String(item.provider.id),
        name: String(item.provider.name),
        slug: String(item.provider.slug),
        type: String(item.provider.type),
        endpointUrl: item.provider.endpointUrl ?? null
      }
      : undefined,
    meta: {
      profile_image_url: typeof item.logoUrl === "string" ? item.logoUrl : undefined,
      provider: typeof item.vendor === "string" ? item.vendor : item.provider?.slug
    }
  }));
}

export async function chatCompletionStream(
  _token: string,
  model: string,
  messages: OWMessage[],
  opts: {
    attachments?: unknown[];
    signal?: AbortSignal;
    chatId?: string;
    onEvent?: (event: StreamEvent) => void;
    onToken?: (delta: string) => void;
    onDone?: (result: { finishReason?: string; raw?: any; chatId?: string; messageId?: string }) => void;
  } = {}
): Promise<void> {
  const res = await fetch(resolveAPIURL("/api/chat/stream"), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": getCsrfToken() },
    credentials: "include",
    signal: opts.signal,
    body: JSON.stringify({
      model,
      messages,
      attachments: opts.attachments,
      chatId: opts.chatId
    })
  });

  if (!res.ok) {
    const text = await res.text();
    const parsed = parseMaybeJson(text);
    throw new Error(typeof parsed === "string" ? parsed : parsed?.error ?? "Streaming request failed.");
  }

  if (!res.body) {
    throw new Error("Streaming response body is empty.");
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  const emitEvent = (eventName: string, rawData: string) => {
    const data = parseMaybeJson(rawData);
    opts.onEvent?.({ event: eventName, data });
    if (eventName === "token" && typeof data?.delta === "string") {
      opts.onToken?.(data.delta);
    }
    if (eventName === "done") {
      opts.onDone?.({
        finishReason: typeof data?.finishReason === "string" ? data.finishReason : undefined,
        chatId: typeof data?.chatId === "string" ? data.chatId : undefined,
        messageId: typeof data?.messageId === "string" ? data.messageId : undefined,
        raw: data
      });
    }
  };

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    let boundary = buffer.indexOf("\n\n");
    while (boundary >= 0) {
      const block = buffer.slice(0, boundary);
      buffer = buffer.slice(boundary + 2);

      const lines = block.split("\n");
      let eventName = "message";
      const dataLines: string[] = [];

      for (const lineRaw of lines) {
        const line = lineRaw.replace(/\r$/, "");
        if (line.startsWith("event:")) {
          eventName = line.slice(6).trim();
        } else if (line.startsWith("data:")) {
          dataLines.push(line.slice(5).trim());
        }
      }

      if (dataLines.length > 0) {
        emitEvent(eventName, dataLines.join("\n"));
      }

      boundary = buffer.indexOf("\n\n");
    }
  }
}
