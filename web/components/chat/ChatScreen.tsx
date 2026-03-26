"use client";

import React from "react";
import {
  chatCompletionStream,
  listModels,
  type OWMessage,
  type OWModel,
  type OWUser
} from "@/lib/owui/client";
import {
  createMessage,
  listMessages,
  updateChat
} from "@/lib/tai/client";
import ModelSelector from "@/components/panels/ModelSelector";
import { displayForModel, supportsImageGeneration, supportsTextChat, supportsVision } from "@/lib/models/catalog";
import IconSlot from "@/components/ui/IconSlot";
import { useTheme } from "@/components/ui/ThemeProvider";
import { loadBootstrapCache, saveBootstrapCache } from "@/lib/client/bootstrap-cache";
import { computeTitle, type ChatMsg, type LocalChat } from "@/lib/chats/store";
import { EMPTY_CHAT_SUGGESTIONS, followupSuggestions } from "@/lib/chat/suggestions";

type SpeechRecInstance = {
  lang: string;
  interimResults: boolean;
  continuous: boolean;
  start: () => void;
  stop: () => void;
  onresult: ((ev: any) => void) | null;
  onend: (() => void) | null;
  onerror: ((ev: any) => void) | null;
};

type SpeechRecCtor = new () => SpeechRecInstance;
type StreamDraft = { id: string; content: string } | null;
type VoiceState = "idle" | "listening" | "permission_denied" | "unsupported" | "stopped";

const MAX_ATTACHMENTS = 6;
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const MAX_TEXT_FILE_BYTES = 1 * 1024 * 1024;
const MAX_TEXT_ATTACHMENT_CHARS = 120000;
const TEXT_FILE_EXTENSIONS = new Set([".txt", ".md", ".markdown", ".csv", ".json", ".xml", ".yaml", ".yml", ".log", ".ts", ".tsx", ".js", ".jsx", ".py", ".java", ".go", ".rs", ".sql"]);
const TEXT_FILE_MIME_PREFIXES = ["text/"];
const TEXT_FILE_MIME_ALLOWLIST = new Set(["application/json", "application/xml", "application/yaml", "application/x-yaml"]);

function getSpeechRecognitionCtor(): SpeechRecCtor | null {
  if (typeof window === "undefined") return null;
  const w = window as any;
  return (w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null) as SpeechRecCtor | null;
}

async function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result ?? ""));
    reader.onerror = () => reject(new Error("Could not read file."));
    reader.readAsDataURL(file);
  });
}

async function fileToText(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result ?? ""));
    reader.onerror = () => reject(new Error("Could not read file text."));
    reader.readAsText(file);
  });
}

function isTextFile(file: File): boolean {
  const name = file.name.toLowerCase();
  const dotIndex = name.lastIndexOf(".");
  const ext = dotIndex >= 0 ? name.slice(dotIndex) : "";
  if (TEXT_FILE_EXTENSIONS.has(ext)) return true;
  if (TEXT_FILE_MIME_ALLOWLIST.has(file.type)) return true;
  return TEXT_FILE_MIME_PREFIXES.some((prefix) => file.type.startsWith(prefix));
}

async function buildAttachmentsPayload(files: File[]): Promise<any[]> {
  const payload: any[] = [];
  for (const file of files) {
    if (file.type.startsWith("image/")) {
      if (file.size > MAX_IMAGE_BYTES) {
        throw new Error(`Image ${file.name} exceeds 8MB limit.`);
      }
      const dataUrl = await fileToDataUrl(file);
      payload.push({
        type: "image_url",
        image_url: { url: dataUrl },
        name: file.name,
        mime: file.type,
        size: file.size
      });
      continue;
    }
    if (!isTextFile(file)) {
      throw new Error(`Unsupported file type: ${file.name}. Only images and text files are supported.`);
    }
    if (file.size > MAX_TEXT_FILE_BYTES) {
      throw new Error(`Text file ${file.name} exceeds 1MB limit.`);
    }
    const text = (await fileToText(file)).slice(0, MAX_TEXT_ATTACHMENT_CHARS);
    payload.push({ type: "text_file", name: file.name, mime: file.type || "text/plain", size: file.size, text });
  }
  return payload;
}

