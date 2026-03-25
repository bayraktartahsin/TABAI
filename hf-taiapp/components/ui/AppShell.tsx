"use client";

import React from "react";
import Sidebar from "@/components/ui/Sidebar";
import ChatScreen from "@/components/chat/ChatScreen";
import LoginScreen from "@/components/ui/LoginScreen";
import CommandPalette from "@/components/commands/CommandPalette";
import { clearBootstrapCache, loadBootstrapCache, saveBootstrapCache } from "@/lib/client/bootstrap-cache";
import { signout, type OWUser } from "@/lib/owui/client";
import {
  createChat,
  createMessage,
  createFolder,
  deleteChat,
  deleteFolder,
  getBootstrap,
  listChats,
  listFolders,
  listMessages,
  updateChat,
  updateFolder
} from "@/lib/tai/client";
import type { LocalChat, ChatMsg } from "@/lib/chats/store";

const ACTIVE_CHAT_KEY = "tai.active_chat_id";

function getStoredActiveChatId() {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(ACTIVE_CHAT_KEY);
}

function setStoredActiveChatId(id: string | null) {
  if (typeof window === "undefined") return;
  if (id) localStorage.setItem(ACTIVE_CHAT_KEY, id);
  else localStorage.removeItem(ACTIVE_CHAT_KEY);
}

function getRequestedChatId() {
  if (typeof window === "undefined") return null;
  return new URLSearchParams(window.location.search).get("chat");
}

function setRequestedChatId(id: string | null) {
  if (typeof window === "undefined") return;
  const url = new URL(window.location.href);
  if (id) url.searchParams.set("chat", id);
  else url.searchParams.delete("chat");
  window.history.replaceState({}, "", url);
}

