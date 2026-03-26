"use client";

import React from "react";
import Link from "next/link";
import { adminFetch, adminPost, adminPatch, adminPut, adminDelete } from "@/lib/admin/api";

// ── Types ──

type User = {
  id: string; email: string; username: string; displayName?: string | null;
  role: string; status: string; planTier: string; emailVerified: boolean;
  signupPlatform?: string;
  lastActiveAt?: string | null; createdAt?: string | null;
  entitlement?: { source?: string; status?: string; planTier?: string; expiresAt?: string | null; autoRenew?: boolean; externalProductId?: string | null; externalOriginalTransactionId?: string | null; lastValidatedAt?: string | null } | null;
};

type Model = { id: string; displayName: string; providerModelId: string; vendor?: string; enabled: boolean; capabilities?: string[]; verified?: boolean; requiredPlanTier?: string; canAccess?: boolean };
type Chat = { id: string; title: string; isDeleted: boolean; updatedAt: string; user: { email: string; username: string; displayName?: string | null }; messages: { id: string; role: string; content: string }[] };
type AuditEntry = { id: string; action: string; targetType: string; targetId?: string | null; createdAt: string; actor?: { email?: string } | null };
type OverviewStats = { users: { total: number; active24h: number; active7d: number; active30d: number; frozen: number }; chats: { total: number; today: number }; subscriptions: { tierBreakdown: Record<string, number>; sourceBreakdown: Record<string, number>; totalPaid: number }; usage: { requests24h: number; requests7d: number } };
type DiscountCode = { id: string; code: string; plan_tier: string; duration_days: number; max_uses: number; current_uses: number; is_active: number; created_at: string; expires_at?: string | null };
type SafetyEvent = { id: string; event_type: string; user_id?: string; model_id?: string; code?: string; message?: string; created_at: string };
type Note = { id: string; content: string; created_at: string; author_email?: string };
type Section = "overview" | "users" | "models" | "analytics" | "support" | "codes" | "system";

// ── Main Component ──

