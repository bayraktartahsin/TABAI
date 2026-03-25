"use client";

import React from "react";
import Link from "next/link";
import IconSlot from "@/components/ui/IconSlot";
import type { LocalChat } from "@/lib/chats/store";

type FolderRecord = { id: string; name: string; color?: string | null };

type ContextMenuState = {
  kind: "chat" | "folder";
  id: string;
  x: number;
  y: number;
} | null;

export default function Sidebar(props: {
  chats: LocalChat[];
  folders: FolderRecord[];
  activeId: string | null;
  loading?: boolean;
  onSelectChat: (id: string) => void;
  onCreateChat: () => void | Promise<void>;
  onCreateFolder: (name: string) => void | Promise<void>;
  onRenameFolder: (folderId: string, name: string) => void | Promise<void>;
  onDeleteFolder: (folderId: string) => void | Promise<void>;
  onRenameChat: (chatId: string, title: string) => void | Promise<void>;
  onDeleteChat: (chatId: string) => void | Promise<void>;
  onMoveChatToFolder: (chatId: string, folderId: string | null) => void | Promise<void>;
  onDuplicateChat: (chatId: string) => void | Promise<void>;
  onCopyChatLink: (chatId: string) => void | Promise<void>;
  open: boolean;
  onClose: () => void;
}) {
  const [q, setQ] = React.useState("");
  const [creatingFolder, setCreatingFolder] = React.useState(false);
  const [folderName, setFolderName] = React.useState("");
  const [editingChatId, setEditingChatId] = React.useState<string | null>(null);
  const [editingValue, setEditingValue] = React.useState("");
  const [contextMenu, setContextMenu] = React.useState<ContextMenuState>(null);
  const [draggingChatId, setDraggingChatId] = React.useState<string | null>(null);
  const [dragOverFolderId, setDragOverFolderId] = React.useState<string | null | undefined>(undefined);

  React.useEffect(() => {
    const close = () => setContextMenu(null);
    window.addEventListener("pointerdown", close);
    window.addEventListener("blur", close);
    return () => {
      window.removeEventListener("pointerdown", close);
      window.removeEventListener("blur", close);
    };
  }, []);

  const filtered = React.useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return props.chats;
    return props.chats.filter((c) =>
      [c.title, c.modelName, c.modelVendor]
        .filter((value): value is string => typeof value === "string" && value.length > 0)
        .some((value) => value.toLowerCase().includes(needle))
    );
  }, [props.chats, q]);

  const grouped = React.useMemo(() => {
    const byFolder = new Map<string, LocalChat[]>();
    const ungrouped: LocalChat[] = [];

    for (const chat of filtered) {
      if (chat.folderId) {
        const current = byFolder.get(chat.folderId) ?? [];
        current.push(chat);
        byFolder.set(chat.folderId, current);
      } else {
        ungrouped.push(chat);
      }
    }

    return { byFolder, ungrouped };
  }, [filtered]);

  const activeContextChat =
    contextMenu?.kind === "chat" ? props.chats.find((chat) => chat.id === contextMenu.id) ?? null : null;
  const activeContextFolder =
    contextMenu?.kind === "folder" ? props.folders.find((folder) => folder.id === contextMenu.id) ?? null : null;

  const submitFolder = async () => {
    const nextName = folderName.trim();
    if (!nextName) return;
    await props.onCreateFolder(nextName);
    setFolderName("");
    setCreatingFolder(false);
  };

  const startRename = (chat: LocalChat) => {
    setEditingChatId(chat.id);
    setEditingValue(chat.title);
    setContextMenu(null);
  };

  const submitRename = async () => {
    const next = editingValue.trim();
    const chatId = editingChatId;
    if (!chatId) return;
    setEditingChatId(null);
    if (!next) return;
    await props.onRenameChat(chatId, next);
  };

  const moveDraggedChat = async (chatId: string | null, folderId: string | null) => {
    const resolvedChatId = chatId ?? draggingChatId;
    if (!resolvedChatId) return;
    const draggingChat = props.chats.find((chat) => chat.id === resolvedChatId);
    if (!draggingChat || draggingChat.folderId === folderId) {
      setDraggingChatId(null);
      setDragOverFolderId(undefined);
      return;
    }
    await props.onMoveChatToFolder(resolvedChatId, folderId);
    setDraggingChatId(null);
    setDragOverFolderId(undefined);
  };

  return (
    <div className={`tai-sidebar ${props.open ? "tai-sidebar--open" : "tai-sidebar--closed"}`}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8, padding: 12 }}>
        <div style={{ fontWeight: 700, letterSpacing: "-0.02em" }}>TAI</div>
        <div style={{ display: "flex", gap: 6 }}>
          <IconSlot name="plus" title="New chat" size="compact" onClick={() => void props.onCreateChat()} />
          <IconSlot
            name="folder-plus"
            title="New folder"
            size="compact"
            onClick={() => {
              setCreatingFolder((value) => !value);
              setContextMenu(null);
            }}
          />
          <IconSlot name="close" title="Close sidebar" size="compact" onClick={props.onClose} className="tai-mobile-only" />
        </div>
      </div>

      <div style={{ padding: "0 12px 12px", display: "grid", gap: 8 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <IconSlot name="search" title="Search chats" size="compact" />
          <input
            className="ds-input"
            aria-label="Search chats"
            placeholder="Search chats"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            style={{ height: 34, padding: "7px 10px" }}
          />
        </div>

        {creatingFolder ? (
          <div className="ds-card" style={{ padding: 8, display: "grid", gap: 8 }}>
            <input
              className="ds-input"
              autoFocus
              placeholder="Folder name"
              value={folderName}
              onChange={(e) => setFolderName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") void submitFolder();
                if (e.key === "Escape") {
                  setCreatingFolder(false);
                  setFolderName("");
                }
              }}
            />
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button className="ds-btn" onClick={() => { setCreatingFolder(false); setFolderName(""); }}>Cancel</button>
              <button className="ds-btn" onClick={() => void submitFolder()}>Create</button>
            </div>
          </div>
        ) : null}
      </div>

      <div style={{ flex: 1, overflow: "auto", padding: "0 8px 8px" }}>
        {props.loading ? (
          <div style={{ color: "var(--ds-text-3)", fontSize: 12, padding: 10 }}>Loading chats…</div>
        ) : null}

        <div style={{ display: "grid", gap: 12 }}>
          <ChatSection
            title="Chats"
            chats={grouped.ungrouped}
            activeId={props.activeId}
            editingChatId={editingChatId}
            editingValue={editingValue}
            dragOver={dragOverFolderId === null}
            onEditingValueChange={setEditingValue}
            onRenameSubmit={submitRename}
            onRenameCancel={() => setEditingChatId(null)}
            onSelectChat={props.onSelectChat}
            onClose={props.onClose}
            onOpenContextMenu={setContextMenu}
            onDragStart={setDraggingChatId}
            onDropChat={async (chatId) => moveDraggedChat(chatId, null)}
            onDragEnter={() => setDragOverFolderId(null)}
            onDragLeave={() => {}}
          />

          {props.folders.map((folder) => {
            const chats = grouped.byFolder.get(folder.id) ?? [];
            if (chats.length === 0 && q.trim()) return null;
            return (
              <ChatSection
                key={folder.id}
                title={folder.name}
                folderId={folder.id}
                chats={chats}
                activeId={props.activeId}
                editingChatId={editingChatId}
                editingValue={editingValue}
                dragOver={dragOverFolderId === folder.id}
                onEditingValueChange={setEditingValue}
                onRenameSubmit={submitRename}
                onRenameCancel={() => setEditingChatId(null)}
                onSelectChat={props.onSelectChat}
                onClose={props.onClose}
                onRenameFolder={props.onRenameFolder}
                onDeleteFolder={props.onDeleteFolder}
                onOpenContextMenu={setContextMenu}
                onDragStart={setDraggingChatId}
                onDropChat={async (chatId) => moveDraggedChat(chatId, folder.id)}
                onDragEnter={() => setDragOverFolderId(folder.id)}
                onDragLeave={() => {}}
              />
            );
          })}

          {!props.loading && filtered.length === 0 ? (
            <div style={{ color: "var(--ds-text-3)", fontSize: 12, padding: 10 }}>No chats found.</div>
          ) : null}
        </div>
      </div>

      <div
        style={{
          padding: "8px 12px 12px",
          borderTop: "1px solid var(--ds-border)",
          display: "flex",
          flexWrap: "wrap",
          gap: 8,
          fontSize: 11,
          color: "var(--ds-text-3)"
        }}
      >
        <Link href="/privacy">Privacy</Link>
        <span>•</span>
        <Link href="/terms">Terms</Link>
        <span>•</span>
        <Link href="/acceptable-use">Acceptable Use</Link>
        <span>•</span>
        <Link href="/subscription">Subscription</Link>
        <span>•</span>
        <Link href="/support">Support</Link>
      </div>

      {contextMenu && (activeContextChat || activeContextFolder) ? (
        <div
          className="ds-card"
          style={{
            position: "fixed",
            top: Math.min(contextMenu.y, window.innerHeight - 320),
            left: Math.min(contextMenu.x, window.innerWidth - 236),
            zIndex: 80,
            width: 220,
            padding: 8,
            display: "grid",
            gap: 6
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {activeContextChat ? (
            <>
              <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left" }} onClick={() => startRename(activeContextChat)}>
                Rename
              </button>
              <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left" }} onClick={() => void Promise.resolve(props.onDuplicateChat(activeContextChat.id)).then(() => setContextMenu(null))}>
                Duplicate
              </button>
              <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left" }} onClick={() => void Promise.resolve(props.onCopyChatLink(activeContextChat.id)).then(() => setContextMenu(null))}>
                Copy link
              </button>
              <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left" }} onClick={() => void Promise.resolve(props.onMoveChatToFolder(activeContextChat.id, null)).then(() => setContextMenu(null))}>
                Move to chats
              </button>
              {props.folders.map((folder) => (
                <button
                  key={folder.id}
                  className="ds-btn tai-menu-button"
                  style={{ width: "100%", textAlign: "left" }}
                  onClick={() => void Promise.resolve(props.onMoveChatToFolder(activeContextChat.id, folder.id)).then(() => setContextMenu(null))}
                >
                  Move to {folder.name}
                </button>
              ))}
              <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left", color: "var(--ds-danger)" }} onClick={() => void Promise.resolve(props.onDeleteChat(activeContextChat.id)).then(() => setContextMenu(null))}>
                Delete
              </button>
            </>
          ) : null}
          {activeContextFolder ? (
            <>
              <button
                className="ds-btn tai-menu-button"
                style={{ width: "100%", textAlign: "left" }}
                onClick={() => {
                  const next = window.prompt("Rename folder", activeContextFolder.name);
                  setContextMenu(null);
                  if (next?.trim()) void props.onRenameFolder(activeContextFolder.id, next.trim());
                }}
              >
                Rename folder
              </button>
              <button
                className="ds-btn tai-menu-button"
                style={{ width: "100%", textAlign: "left", color: "var(--ds-danger)" }}
                onClick={() => {
                  setContextMenu(null);
                  if (window.confirm(`Delete folder "${activeContextFolder.name}"? Chats stay in history.`)) {
                    void props.onDeleteFolder(activeContextFolder.id);
                  }
                }}
              >
                Delete folder
              </button>
            </>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

function ChatSection(props: {
  title: string;
  folderId?: string;
  chats: LocalChat[];
  activeId: string | null;
  editingChatId: string | null;
  editingValue: string;
  dragOver: boolean;
  onEditingValueChange: (value: string) => void;
  onRenameSubmit: () => void;
  onRenameCancel: () => void;
  onSelectChat: (id: string) => void;
  onClose: () => void;
  onRenameFolder?: (folderId: string, name: string) => void | Promise<void>;
  onDeleteFolder?: (folderId: string) => void | Promise<void>;
  onOpenContextMenu: (state: ContextMenuState) => void;
  onDragStart: (chatId: string | null) => void;
  onDropChat: (chatId: string | null) => void | Promise<void>;
  onDragEnter: () => void;
  onDragLeave: () => void;
}) {
  return (
    <div style={{ display: "grid", gap: 6 }}>
      <div
        className="tai-sidebar-dropzone"
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 8,
          padding: "6px 6px",
          borderRadius: 12,
          background: props.dragOver ? "rgba(255,255,255,0.07)" : "transparent",
          border: props.dragOver ? "1px dashed rgba(255,255,255,0.24)" : "1px dashed transparent"
        }}
        onDragOver={(e) => {
          e.preventDefault();
          props.onDragEnter();
        }}
        onDragEnter={(e) => {
          e.preventDefault();
          props.onDragEnter();
        }}
        onDragLeave={props.onDragLeave}
        onDrop={(e) => {
          e.preventDefault();
          const chatId = e.dataTransfer.getData("text/plain") || null;
          void props.onDropChat(chatId);
        }}
        onContextMenu={(e) => {
          if (!props.folderId) return;
          e.preventDefault();
          props.onOpenContextMenu({ kind: "folder", id: props.folderId, x: e.clientX, y: e.clientY });
        }}
      >
        <div style={{ color: "var(--ds-text-3)", fontSize: 11, textTransform: "uppercase", letterSpacing: "0.08em" }}>
          {props.title}
        </div>
      </div>
      <div style={{ display: "grid", gap: 4 }}>
        {props.chats.map((c) => (
          <div key={c.id} style={{ position: "relative" }}>
            <button
              className="ds-btn tai-sidebar-row"
              draggable
              onDragStart={(e) => {
                e.dataTransfer.effectAllowed = "move";
                e.dataTransfer.setData("text/plain", c.id);
                props.onDragStart(c.id);
              }}
              onDragEnd={() => {
                props.onDragStart(null);
                props.onDragLeave();
              }}
              onContextMenu={(e) => {
                e.preventDefault();
                props.onOpenContextMenu({ kind: "chat", id: c.id, x: e.clientX, y: e.clientY });
              }}
              onClick={() => {
                props.onSelectChat(c.id);
                props.onClose();
              }}
              style={{
                textAlign: "left",
                borderRadius: 12,
                padding: "9px 10px",
                background: c.id === props.activeId ? "rgba(255,255,255,0.08)" : "transparent",
                borderColor: c.id === props.activeId ? "rgba(255,255,255,0.2)" : "transparent",
                width: "100%"
              }}
              title={c.title}
            >
              <span style={{ display: "grid", gap: 4, width: "100%" }}>
                {props.editingChatId === c.id ? (
                  <input
                    className="ds-input"
                    autoFocus
                    value={props.editingValue}
                    onChange={(e) => props.onEditingValueChange(e.target.value)}
                    onClick={(e) => e.stopPropagation()}
                    onBlur={() => void props.onRenameSubmit()}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") void props.onRenameSubmit();
                      if (e.key === "Escape") props.onRenameCancel();
                    }}
                    style={{ height: 30, padding: "5px 8px" }}
                  />
                ) : (
                  <span style={{ display: "inline-block", width: "100%", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {c.title}
                  </span>
                )}
                {c.modelName ? (
                  <span
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      maxWidth: "100%",
                      width: "fit-content",
                      border: "1px solid rgba(255,255,255,0.1)",
                      borderRadius: 999,
                      padding: "2px 8px",
                      fontSize: 11,
                      color: "var(--ds-text-3)",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap"
                    }}
                  >
                    {c.modelName}
                  </span>
                ) : null}
              </span>
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