export default function AppShell() {
  const [user, setUser] = React.useState<OWUser | null>(null);
  const [booting, setBooting] = React.useState(true);
  const [loadingChats, setLoadingChats] = React.useState(false);
  const [chats, setChats] = React.useState<LocalChat[]>([]);
  const [folders, setFolders] = React.useState<Array<{ id: string; name: string; color?: string | null }>>([]);
  const [activeId, setActiveId] = React.useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = React.useState(true);

  React.useEffect(() => {
    if (typeof window === "undefined") return;
    setSidebarOpen(window.innerWidth >= 901);
  }, []);

  const hydrateChatMessages = React.useCallback(async (chatId: string) => {
    const messages = await listMessages(chatId);
    setChats((current) =>
      current.map((chat) => (chat.id === chatId ? { ...chat, messages } : chat))
    );
  }, []);

  const refreshFolders = React.useCallback(async () => {
    const next = await listFolders();
    setFolders(next.map((folder) => ({ id: folder.id, name: folder.name, color: folder.color })));
  }, []);

  const refreshChats = React.useCallback(async () => {
    setLoadingChats(true);
    try {
      const next = await listChats();
      setChats((current) => {
        const currentById = new Map(current.map((chat) => [chat.id, chat]));
        return next.map((chat) => ({
          ...chat,
          messages: currentById.get(chat.id)?.messages ?? chat.messages
        }));
      });

      const stored = getStoredActiveChatId();
      const requested = getRequestedChatId();
      const candidate =
        requested && next.some((chat) => chat.id === requested)
          ? requested
          : stored && next.some((chat) => chat.id === stored)
            ? stored
            : next[0]?.id ?? null;
      setActiveId((prev) => {
        const nextId = prev && next.some((chat) => chat.id === prev) ? prev : candidate;
        setStoredActiveChatId(nextId);
        setRequestedChatId(nextId);
        return nextId;
      });
    } finally {
      setLoadingChats(false);
    }
  }, []);

  const applyChatSelection = React.useCallback((next: LocalChat[]) => {
    const stored = getStoredActiveChatId();
    const requested = getRequestedChatId();
    const candidate =
      requested && next.some((chat) => chat.id === requested)
        ? requested
        : stored && next.some((chat) => chat.id === stored)
          ? stored
          : next[0]?.id ?? null;
    setActiveId((prev) => {
      const nextId = prev && next.some((chat) => chat.id === prev) ? prev : candidate;
      setStoredActiveChatId(nextId);
      setRequestedChatId(nextId);
      return nextId;
    });
  }, []);

  const applyBootstrap = React.useCallback((payload: {
    user: OWUser | null;
    chats: LocalChat[];
  }) => {
    setUser(payload.user);
    setChats((current) => {
      const currentById = new Map(current.map((chat) => [chat.id, chat]));
      return payload.chats.map((chat) => ({
        ...chat,
        messages: currentById.get(chat.id)?.messages ?? chat.messages
      }));
    });
    applyChatSelection(payload.chats);
  }, [applyChatSelection]);

  const boot = React.useCallback(async () => {
    setBooting(true);
    try {
      const cached = await loadBootstrapCache().catch(() => null);
      if (cached?.user) {
        applyBootstrap({ user: cached.user, chats: cached.chats });
        setBooting(false);
      }

      const bootstrap = await getBootstrap().catch(() => null);
      if (!bootstrap?.user) {
        setChats([]);
        setFolders([]);
        setUser(null);
        setActiveId(null);
        setStoredActiveChatId(null);
        await clearBootstrapCache().catch(() => undefined);
        return;
      }

      applyBootstrap({ user: bootstrap.user, chats: bootstrap.chats });
      await saveBootstrapCache({
        user: bootstrap.user,
        chats: bootstrap.chats,
        models: bootstrap.models,
        settings: bootstrap.settings ?? null,
        updatedAt: Date.now()
      }).catch(() => undefined);

      setBooting(false);
      void refreshFolders();
    } finally {
      setBooting(false);
    }
  }, [applyBootstrap, refreshFolders]);

  React.useEffect(() => {
    void boot();
  }, [boot]);

  React.useEffect(() => {
    if (!activeId) return;
    const chat = chats.find((item) => item.id === activeId);
    if (chat && chat.messages.length > 0) return;
    void hydrateChatMessages(activeId);
  }, [activeId, chats, hydrateChatMessages]);

  React.useEffect(() => {
    setRequestedChatId(activeId);
  }, [activeId]);

  const activeChat = React.useMemo(
    () => chats.find((chat) => chat.id === activeId) ?? null,
    [activeId, chats]
  );

  const replaceChat = React.useCallback((chatId: string, updater: (chat: LocalChat) => LocalChat) => {
    setChats((current) =>
      current
        .map((chat) => (chat.id === chatId ? updater(chat) : chat))
        .sort((a, b) => b.updatedAt - a.updatedAt)
    );
  }, []);

  const ensureActiveChat = React.useCallback(
    async (modelId?: string | null) => {
      if (activeChat && activeChat.modelId === (modelId ?? null)) return activeChat;
      const created = await createChat({
        title: "New chat",
        modelId: modelId ?? null
      });
      setChats((current) => [created, ...current]);
      setActiveId(created.id);
      setStoredActiveChatId(created.id);
      return created;
    },
    [activeChat]
  );

  if (booting) {
    return (
      <main
        className="ds-main"
        style={{ minHeight: "100dvh", display: "grid", placeItems: "center", padding: 24 }}
      >
        <div style={{ textAlign: "center" }}>
          <div style={{ fontSize: 32, fontWeight: 700, color: "#59CCB3", letterSpacing: 1.5 }}>TABAI</div>
          <div style={{ color: "var(--ds-text-2)", marginTop: 8, fontSize: 13 }}>Loading...</div>
        </div>
      </main>
    );
  }

  if (!user) {
    return (
      <main
        className="ds-main"
        style={{
          minHeight: "100dvh",
          display: "grid",
          placeItems: "center",
          padding: 24
        }}
      >
        <LoginScreen
          onSignedIn={async () => {
            await boot();
          }}
        />
      </main>
    );
  }

  return (
    <div className="ds-shell">
      <aside className={`ds-sidebar ${sidebarOpen ? "ds-sidebar-open" : ""}`}>
        <Sidebar
          chats={chats}
          folders={folders}
          activeId={activeId}
          loading={loadingChats}
          open={sidebarOpen}
          onClose={() => {
            if (typeof window !== "undefined" && window.innerWidth < 901) setSidebarOpen(false);
          }}
          onSelectChat={(id) => {
            setActiveId(id);
            setStoredActiveChatId(id);
            setRequestedChatId(id);
          }}
          onCreateChat={async () => {
            const created = await createChat({ title: "New chat" });
            setChats((current) => [created, ...current]);
            setActiveId(created.id);
            setStoredActiveChatId(created.id);
            setRequestedChatId(created.id);
          }}
          onCreateFolder={async (name) => {
            const folder = await createFolder({ name });
            setFolders((current) => [folder, ...current]);
          }}
          onRenameFolder={async (folderId, name) => {
            const folder = await updateFolder(folderId, { name });
            setFolders((current) => current.map((item) => (item.id === folder.id ? folder : item)));
          }}
          onDeleteFolder={async (folderId) => {
            await deleteFolder(folderId);
            setFolders((current) => current.filter((folder) => folder.id !== folderId));
            setChats((current) => current.map((chat) => (chat.folderId === folderId ? { ...chat, folderId: null } : chat)));
          }}
          onRenameChat={async (chatId, title) => {
            const chat = await updateChat(chatId, { title });
            replaceChat(chatId, (current) => ({ ...current, ...chat }));
          }}
          onDeleteChat={async (chatId) => {
            await deleteChat(chatId);
            await refreshChats();
          }}
          onMoveChatToFolder={async (chatId, folderId) => {
            const chat = await updateChat(chatId, { folderId });
            replaceChat(chatId, (current) => ({ ...current, ...chat }));
          }}
          onDuplicateChat={async (chatId) => {
            const sourceMessages = await listMessages(chatId);
            const sourceChat = chats.find((chat) => chat.id === chatId);
            const duplicated = await createChat({
              title: `${sourceChat?.title ?? "New chat"} copy`,
              modelId: sourceChat?.modelId ?? null,
              folderId: sourceChat?.folderId ?? null
            });
            for (const message of sourceMessages) {
              if (!message.content.trim()) continue;
              const role =
                message.role === "system"
                  ? "SYSTEM"
                  : message.role === "assistant"
                    ? "ASSISTANT"
                    : message.role === "tool"
                      ? "TOOL"
                      : "USER";
              await createMessage(duplicated.id, {
                role,
                content: message.content
              });
            }
            await refreshChats();
            await hydrateChatMessages(duplicated.id);
            setActiveId(duplicated.id);
            setStoredActiveChatId(duplicated.id);
            setRequestedChatId(duplicated.id);
          }}
          onCopyChatLink={async (chatId) => {
            await navigator.clipboard.writeText(`${window.location.origin}/?chat=${chatId}`);
          }}
        />
      </aside>

      <main className="ds-main">
        <ChatScreen
          user={user}
          chat={activeChat}
          chats={chats}
          folders={folders}
          onCreateEmptyChat={async () => {
            const created = await createChat({ title: "New chat", modelId: null });
            setChats((current) => [created, ...current]);
            setActiveId(created.id);
            setStoredActiveChatId(created.id);
            setRequestedChatId(created.id);
            return created;
          }}
          onCreateChatForModel={async (modelId) => {
            const created = await createChat({ title: "New chat", modelId });
            setChats((current) => [created, ...current]);
            setActiveId(created.id);
            setStoredActiveChatId(created.id);
            setRequestedChatId(created.id);
            return created;
          }}
          onRequireChat={ensureActiveChat}
          onRefreshChats={refreshChats}
          onRefreshFolders={refreshFolders}
          onLoadChatMessages={hydrateChatMessages}
          onPatchChat={(chatId, patch) => {
            replaceChat(chatId, (chat) => ({
              ...chat,
              ...patch,
              updatedAt: patch.updatedAt ?? Date.now()
            }));
          }}
          onPatchMessages={(chatId, messages: ChatMsg[]) => {
            replaceChat(chatId, (chat) => ({
              ...chat,
              messages,
              updatedAt: Date.now()
            }));
          }}
          onSelectChat={(chatId) => {
            setActiveId(chatId);
            setStoredActiveChatId(chatId);
            setRequestedChatId(chatId);
          }}
          onToggleSidebar={() => setSidebarOpen((value) => !value)}
          onSignOut={async () => {
            await signout();
            setUser(null);
            setChats([]);
            setFolders([]);
            setActiveId(null);
            setStoredActiveChatId(null);
            setRequestedChatId(null);
            await clearBootstrapCache().catch(() => undefined);
          }}
        />
      </main>

      <div
        className={`tai-sidebar-backdrop ${sidebarOpen ? "tai-sidebar-backdrop--show" : ""}`}
        onClick={() => setSidebarOpen(false)}
      />
      <CommandPalette />
    </div>
  );
}