function extractCodeBlocks(content: string): Array<{ type: "text" | "code"; value: string }> {
  const out: Array<{ type: "text" | "code"; value: string }> = [];
  const parts = content.split(/```[\s\S]*?```/g);
  const codeMatches = content.match(/```([\s\S]*?)```/g) ?? [];
  for (let i = 0; i < parts.length; i += 1) {
    if (parts[i]) out.push({ type: "text", value: parts[i] });
    if (i < codeMatches.length) {
      out.push({ type: "code", value: codeMatches[i].replace(/^```/, "").replace(/```$/, "") });
    }
  }
  return out.length ? out : [{ type: "text", value: content }];
}

const MemoMessageRow = React.memo(function MessageRow(props: {
  msg: ChatMsg;
  streaming: boolean;
  canEdit: boolean;
  canRetry: boolean;
  onRetry: () => void;
  onEdit: () => void;
  onCopyMessage: (text: string) => void;
  onCopyCode: (text: string) => void;
  onShare: (text: string) => void;
}) {
  const isUser = props.msg.role === "user";
  const blocks = props.streaming
    ? [{ type: "text" as const, value: props.msg.content }]
    : extractCodeBlocks(props.msg.content);

  return (
    <div style={{ display: "flex", justifyContent: isUser ? "flex-end" : "flex-start", animation: "taiMsgIn 250ms ease" }}>
      {isUser ? (
        /* User bubble — right-aligned, teal tint */
        <div style={{ maxWidth: 520, padding: "14px 18px", borderRadius: "20px 20px 6px 20px", border: "1px solid rgba(89,204,179,0.15)", background: "rgba(89,204,179,0.06)", fontSize: 15, lineHeight: 1.6 }}>
          <div style={{ whiteSpace: "pre-wrap" }}>
            {blocks.map((block, idx) => block.type === "code" ? (
              <pre key={idx}><button className="ds-btn" type="button" onClick={() => props.onCopyCode(block.value.trim())} style={{ float: "right", padding: "6px 8px" }}>Copy</button><code>{block.value.trim()}</code></pre>
            ) : <span key={idx}>{block.value}</span>)}
          </div>
          {!props.streaming && (
            <div style={{ display: "flex", gap: 6, marginTop: 8, opacity: 0.6 }}>
              <IconSlot name="copy" title="Copy" size="compact" onClick={() => props.onCopyMessage(props.msg.content)} />
              {props.canEdit && <IconSlot name="pencil" title="Edit" size="compact" onClick={props.onEdit} />}
            </div>
          )}
        </div>
      ) : (
        /* Assistant answer card — Perplexity style, full width */
        <div style={{ width: "100%", maxWidth: 760, padding: "20px 0", borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
          {/* AI badge */}
          <span style={{ display: "inline-block", fontSize: 10, fontWeight: 800, color: "#fff", background: "#59CCB3", padding: "2px 8px", borderRadius: 6, marginBottom: 10, letterSpacing: 0.5 }}>AI</span>
          {/* Content */}
          <div style={{ whiteSpace: "pre-wrap", fontSize: 15, lineHeight: 1.65, color: "var(--ds-text)" }}>
            {blocks.map((block, idx) => block.type === "code" ? (
              <pre key={idx}><button className="ds-btn" type="button" onClick={() => props.onCopyCode(block.value.trim())} style={{ float: "right", padding: "6px 8px" }}>Copy</button><code>{block.value.trim()}</code></pre>
            ) : <span key={idx}>{block.value}</span>)}
            {props.streaming && <span className="tai-cursor" />}
          </div>
          {/* Action bar */}
          {!props.streaming && (
            <div style={{ display: "flex", gap: 8, marginTop: 12, paddingTop: 10, borderTop: "1px solid rgba(255,255,255,0.06)" }}>
              <IconSlot name="copy" title="Copy" size="compact" onClick={() => props.onCopyMessage(props.msg.content)} />
              {props.canRetry && <IconSlot name="refresh" title="Regenerate" size="compact" onClick={props.onRetry} />}
              <IconSlot name="external-link" title="Share" size="compact" onClick={() => props.onShare(props.msg.content)} />
            </div>
          )}
        </div>
      )}
    </div>
  );
}, (prev, next) => {
  return (
    prev.msg.id === next.msg.id &&
    prev.msg.content === next.msg.content &&
    prev.streaming === next.streaming &&
    prev.canEdit === next.canEdit &&
    prev.canRetry === next.canRetry
  );
});

export default function ChatScreen(props: {
  user: OWUser;
  chat: LocalChat | null;
  chats: LocalChat[];
  folders: Array<{ id: string; name: string; color?: string | null }>;
  onCreateEmptyChat: () => Promise<LocalChat>;
  onCreateChatForModel: (modelId: string) => Promise<LocalChat>;
  onRequireChat: (modelId?: string | null) => Promise<LocalChat>;
  onRefreshChats: () => Promise<void>;
  onRefreshFolders: () => Promise<void>;
  onLoadChatMessages: (chatId: string) => Promise<void>;
  onPatchChat: (chatId: string, patch: Partial<LocalChat>) => void;
  onPatchMessages: (chatId: string, messages: ChatMsg[]) => void;
  onSelectChat: (chatId: string) => void;
  onToggleSidebar: () => void;
  onSignOut: () => void | Promise<void>;
}) {
  const { toggleTheme } = useTheme();
  const [models, setModels] = React.useState<OWModel[]>([]);
  const [model, setModel] = React.useState<OWModel | null>(null);
  const [openModels, setOpenModels] = React.useState(false);
  const [input, setInput] = React.useState("");
  const [busy, setBusy] = React.useState(false);
  const [err, setErr] = React.useState<string | null>(null);
  const [files, setFiles] = React.useState<File[]>([]);
  const [loadingModels, setLoadingModels] = React.useState(true);
  const [canContinue, setCanContinue] = React.useState(false);
  const [listening, setListening] = React.useState(false);
  const [voiceState, setVoiceState] = React.useState<VoiceState>("idle");
  const [voiceSessionEnabled, setVoiceSessionEnabled] = React.useState(false);
  const [menuOpen, setMenuOpen] = React.useState(false);
  const [openAttachMenu, setOpenAttachMenu] = React.useState(false);
  const [streamDraft, setStreamDraft] = React.useState<StreamDraft>(null);
  const [toast, setToast] = React.useState<string | null>(null);

  const msgs = React.useMemo(() => props.chat?.messages ?? [], [props.chat]);
  const streamAbortRef = React.useRef<AbortController | null>(null);
  const toastTimerRef = React.useRef<number | null>(null);
  const speechRef = React.useRef<SpeechRecInstance | null>(null);
  const composerRef = React.useRef<HTMLDivElement | null>(null);
  const messagePaneRef = React.useRef<HTMLDivElement | null>(null);
  const imageInputRef = React.useRef<HTMLInputElement | null>(null);
  const fileInputRef = React.useRef<HTMLInputElement | null>(null);
  const textareaRef = React.useRef<HTMLTextAreaElement | null>(null);
  const autoScrollRef = React.useRef(true);

  const canSeeAdmin = /admin/i.test(props.user.role ?? "");
  const micSupported = React.useMemo(() => !!getSpeechRecognitionCtor(), []);

  const refreshModelCatalog = React.useCallback(async () => {
    try {
      setLoadingModels(true);
      const cached = await loadBootstrapCache().catch(() => null);
      const cachedSettings = cached?.settings ?? null;
      if (typeof cachedSettings?.voiceSessionEnabled === "boolean") {
        setVoiceSessionEnabled(cachedSettings.voiceSessionEnabled);
      }
      if (cached?.models?.length) {
        const cachedModels = (cached.models as OWModel[]).slice().sort((a, b) => a.name.localeCompare(b.name));
        const cachedAccessible = cachedModels.filter((item) => item.canAccess !== false);
        setModels((current) => (current.length > 0 ? current : cachedModels));
        setModel((current) => {
          const fromActiveChat =
            props.chat?.modelId ? cachedModels.find((item) => item.id === props.chat?.modelId) ?? null : null;
          if (fromActiveChat) return fromActiveChat;
          if (current && cachedModels.some((item) => item.id === current.id)) return current;
          return cachedAccessible[0] ?? cachedModels[0] ?? null;
        });
      }
      const next = await listModels();
      const sorted = [...next].sort((a, b) => a.name.localeCompare(b.name));
      const accessible = sorted.filter((item) => item.canAccess !== false);
      setModels(sorted);
      await saveBootstrapCache({
        user: props.user,
        chats: props.chats,
        models: sorted,
        settings: cachedSettings,
        updatedAt: Date.now()
      }).catch(() => undefined);
      setModel((current) => {
        const fromActiveChat =
          props.chat?.modelId ? sorted.find((item) => item.id === props.chat?.modelId) ?? null : null;
        if (fromActiveChat) return fromActiveChat;
        if (current && sorted.some((item) => item.id === current.id)) return current;
        return accessible[0] ?? sorted[0] ?? null;
      });
    } catch (e: any) {
      setErr(e?.message ?? "Failed to load models.");
    } finally {
      setLoadingModels(false);
    }
  }, [props.chat?.modelId, props.chats, props.user]);

  React.useEffect(() => {
    if (!micSupported) setVoiceState("unsupported");
    else if (!listening && voiceState === "unsupported") setVoiceState("idle");
  }, [micSupported, listening, voiceState]);

  const appendFiles = React.useCallback((incoming: File[]) => {
    if (incoming.length === 0) return;
    const accepted: File[] = [];
    for (const file of incoming) {
      if (file.type.startsWith("image/")) {
        if (file.size > MAX_IMAGE_BYTES) {
          setErr(`Image ${file.name} exceeds 8MB limit.`);
          continue;
        }
        accepted.push(file);
        continue;
      }
      if (!isTextFile(file)) {
        setErr(`Unsupported file type: ${file.name}. Use images or text files.`);
        continue;
      }
      if (file.size > MAX_TEXT_FILE_BYTES) {
        setErr(`Text file ${file.name} exceeds 1MB limit.`);
        continue;
      }
      accepted.push(file);
    }
    if (!accepted.length) return;
    setFiles((prev) => [...prev, ...accepted].slice(0, MAX_ATTACHMENTS));
  }, []);

  const showToast = React.useCallback((message: string) => {
    setToast(message);
    if (toastTimerRef.current) window.clearTimeout(toastTimerRef.current);
    toastTimerRef.current = window.setTimeout(() => setToast(null), 2200);
  }, []);

  React.useEffect(() => {
    return () => {
      if (toastTimerRef.current) window.clearTimeout(toastTimerRef.current);
    };
  }, []);

  React.useEffect(() => {
    const onClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (!target.closest("[data-user-menu]")) setMenuOpen(false);
      if (!target.closest("[data-attach-menu]")) setOpenAttachMenu(false);
    };
    window.addEventListener("click", onClick);
    return () => window.removeEventListener("click", onClick);
  }, []);

  React.useEffect(() => {
    void refreshModelCatalog();
  }, [refreshModelCatalog]);

  React.useEffect(() => {
    const onFocus = () => void refreshModelCatalog();
    window.addEventListener("focus", onFocus);
    document.addEventListener("visibilitychange", onFocus);
    return () => {
      window.removeEventListener("focus", onFocus);
      document.removeEventListener("visibilitychange", onFocus);
    };
  }, [refreshModelCatalog]);

  React.useEffect(() => {
    if (!props.chat?.modelId || !models.length) return;
    const next = models.find((item) => item.id === props.chat?.modelId) ?? null;
    if (next) setModel(next);
  }, [models, props.chat?.modelId]);

  React.useEffect(() => {
    const onPaste = (e: ClipboardEvent) => {
      if (!e.clipboardData) return;
      const pasted: File[] = [];
      for (const item of Array.from(e.clipboardData.items)) {
        if (!item.type.startsWith("image/")) continue;
        const file = item.getAsFile();
        if (file) pasted.push(file);
      }
      if (pasted.length > 0) {
        e.preventDefault();
        appendFiles(pasted);
      }
    };
    window.addEventListener("paste", onPaste);
    return () => window.removeEventListener("paste", onPaste);
  }, [appendFiles]);

  React.useEffect(() => {
    const pane = messagePaneRef.current;
    if (!pane) return;
    const onScroll = () => {
      autoScrollRef.current = pane.scrollHeight - pane.scrollTop - pane.clientHeight < 90;
    };
    pane.addEventListener("scroll", onScroll);
    return () => pane.removeEventListener("scroll", onScroll);
  }, []);

  React.useEffect(() => {
    const pane = messagePaneRef.current;
    if (!pane || !autoScrollRef.current) return;
    pane.scrollTo({ top: pane.scrollHeight, behavior: busy ? "auto" : "smooth" });
  }, [msgs.length, streamDraft?.content, busy]);

  React.useEffect(() => {
    const node = textareaRef.current;
    if (!node) return;
    node.style.height = "0px";
    node.style.height = `${Math.min(node.scrollHeight, 220)}px`;
  }, [input]);

  const renderedMessages = React.useMemo(() => {
    if (!streamDraft) return msgs;
    return [...msgs, { id: streamDraft.id, role: "assistant", content: streamDraft.content } as ChatMsg];
  }, [msgs, streamDraft]);

  const chatCapable = supportsTextChat(model);
  const imageGenCapable = supportsImageGeneration(model);
  const canSend = !!model && model.canAccess !== false && chatCapable && !!input.trim() && !busy;
  const hasImage = files.some((f) => f.type.startsWith("image/"));
  const visionOk = supportsVision(model);

  const stopGenerating = () => {
    streamAbortRef.current?.abort();
    showToast("Generation stopped.");
  };

  const copyText = React.useCallback(async (text: string, successLabel: string) => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
      } else {
        const node = document.createElement("textarea");
        node.value = text;
        node.setAttribute("readonly", "");
        node.style.position = "absolute";
        node.style.left = "-9999px";
        document.body.appendChild(node);
        node.select();
        document.execCommand("copy");
        document.body.removeChild(node);
      }
      showToast(successLabel);
    } catch {
      setErr("Clipboard access failed.");
    }
  }, [showToast]);

  const shareText = React.useCallback(async (text: string) => {
    try {
      if (navigator.share) {
        await navigator.share({ text });
        showToast("Message shared.");
        return;
      }
      await copyText(text, "Message copied.");
    } catch (error: any) {
      if (error?.name === "AbortError") return;
      setErr("Share failed.");
    }
  }, [copyText, showToast]);

  const toggleMic = () => {
    const Ctor = getSpeechRecognitionCtor();
    if (!Ctor) {
      setVoiceState("unsupported");
      setErr("Voice input is not supported in this browser.");
      return;
    }
    if (!voiceSessionEnabled) {
      setVoiceState("stopped");
      setErr("Voice input is disabled in Settings.");
      return;
    }
    if (listening && speechRef.current) {
      speechRef.current.stop();
      setListening(false);
      setVoiceState("stopped");
      return;
    }

    const sr = new Ctor();
    sr.lang = "en-US";
    sr.interimResults = true;
    sr.continuous = true;
    sr.onresult = (ev) => {
      let transcript = "";
      for (let i = ev.resultIndex; i < ev.results.length; i += 1) {
        transcript += ev.results[i][0].transcript;
      }
      setInput((prev) =>
        prev.trim() ? `${prev.trim()} ${transcript.trim()}`.trim() : transcript.trim()
      );
    };
    sr.onerror = (ev: any) => {
      setListening(false);
      if (ev?.error === "not-allowed" || ev?.error === "service-not-allowed") {
        setVoiceState("permission_denied");
        setErr("Microphone permission denied. Allow mic access in browser settings.");
        return;
      }
      setVoiceState("stopped");
      setErr("Microphone input failed. Check browser permissions.");
    };
    sr.onend = () => {
      setListening(false);
      setVoiceState((current) => (current === "permission_denied" ? current : "stopped"));
    };
    speechRef.current = sr;
    setListening(true);
    setVoiceState("listening");
    try {
      sr.start();
    } catch {
      setListening(false);
      setVoiceState("stopped");
      setErr("Could not start voice input.");
    }
  };

  const persistTitleIfNeeded = React.useCallback(async (chat: LocalChat, messages: ChatMsg[]) => {
    const title = computeTitle(messages);
    if (title !== chat.title) {
      props.onPatchChat(chat.id, { title, updatedAt: Date.now() });
      await updateChat(chat.id, { title });
    }
  }, [props]);

  const streamAssistant = async (
    chat: LocalChat,
    baseMessages: ChatMsg[],
    streamId: string,
    attachments?: any[]
  ) => {
    if (!model) return;

    const ow: OWMessage[] = baseMessages
      .filter((m) => m.role === "user" || m.role === "assistant" || m.role === "system")
      .map((m) => ({ role: m.role as OWMessage["role"], content: m.content }));

    let streamed = "";
    let finishReason: string | undefined;
    const aborter = new AbortController();
    streamAbortRef.current = aborter;
    setStreamDraft({ id: streamId, content: "" });

    try {
      await chatCompletionStream("session", model.id, ow, {
        attachments,
        signal: aborter.signal,
        chatId: chat.id,
        onToken: (delta) => {
          streamed += delta;
          setStreamDraft({ id: streamId, content: streamed });
        },
        onDone: (res) => {
          finishReason = res.finishReason;
        }
      });

      const latest = await listMessages(chat.id);
      props.onPatchMessages(chat.id, latest);
      await props.onRefreshChats();
      setCanContinue(finishReason === "length");
      setFiles([]);
    } catch (e: any) {
      if (e?.name !== "AbortError") {
        setErr(e?.message ?? "Send failed.");
      }
      const latest = await listMessages(chat.id).catch(() => baseMessages);
      props.onPatchMessages(chat.id, latest);
    } finally {
      setStreamDraft(null);
      streamAbortRef.current = null;
      setBusy(false);
    }
  };

  const send = async (forcedText?: string) => {
    if (!model) return;
    if (model.canAccess === false) {
      setErr(model.lockReason ?? `Selected model (${displayForModel(model).name}) is locked for your plan.`);
      return;
    }
    if (!chatCapable) {
      setErr(`Selected model (${displayForModel(model).name}) is not chat-compatible in this app yet.`);
      return;
    }
    const text = (forcedText ?? input).trim();
    if (!text) return;
    if (hasImage && !visionOk) {
      setErr(`Selected model (${displayForModel(model).name}) does not support images. Choose a Vision model.`);
      return;
    }

    setBusy(true);
    setErr(null);
    setCanContinue(false);
    if (!forcedText) setInput("");

    try {
      const chat = await props.onRequireChat(model.id);
      props.onSelectChat(chat.id);

      await createMessage(chat.id, {
        role: "USER",
        content: text
      });

      const latest = await listMessages(chat.id);
      props.onPatchMessages(chat.id, latest);
      await persistTitleIfNeeded(chat, latest);

      const streamId = `stream-${crypto.randomUUID()}`;
      const attachments = files.length ? await buildAttachmentsPayload(files) : undefined;
      await streamAssistant(
        { ...chat, title: computeTitle(latest), modelId: model.id, messages: latest },
        latest,
        streamId,
        attachments
      );
    } catch (e: any) {
      setBusy(false);
      setErr(e?.message ?? "Send failed.");
    }
  };

  const regenerate = async () => {
    if (!model || busy || !props.chat) return;
    const latest = await listMessages(props.chat.id);
    const withoutLastAssistant = [...latest];
    for (let i = withoutLastAssistant.length - 1; i >= 0; i -= 1) {
      if (withoutLastAssistant[i].role === "assistant") {
        withoutLastAssistant.splice(i, 1);
        break;
      }
    }
    props.onPatchMessages(props.chat.id, withoutLastAssistant);
    setBusy(true);
    setErr(null);
    await streamAssistant(props.chat, withoutLastAssistant, `stream-${crypto.randomUUID()}`);
  };

  const handleEditUser = async (msgId: string) => {
    const idx = msgs.findIndex((m) => m.id === msgId && m.role === "user");
    if (idx < 0 || !props.chat) return;
    const original = msgs[idx];
    const trimmed = msgs.slice(0, idx);
    props.onPatchMessages(props.chat.id, trimmed);
    setInput(original.content);
    showToast("Message ready to edit.");
    composerRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
  };

  const followups = React.useMemo(() => followupSuggestions(msgs), [msgs]);
  const folderName = props.chat?.folderId
    ? props.folders.find((folder) => folder.id === props.chat?.folderId)?.name ?? null
    : null;
  const headerTitle = props.chat?.title && props.chat.title !== "New chat" && msgs.length > 0 ? props.chat.title : null;

  return (
    <div style={{ minHeight: "100dvh", display: "flex", flexDirection: "column" }}>
      <header style={{ position: "sticky", top: 0, zIndex: 12, display: "grid", gridTemplateColumns: "auto 1fr auto", alignItems: "center", gap: 10, padding: "10px 16px", borderBottom: "1px solid rgba(255,255,255,0.08)", background: "rgba(11,15,20,0.85)", backdropFilter: "blur(16px)", WebkitBackdropFilter: "blur(16px)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <IconSlot name="panel-left" title="Toggle sidebar" onClick={props.onToggleSidebar} />
          <IconSlot
            name="plus"
            title="New chat"
            onClick={() => void props.onCreateEmptyChat().then((chat) => props.onSelectChat(chat.id))}
          />
        </div>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 12, minHeight: 38 }}>
          <img src="/tai-logo.png" alt="" style={{ width: 24, height: 24 }} />
          <span style={{ fontSize: 17, fontWeight: 700, color: "#59CCB3", letterSpacing: 1 }}>TABAI</span>
          <button
            className="ds-btn tai-pill-button"
            onClick={() => setOpenModels(true)}
            disabled={!models.length}
            style={{ padding: "7px 14px", fontSize: 12 }}
          >
            {model ? displayForModel(model).name : "Select model"}
          </button>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8, justifySelf: "end" }}>
          <div data-user-menu style={{ position: "relative", display: "flex", justifyContent: "flex-end" }}>
            <IconSlot name="user" title="Account menu" onClick={() => setMenuOpen((v) => !v)} />
            {menuOpen ? (
              <div className="ds-card" style={{ position: "absolute", right: 0, top: 40, width: 220, padding: 8, zIndex: 30 }}>
                <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left", marginBottom: 6 }} onClick={toggleTheme}>
                  <span style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    <IconSlot name="sun-moon" title="Theme" size="compact" /> Theme
                  </span>
                </button>
                <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left", marginBottom: 6 }} onClick={() => (window.location.href = "/profile")}>
                  <span style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    <IconSlot name="settings" title="Settings" size="compact" /> Settings
                  </span>
                </button>
                {canSeeAdmin ? (
                  <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left", marginBottom: 6 }} onClick={() => (window.location.href = "/admin")}>
                    <span style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                      <IconSlot name="shield" title="Admin" size="compact" /> Admin
                    </span>
                  </button>
                ) : null}
                <button className="ds-btn tai-menu-button" style={{ width: "100%", textAlign: "left" }} onClick={() => void props.onSignOut()}>
                  <span style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    <IconSlot name="logout" title="Sign out" size="compact" /> Sign out
                  </span>
                </button>
              </div>
            ) : null}
          </div>
        </div>
      </header>

      <div ref={messagePaneRef} style={{ flex: 1, overflow: "auto" }}>
        <div style={{ maxWidth: 880, margin: "0 auto", display: "flex", flexDirection: "column", gap: 12, padding: 16 }}>
          {msgs.length === 0 ? (
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", padding: "60px 0 40px" }}>
              <img src="/tai-logo.png" alt="" style={{ width: 64, height: 64, marginBottom: 8 }} />
              <div style={{ fontSize: 36, fontWeight: 700, color: "#59CCB3", letterSpacing: 1.5, marginBottom: 8 }}>TABAI</div>
              <div style={{ fontSize: 24, fontWeight: 600, color: "var(--ds-text)", marginBottom: 6 }}>
                {loadingModels ? "Loading models..." : "Ask anything"}
              </div>
              <div style={{ color: "var(--ds-text-3)", fontSize: 14, marginBottom: 28 }}>
                Choose a model and start a conversation
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, maxWidth: 520, width: "100%" }}>
                {EMPTY_CHAT_SUGGESTIONS.map((s) => (
                  <button key={s.id} className="tai-chip-button" onClick={() => void send(s.text)} style={{ cursor: "pointer" }}>
                    {s.text}
                  </button>
                ))}
              </div>
            </div>
          ) : null}

          {renderedMessages.map((m, idx) => (
            <MemoMessageRow
              key={m.id}
              msg={m}
              streaming={streamDraft?.id === m.id && busy}
              canEdit={m.role === "user"}
              canRetry={m.role === "assistant" && idx >= msgs.length - 1 && !busy}
              onRetry={() => void regenerate()}
              onEdit={() => void handleEditUser(m.id)}
              onCopyMessage={(text) => void copyText(text, "Message copied.")}
              onCopyCode={(text) => void copyText(text, "Code copied.")}
              onShare={(text) => void shareText(text)}
            />
          ))}

          {msgs.length > 0 && !busy && followups.length > 0 ? (
            <div style={{ paddingTop: 4 }}>
              <div style={{ color: "var(--ds-text-3)", fontSize: 12, marginBottom: 8 }}>Follow-up</div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {followups.slice(0, 4).map((s) => (
                  <button key={s.id} className="tai-chip-button" onClick={() => void send(s.text)} style={{ cursor: "pointer" }}>
                    {s.text}
                  </button>
                ))}
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <div ref={composerRef} style={{ position: "sticky", bottom: 0, background: "linear-gradient(to top, #0B0F14 80%, transparent)", padding: "0 0 8px" }}>
        <div style={{ maxWidth: 880, margin: "0 auto", padding: 12 }}>
          {toast ? (
            <div
              aria-live="polite"
              className="ds-card"
              style={{
                position: "fixed",
                left: "50%",
                bottom: 104,
                transform: "translateX(-50%)",
                zIndex: 60,
                padding: "10px 14px",
                fontSize: 13,
                color: "var(--ds-text-1)",
                background: "rgba(16,18,20,0.92)",
                borderColor: "rgba(255,255,255,0.08)",
                boxShadow: "0 18px 50px rgba(0,0,0,0.28)"
              }}
            >
              {toast}
            </div>
          ) : null}

          {files.length > 0 ? (
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 8 }}>
              {files.map((f) => (
                <div key={`${f.name}-${f.size}`} className="ds-card" style={{ padding: "6px 8px", display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 12 }}>{f.name}</span>
                  <IconSlot
                    name="close"
                    title="Remove attachment"
                    size="compact"
                    onClick={() => setFiles((prev) => prev.filter((x) => x !== f))}
                  />
                </div>
              ))}
            </div>
          ) : null}

          {err ? <div style={{ color: "var(--ds-danger)", fontSize: 13, marginBottom: 8 }}>{err}</div> : null}

          <div style={{ padding: "8px 12px", borderRadius: 24, background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)" }}>
            <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
              <div data-attach-menu style={{ position: "relative", display: "flex", gap: 6 }}>
                <IconSlot name="paperclip" title="Attach" onClick={() => setOpenAttachMenu((v) => !v)} />
                {openAttachMenu ? (
                  <div className="ds-card" style={{ position: "absolute", left: 0, bottom: 40, padding: 8, zIndex: 20, width: 180 }}>
                    <button className="ds-btn" style={{ width: "100%", textAlign: "left", marginBottom: 6 }} onClick={() => imageInputRef.current?.click()}>
                      <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
                        <IconSlot name="image" title="Upload image" size="compact" /> Upload image
                      </span>
                    </button>
                    <button className="ds-btn" style={{ width: "100%", textAlign: "left" }} onClick={() => fileInputRef.current?.click()}>
                      <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
                        <IconSlot name="paperclip" title="Upload text file" size="compact" /> Upload text file
                      </span>
                    </button>
                  </div>
                ) : null}
                <IconSlot
                  name="mic"
                  title={listening ? "Stop voice input" : "Voice input"}
                  onClick={toggleMic}
                  intent={listening ? "active" : "default"}
                />
              </div>

              <textarea
                ref={textareaRef}
                className="ds-input"
                placeholder="Ask anything..."
                value={input}
                onChange={(e) => setInput(e.target.value)}
                rows={1}
                style={{ resize: "none", minHeight: 44, maxHeight: 220, lineHeight: 1.4 }}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
                    e.preventDefault();
                    if (canSend) void send();
                  }
                }}
              />

              {busy ? (
                <IconSlot name="stop" title="Stop generating" onClick={stopGenerating} intent="active" />
              ) : (
                <IconSlot name="send" title="Send" onClick={() => void send()} intent={canSend ? "active" : "muted"} />
              )}
              {props.chat ? <IconSlot name="refresh" title="Regenerate" onClick={() => void regenerate()} /> : null}
            </div>

            <div style={{ marginTop: 6, display: "flex", gap: 8, alignItems: "center", fontSize: 11, color: "rgba(255,255,255,0.3)", padding: "0 4px" }}>
              {model?.canAccess === false && <span style={{ color: "#ff9500" }}>{model.lockReason ?? "Locked"}</span>}
              {canContinue && <button style={{ background: "rgba(89,204,179,0.1)", border: "1px solid rgba(89,204,179,0.2)", borderRadius: 999, padding: "4px 10px", color: "#59CCB3", fontSize: 11, cursor: "pointer" }} onClick={() => void send("Continue")}>Continue</button>}
              <div style={{ flex: 1 }} />
              <span>⌘+Enter to send</span>
            </div>
          </div>
        </div>
      </div>

      <input
        ref={imageInputRef}
        type="file"
        accept="image/*"
        multiple
        style={{ display: "none" }}
        onChange={(e) => appendFiles(Array.from(e.target.files ?? []))}
      />
      <input
        ref={fileInputRef}
        type="file"
        accept=".txt,.md,.markdown,.csv,.json,.xml,.yaml,.yml,.log,.ts,.tsx,.js,.jsx,.py,.java,.go,.rs,.sql,text/*,application/json,application/xml,application/yaml,application/x-yaml"
        multiple
        style={{ display: "none" }}
        onChange={(e) => appendFiles(Array.from(e.target.files ?? []))}
      />

      <ModelSelector
        open={openModels}
        onClose={() => setOpenModels(false)}
        models={models}
        selectedId={model?.id ?? null}
        onSelect={async (next) => {
          if (next.canAccess === false) {
            setErr(next.lockReason ?? `Model ${displayForModel(next).name} is locked for your plan.`);
            return;
          }
          if (next.supportsTextChat === false) {
            setErr(`Model ${displayForModel(next).name} is not chat-compatible in this app yet.`);
            return;
          }
          if (next.id === model?.id) {
            setOpenModels(false);
            return;
          }
          setModel(next);
          setOpenModels(false);
          const created = await props.onCreateChatForModel(next.id);
          props.onSelectChat(created.id);
          showToast(`Started a new ${displayForModel(next).name} chat.`);
        }}
      />
    </div>
  );
}
