export type ChatMsg = {
  id: string;
  role: "system" | "user" | "assistant" | "tool";
  content: string;
  sequence?: number;
  isDeleted?: boolean;
};

export type LocalChat = {
  id: string;
  title: string;
  updatedAt: number;
  createdAt?: number;
  folderId?: string | null;
  modelId?: string | null;
  modelName?: string | null;
  modelVendor?: string | null;
  modelLogoUrl?: string | null;
  isDeleted?: boolean;
  messages: ChatMsg[];
};

export function newChat(): LocalChat {
  return {
    id: crypto.randomUUID(),
    title: "New chat",
    updatedAt: Date.now(),
    createdAt: Date.now(),
    folderId: null,
    modelId: null,
    modelName: null,
    modelVendor: null,
    modelLogoUrl: null,
    messages: []
  };
}

export function computeTitle(messages: ChatMsg[]): string {
  const firstUser = messages.find((m) => m.role === "user")?.content?.trim() ?? "";
  if (!firstUser) return "New chat";
  const single = firstUser.replace(/\s+/g, " ");
  return single.length > 42 ? `${single.slice(0, 42)}…` : single;
}