export default function AdminPage() {
  const [section, setSection] = React.useState<Section>("overview");
  const [overview, setOverview] = React.useState<OverviewStats | null>(null);
  const [users, setUsers] = React.useState<User[]>([]);
  const [models, setModels] = React.useState<Model[]>([]);
  const [chats, setChats] = React.useState<Chat[]>([]);
  const [audit, setAudit] = React.useState<AuditEntry[]>([]);
  const [codes, setCodes] = React.useState<DiscountCode[]>([]);
  const [safety, setSafety] = React.useState<SafetyEvent[]>([]);
  const [modelUsage, setModelUsage] = React.useState<{ model_id: string; requests: number; total_output: number; errors: number }[]>([]);
  const [errorSummary, setErrorSummary] = React.useState<{ event_type: string; model_id: string; cnt: number }[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [err, setErr] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);

  // User detail
  const [selectedUserId, setSelectedUserId] = React.useState<string | null>(null);
  const [userNotes, setUserNotes] = React.useState<Note[]>([]);
  const [userChats, setUserChats] = React.useState<any[]>([]);
  const [userSearch, setUserSearch] = React.useState("");
  const [modelSearch, setModelSearch] = React.useState("");

  const flash = (msg: string) => { setNotice(msg); setTimeout(() => setNotice(null), 4000); };

  const loadAll = React.useCallback(async () => {
    setLoading(true); setErr(null);
    try {
      const [ov, u, m, c, a, co, se, mu, es] = await Promise.all([
        adminFetch<OverviewStats>("/api/admin/analytics/overview"),
        adminFetch<{ users: User[] }>("/api/admin/users"),
        adminFetch<{ models: Model[] }>("/api/admin/models"),
        adminFetch<{ chats: Chat[] }>("/api/admin/chats"),
        adminFetch<{ entries: AuditEntry[] }>("/api/admin/audit"),
        adminFetch<{ codes: DiscountCode[] }>("/api/admin/discount-codes").catch(() => ({ codes: [] })),
        adminFetch<{ events: SafetyEvent[] }>("/api/admin/safety-events?limit=50").catch(() => ({ events: [] })),
        adminFetch<{ usage: any[] }>("/api/admin/analytics/model-usage").catch(() => ({ usage: [] })),
        adminFetch<{ errors: any[] }>("/api/admin/analytics/errors").catch(() => ({ errors: [] })),
      ]);
      setOverview(ov); setUsers(u.users ?? []); setModels(m.models ?? []); setChats(c.chats ?? []);
      setAudit(a.entries ?? []); setCodes(co.codes ?? []); setSafety(se.events ?? []);
      setModelUsage(mu.usage ?? []); setErrorSummary(es.errors ?? []);
    } catch (e: any) { setErr(e?.message ?? "Failed to load"); }
    setLoading(false);
  }, []);

  React.useEffect(() => { void loadAll(); }, [loadAll]);

  const selectUser = async (userId: string) => {
    setSelectedUserId(userId);
    try {
      const [notes, chats] = await Promise.all([
        adminFetch<{ notes: Note[] }>(`/api/admin/users/${userId}/notes`).catch(() => ({ notes: [] })),
        adminFetch<{ chats: any[] }>(`/api/admin/users/${userId}/chats`).catch(() => ({ chats: [] })),
      ]);
      setUserNotes(notes.notes ?? []); setUserChats(chats.chats ?? []);
    } catch { /* ignore */ }
  };

  const selectedUser = users.find(u => u.id === selectedUserId) ?? null;
  const filteredUsers = React.useMemo(() => {
    const q = userSearch.trim().toLowerCase();
    if (!q) return users;
    return users.filter(u => u.email.toLowerCase().includes(q) || u.username.toLowerCase().includes(q) || (u.displayName ?? "").toLowerCase().includes(q) || u.id.includes(q));
  }, [users, userSearch]);

  const filteredModels = React.useMemo(() => {
    const q = modelSearch.trim().toLowerCase();
    const sorted = [...models].sort((a, b) => a.displayName.localeCompare(b.displayName));
    if (!q) return sorted;
    return sorted.filter(m => m.displayName.toLowerCase().includes(q) || m.providerModelId.toLowerCase().includes(q) || (m.vendor ?? "").toLowerCase().includes(q));
  }, [models, modelSearch]);

  // Sidebar nav items
  const nav: { key: Section; label: string; icon: string }[] = [
    { key: "overview", label: "Overview", icon: "📊" },
    { key: "users", label: "Users", icon: "👥" },
    { key: "models", label: "Models", icon: "🤖" },
    { key: "analytics", label: "Analytics", icon: "📈" },
    { key: "support", label: "Support", icon: "💬" },
    { key: "codes", label: "Discount Codes", icon: "🎟️" },
    { key: "system", label: "System", icon: "⚙️" },
  ];

  return (
    <div style={{ display: "flex", minHeight: "100dvh", background: "#0B0F14", color: "#f5f5f5", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      {/* Sidebar */}
      <nav style={{ width: 220, borderRight: "1px solid rgba(255,255,255,0.08)", padding: "20px 12px", display: "flex", flexDirection: "column", gap: 4, flexShrink: 0 }}>
        <div style={{ fontSize: 20, fontWeight: 700, color: "#59CCB3", letterSpacing: 1.5, padding: "0 12px", marginBottom: 20 }}>TABAI</div>
        <div style={{ fontSize: 11, color: "#8e8e93", padding: "0 12px", marginBottom: 12 }}>Admin Panel</div>
        {nav.map(n => (
          <button key={n.key} onClick={() => setSection(n.key)} style={{
            display: "flex", alignItems: "center", gap: 10, padding: "10px 12px", border: "none", borderRadius: 10, cursor: "pointer",
            background: section === n.key ? "rgba(89,204,179,0.1)" : "transparent",
            color: section === n.key ? "#59CCB3" : "#8e8e93", fontSize: 14, fontWeight: section === n.key ? 600 : 400, textAlign: "left", width: "100%",
          }}>{n.icon} {n.label}</button>
        ))}
        <div style={{ flex: 1 }} />
        <button onClick={() => void loadAll()} style={{ padding: "10px 12px", border: "none", borderRadius: 10, background: "rgba(255,255,255,0.05)", color: "#8e8e93", fontSize: 13, cursor: "pointer" }}>↻ Refresh</button>
        <Link href="/" style={{ padding: "10px 12px", textDecoration: "none", color: "#8e8e93", fontSize: 13 }}>← Back to Chat</Link>
      </nav>

      {/* Main */}
      <main style={{ flex: 1, padding: 24, overflow: "auto" }}>
        {err && <div style={{ padding: "10px 14px", background: "rgba(255,59,48,0.1)", border: "1px solid rgba(255,59,48,0.3)", borderRadius: 10, color: "#ff3b30", fontSize: 13, marginBottom: 12 }}>{err}</div>}
        {notice && <div style={{ padding: "10px 14px", background: "rgba(52,199,89,0.1)", border: "1px solid rgba(52,199,89,0.3)", borderRadius: 10, color: "#34c759", fontSize: 13, marginBottom: 12 }}>{notice}</div>}

        {/* ═══ OVERVIEW ═══ */}
        {section === "overview" && overview && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>Dashboard</h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12, marginBottom: 20 }}>
              <Stat label="Total Users" value={overview.users.total} />
              <Stat label="Active 24h" value={overview.users.active24h} color="#007aff" />
              <Stat label="Active 7d" value={overview.users.active7d} color="#59CCB3" />
              <Stat label="Paid Subs" value={overview.subscriptions.totalPaid} color="#34c759" />
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12, marginBottom: 20 }}>
              <Stat label="Chats Today" value={overview.chats.today} />
              <Stat label="Total Chats" value={overview.chats.total} />
              <Stat label="Requests 24h" value={overview.usage.requests24h} />
              <Stat label="Requests 7d" value={overview.usage.requests7d} />
            </div>
            {/* Tier breakdown */}
            <Card title="Subscriptions by Tier">
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                {Object.entries(overview.subscriptions.tierBreakdown).map(([tier, count]) => (
                  <div key={tier} style={{ padding: "8px 14px", borderRadius: 10, border: "1px solid rgba(255,255,255,0.08)", fontSize: 14 }}>
                    <span style={{ fontWeight: 600 }}>{tier.toUpperCase()}</span>: {count}
                  </div>
                ))}
              </div>
            </Card>
            <Card title="Subscriptions by Source" style={{ marginTop: 12 }}>
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                {Object.entries(overview.subscriptions.sourceBreakdown).map(([source, count]) => (
                  <div key={source} style={{ padding: "8px 14px", borderRadius: 10, border: "1px solid rgba(255,255,255,0.08)", fontSize: 14 }}>
                    <span style={{ fontWeight: 600, textTransform: "capitalize" }}>{source === "apple" ? "🍎 iOS" : source === "google" ? "🤖 Android" : source === "admin" ? "👤 Admin" : source === "web" ? "🌐 Web" : source}</span>: {count}
                  </div>
                ))}
              </div>
            </Card>
            {/* Recent activity */}
            <Card title="Recent Audit" style={{ marginTop: 12 }}>
              {audit.slice(0, 8).map(e => (
                <div key={e.id} style={{ padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13, display: "flex", justifyContent: "space-between" }}>
                  <span><b>{e.action}</b> — {e.actor?.email ?? "system"}</span>
                  <span style={{ color: "#8e8e93" }}>{new Date(e.createdAt).toLocaleString()}</span>
                </div>
              ))}
            </Card>
          </div>
        )}

        {/* ═══ USERS ═══ */}
        {section === "users" && (
          <div style={{ display: "grid", gridTemplateColumns: selectedUser ? "1fr 1.3fr" : "1fr", gap: 16 }}>
            <div>
              <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 12 }}>Users ({users.length})</h2>
              <input value={userSearch} onChange={e => setUserSearch(e.target.value)} placeholder="Search email, username, ID..." style={{ ...inputStyle, width: "100%", marginBottom: 12 }} />
              <div style={{ display: "grid", gap: 6, maxHeight: "75vh", overflow: "auto" }}>
                {filteredUsers.map(u => (
                  <button key={u.id} onClick={() => void selectUser(u.id)} style={{
                    display: "grid", gridTemplateColumns: "1fr auto auto", alignItems: "center", gap: 10,
                    padding: "12px 14px", border: selectedUserId === u.id ? "2px solid #59CCB3" : "1px solid rgba(255,255,255,0.08)",
                    borderRadius: 12, background: selectedUserId === u.id ? "rgba(89,204,179,0.06)" : "transparent",
                    cursor: "pointer", textAlign: "left", width: "100%", color: "#f5f5f5",
                  }}>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 14 }}>{u.displayName ?? u.username}</div>
                      <div style={{ fontSize: 12, color: "#8e8e93" }}>{u.email}</div>
                      <div style={{ fontSize: 11, color: "#8e8e93" }}>{u.signupPlatform === "ios" ? "🍎" : u.signupPlatform === "android" ? "🤖" : "🌐"} {u.signupPlatform ?? "web"} · {u.lastActiveAt ? timeAgo(u.lastActiveAt) : "Never"}</div>
                    </div>
                    <PlanBadge tier={u.planTier} />
                    <StatusDot status={u.status} source={u.entitlement?.source} />
                  </button>
                ))}
              </div>
            </div>
            {selectedUser && (
              <Card title={selectedUser.displayName ?? selectedUser.username}>
                <div style={{ fontSize: 13, color: "#8e8e93", marginBottom: 12 }}>{selectedUser.email} · ID: {selectedUser.id.slice(0, 12)}...</div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 16 }}>
                  <Info label="Plan" value={selectedUser.planTier.toUpperCase()} />
                  <Info label="Status" value={selectedUser.status} />
                  <Info label="Platform" value={selectedUser.signupPlatform ?? "web"} />
                  <Info label="Source" value={selectedUser.entitlement?.source ?? "free"} />
                  <Info label="Signed up" value={selectedUser.createdAt ? new Date(selectedUser.createdAt).toLocaleDateString() : "—"} />
                  <Info label="Last active" value={selectedUser.lastActiveAt ? timeAgo(selectedUser.lastActiveAt) : "Never"} />
                </div>
                {/* Entitlement */}
                {selectedUser.entitlement && selectedUser.entitlement.source !== "free" && (
                  <div style={{ padding: 12, border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, marginBottom: 12, fontSize: 13 }}>
                    <div style={{ fontWeight: 600, marginBottom: 6 }}>Subscription</div>
                    <div>Status: {selectedUser.entitlement.status} · Auto-renew: {selectedUser.entitlement.autoRenew ? "Yes" : "No"}</div>
                    <div>Expires: {selectedUser.entitlement.expiresAt ? new Date(selectedUser.entitlement.expiresAt).toLocaleDateString() : "Never"}</div>
                    {selectedUser.entitlement.externalProductId && <div>Product: {selectedUser.entitlement.externalProductId}</div>}
                  </div>
                )}
                {/* Quick actions */}
                <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 8 }}>Quick Actions</div>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 16 }}>
                  {(["starter", "pro", "power"] as const).map(tier => (
                    <Btn key={tier} onClick={async () => {
                      if (!confirm(`Grant ${tier.toUpperCase()} to ${selectedUser.email}?`)) return;
                      await adminPut(`/api/admin/users/${selectedUser.id}/entitlement`, { planTier: tier, source: "admin", status: "active" });
                      flash(`Granted ${tier}`); await loadAll(); void selectUser(selectedUser.id);
                    }}>Grant {tier}</Btn>
                  ))}
                  <Btn onClick={async () => {
                    await adminPut(`/api/admin/users/${selectedUser.id}/entitlement`, { planTier: "free", source: "free", status: "active" });
                    flash("Reset to Free"); await loadAll(); void selectUser(selectedUser.id);
                  }}>Reset Free</Btn>
                  <Btn onClick={async () => {
                    const pw = prompt("New password:"); if (!pw) return;
                    await adminPatch(`/api/admin/users/${selectedUser.id}`, { password: pw }); flash("Password reset");
                  }}>Reset PW</Btn>
                  <Btn onClick={async () => {
                    await adminPatch(`/api/admin/users/${selectedUser.id}`, { status: selectedUser.status === "FROZEN" ? "ENABLED" : "FROZEN" });
                    flash(selectedUser.status === "FROZEN" ? "Enabled" : "Frozen"); await loadAll(); void selectUser(selectedUser.id);
                  }}>{selectedUser.status === "FROZEN" ? "Unfreeze" : "Freeze"}</Btn>
                  <Btn danger onClick={async () => {
                    if (!confirm(`DELETE ${selectedUser.email}?`)) return;
                    await adminDelete(`/api/admin/users/${selectedUser.id}`);
                    flash("Deleted"); setSelectedUserId(null); await loadAll();
                  }}>Delete</Btn>
                </div>
                {/* Notes */}
                <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 8 }}>Admin Notes</div>
                <form onSubmit={async e => {
                  e.preventDefault(); const content = (e.target as any).note.value;
                  if (!content) return;
                  await adminPost(`/api/admin/users/${selectedUser.id}/notes`, { content });
                  (e.target as any).note.value = ""; void selectUser(selectedUser.id);
                }}>
                  <div style={{ display: "flex", gap: 8 }}>
                    <input name="note" placeholder="Add a note..." style={{ ...inputStyle, flex: 1 }} />
                    <Btn type="submit">Add</Btn>
                  </div>
                </form>
                <div style={{ maxHeight: 200, overflow: "auto", marginTop: 8 }}>
                  {userNotes.map(n => (
                    <div key={n.id} style={{ padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                      <div>{n.content}</div>
                      <div style={{ fontSize: 11, color: "#8e8e93" }}>{n.author_email} · {new Date(n.created_at).toLocaleString()}</div>
                    </div>
                  ))}
                </div>
                {/* User chats */}
                <div style={{ fontWeight: 600, fontSize: 13, marginTop: 16, marginBottom: 8 }}>Recent Chats ({userChats.length})</div>
                <div style={{ maxHeight: 200, overflow: "auto" }}>
                  {userChats.slice(0, 15).map((c: any) => (
                    <div key={c.id} style={{ padding: "6px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                      {c.title} <span style={{ color: "#8e8e93" }}>· {c.message_count} msgs · {new Date(c.updated_at).toLocaleDateString()}</span>
                    </div>
                  ))}
                </div>
              </Card>
            )}
          </div>
        )}

        {/* ═══ MODELS ═══ */}
        {section === "models" && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 12 }}>Models ({models.length})</h2>
            <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
              <input value={modelSearch} onChange={e => setModelSearch(e.target.value)} placeholder="Search models..." style={{ ...inputStyle, flex: 1 }} />
              <Btn onClick={async () => { await adminPost("/api/admin/models", { action: "sync-openrouter" }); flash("Synced"); await loadAll(); }}>Sync OpenRouter</Btn>
            </div>
            <div style={{ display: "grid", gap: 6, maxHeight: "75vh", overflow: "auto" }}>
              {filteredModels.map(m => (
                <div key={m.id} style={{ display: "grid", gridTemplateColumns: "2fr 1fr auto auto", alignItems: "center", gap: 10, padding: "10px 14px", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10 }}>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: 14 }}>{m.displayName}</div>
                    <div style={{ fontSize: 11, color: "#8e8e93" }}>{m.providerModelId} · {m.vendor ?? "—"}</div>
                  </div>
                  <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                    {m.requiredPlanTier && <PlanBadge tier={m.requiredPlanTier} />}
                    {(m.capabilities ?? []).slice(0, 2).map(c => <Badge key={c} label={c} />)}
                  </div>
                  <Btn onClick={async () => { await adminPatch(`/api/admin/models/${m.id}`, { enabled: !m.enabled }); await loadAll(); }}>{m.enabled ? "Disable" : "Enable"}</Btn>
                  <Btn onClick={async () => { const n = prompt("Rename:", m.displayName); if (!n) return; await adminPatch(`/api/admin/models/${m.id}`, { displayName: n }); await loadAll(); }}>Rename</Btn>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ═══ ANALYTICS ═══ */}
        {section === "analytics" && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>Analytics</h2>
            <Card title="Model Usage (7 days)">
              <div style={{ display: "grid", gap: 4 }}>
                {modelUsage.slice(0, 20).map(m => {
                  const maxReq = modelUsage[0]?.requests ?? 1;
                  return (
                    <div key={m.model_id} style={{ display: "grid", gridTemplateColumns: "200px 1fr 80px 60px", alignItems: "center", gap: 10, fontSize: 13 }}>
                      <div style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{m.model_id.replace(/^or-/, "")}</div>
                      <div style={{ height: 6, borderRadius: 3, background: "rgba(255,255,255,0.06)" }}>
                        <div style={{ height: 6, borderRadius: 3, background: "#59CCB3", width: `${(m.requests / maxReq) * 100}%` }} />
                      </div>
                      <div style={{ textAlign: "right" }}>{m.requests} req</div>
                      <div style={{ textAlign: "right", color: m.errors > 0 ? "#ff3b30" : "#8e8e93" }}>{m.errors} err</div>
                    </div>
                  );
                })}
              </div>
            </Card>
            <Card title="Error Summary (7 days)" style={{ marginTop: 12 }}>
              {errorSummary.length === 0 && <div style={{ color: "#8e8e93", fontSize: 13 }}>No errors in the last 7 days</div>}
              {errorSummary.slice(0, 20).map((e, i) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                  <span>{e.event_type} — {e.model_id}</span>
                  <span style={{ color: "#ff3b30", fontWeight: 600 }}>{e.cnt}</span>
                </div>
              ))}
            </Card>
          </div>
        )}

        {/* ═══ SUPPORT ═══ */}
        {section === "support" && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 12 }}>Support</h2>
            <p style={{ color: "#8e8e93", fontSize: 14, marginBottom: 16 }}>Select a user from the Users tab to view their chats, add notes, and manage their account.</p>
            <Card title="Recent Safety Events">
              {safety.slice(0, 30).map(e => (
                <div key={e.id} style={{ padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                  <div><b>{e.event_type}</b> {e.code && `(${e.code})`}</div>
                  <div style={{ color: "#8e8e93" }}>User: {e.user_id?.slice(0, 12) ?? "—"} · Model: {e.model_id ?? "—"} · {new Date(e.created_at).toLocaleString()}</div>
                  {e.message && <div style={{ fontSize: 12, color: "#ff9500", marginTop: 2 }}>{e.message.slice(0, 200)}</div>}
                </div>
              ))}
            </Card>
          </div>
        )}

        {/* ═══ DISCOUNT CODES ═══ */}
        {section === "codes" && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 12 }}>Discount Codes</h2>
            <form onSubmit={async e => {
              e.preventDefault(); const f = e.target as any;
              try {
                await adminPost("/api/admin/discount-codes", {
                  code: f.code.value, planTier: f.planTier.value,
                  durationDays: parseInt(f.days.value), maxUses: parseInt(f.maxUses.value),
                });
                flash("Code created"); f.reset(); await loadAll();
              } catch (err: any) { setErr(err.message); }
            }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr auto", gap: 8, marginBottom: 12 }}>
                <input name="code" placeholder="Code (e.g. WELCOME50)" required style={inputStyle} />
                <select name="planTier" style={inputStyle}><option value="starter">Starter</option><option value="pro">Pro</option><option value="power">Power</option></select>
                <input name="days" type="number" placeholder="Days" defaultValue="30" required style={inputStyle} />
                <input name="maxUses" type="number" placeholder="Max uses" defaultValue="1" required style={inputStyle} />
                <Btn type="submit">Create</Btn>
              </div>
            </form>
            <div style={{ display: "grid", gap: 6 }}>
              {codes.map(c => (
                <div key={c.id} style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr auto", alignItems: "center", gap: 10, padding: "10px 14px", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, opacity: c.is_active ? 1 : 0.5 }}>
                  <div style={{ fontWeight: 600, fontFamily: "monospace" }}>{c.code}</div>
                  <div><PlanBadge tier={c.plan_tier} /> · {c.duration_days}d</div>
                  <div>{c.current_uses}/{c.max_uses} used</div>
                  <div style={{ fontSize: 12, color: "#8e8e93" }}>{new Date(c.created_at).toLocaleDateString()}</div>
                  {c.is_active ? <Btn danger onClick={async () => { await adminDelete(`/api/admin/discount-codes/${c.id}`); await loadAll(); }}>Deactivate</Btn> : <span style={{ color: "#8e8e93", fontSize: 12 }}>Inactive</span>}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ═══ SYSTEM ═══ */}
        {section === "system" && (
          <div>
            <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>System</h2>
            <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: 16 }}>
              <Card title="Chat Monitor (last 100)">
                <div style={{ maxHeight: "60vh", overflow: "auto" }}>
                  {chats.map(c => (
                    <div key={c.id} style={{ padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                      <div style={{ fontWeight: 600 }}>{c.title} {c.isDeleted && <span style={{ color: "#ff3b30" }}>(deleted)</span>}</div>
                      <div style={{ color: "#8e8e93", fontSize: 11 }}>{c.user.email} · {new Date(c.updatedAt).toLocaleString()}</div>
                      {c.messages.slice(-1).map(m => (
                        <div key={m.id} style={{ fontSize: 12, color: "#aaa", marginTop: 2 }}><b>{m.role}:</b> {m.content.slice(0, 150)}</div>
                      ))}
                    </div>
                  ))}
                </div>
              </Card>
              <Card title="Audit Log">
                <div style={{ maxHeight: "60vh", overflow: "auto" }}>
                  {audit.map(e => (
                    <div key={e.id} style={{ padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 13 }}>
                      <div style={{ fontWeight: 600 }}>{e.action}</div>
                      <div style={{ fontSize: 11, color: "#8e8e93" }}>{e.actor?.email ?? "system"} · {new Date(e.createdAt).toLocaleString()}</div>
                    </div>
                  ))}
                </div>
              </Card>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

// ── Shared Components ──

const inputStyle: React.CSSProperties = { padding: "8px 12px", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 10, background: "rgba(255,255,255,0.05)", color: "#f5f5f5", fontSize: 13, outline: "none" };

function Stat({ label, value, color }: { label: string; value: number; color?: string }) {
  return (
    <div style={{ padding: "14px 16px", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 14, background: "rgba(255,255,255,0.03)" }}>
      <div style={{ fontSize: 11, color: "#8e8e93", textTransform: "uppercase", letterSpacing: "0.04em" }}>{label}</div>
      <div style={{ fontSize: 28, fontWeight: 700, marginTop: 4, color: color ?? "#f5f5f5" }}>{value.toLocaleString()}</div>
    </div>
  );
}

function Card({ title, children, style }: { title: string; children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <div style={{ padding: 16, border: "1px solid rgba(255,255,255,0.08)", borderRadius: 14, background: "rgba(255,255,255,0.03)", ...style }}>
      <div style={{ fontWeight: 600, fontSize: 15, marginBottom: 12 }}>{title}</div>
      {children}
    </div>
  );
}

function PlanBadge({ tier }: { tier: string }) {
  const colors: Record<string, string> = { free: "#8e8e93", starter: "#007aff", pro: "#af52de", power: "#ff9500" };
  return <span style={{ fontSize: 11, fontWeight: 600, padding: "3px 8px", borderRadius: 999, background: (colors[tier] ?? "#8e8e93") + "18", color: colors[tier] ?? "#8e8e93", textTransform: "uppercase" }}>{tier}</span>;
}

function StatusDot({ status, source }: { status: string; source?: string }) {
  let color = "#34c759";
  if (status === "FROZEN") color = "#ff3b30";
  else if (status === "DELETED") color = "#8e8e93";
  return <div style={{ width: 8, height: 8, borderRadius: "50%", background: color }} />;
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ padding: "6px 10px", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 8 }}>
      <div style={{ fontSize: 10, color: "#8e8e93", textTransform: "uppercase" }}>{label}</div>
      <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>{value}</div>
    </div>
  );
}

function Badge({ label }: { label: string }) {
  return <span style={{ fontSize: 10, padding: "2px 6px", borderRadius: 999, border: "1px solid rgba(255,255,255,0.08)", color: "#8e8e93", textTransform: "capitalize" }}>{label}</span>;
}

function Btn({ children, onClick, danger, type }: { children: React.ReactNode; onClick?: () => void; danger?: boolean; type?: "submit" }) {
  return <button type={type ?? "button"} onClick={onClick} style={{ padding: "6px 12px", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 8, background: "rgba(255,255,255,0.05)", color: danger ? "#ff3b30" : "#f5f5f5", fontSize: 12, cursor: "pointer", fontWeight: 500 }}>{children}</button>;
}

function timeAgo(iso: string): string {
  const ms = Date.now() - Date.parse(iso);
  if (ms < 60000) return "Just now";
  if (ms < 3600000) return `${Math.floor(ms / 60000)}m ago`;
  if (ms < 86400000) return `${Math.floor(ms / 3600000)}h ago`;
  if (ms < 604800000) return `${Math.floor(ms / 86400000)}d ago`;
  return new Date(iso).toLocaleDateString();
}
