"use client";

import React from "react";
import { resolveAPIURL } from "@/lib/tai/client";
import { useTheme } from "@/components/ui/ThemeProvider";
import IconButton from "@/components/ui/IconButton";
import { getCurrentUserProfile } from "@/lib/tai/client";
import { signout } from "@/lib/owui/client";

type Me = {
  id?: string;
  email?: string;
  name?: string;
  username?: string;
  role?: string;
  status?: string;
  planTier?: "free" | "starter" | "pro" | "power";
  entitlement?: {
    source: "free" | "apple" | "google" | "admin" | "web";
    status: "active" | "inactive" | "grace" | "cancelled" | "expired";
    expiresAt: string | null;
  } | null;
} | null;

export default function ProfilePage() {
  const { theme, toggleTheme, setTheme } = useTheme();
  const [me, setMe] = React.useState<Me>(null);
  const [settings, setSettings] = React.useState({ theme: "dark", language: "en", notificationsEnabled: true, voiceSessionEnabled: false });
  const [email, setEmail] = React.useState("");
  const [currentPassword, setCurrentPassword] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [err, setErr] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    const run = async () => {
      setLoading(true);
      setErr(null);
      try {
        const profile = await getCurrentUserProfile();
        const settingsRes = await fetch(resolveAPIURL("/api/settings"), { credentials: "include" });
        const settingsJson = await settingsRes.json().catch(() => ({ settings: null }));
        setMe(profile ? {
          id: profile.id,
          email: profile.email,
          name: profile.name,
          username: profile.username,
          role: profile.role,
          status: profile.status,
          planTier: profile.planTier,
          entitlement: profile.entitlement
            ? {
              source: profile.entitlement.source,
              status: profile.entitlement.status,
              expiresAt: profile.entitlement.expiresAt
            }
            : null
        } : null);
        setEmail(profile?.email ?? "");
        if (settingsJson?.settings) {
          setSettings({
            theme: settingsJson.settings.theme ?? "dark",
            language: settingsJson.settings.language ?? "en",
            notificationsEnabled: settingsJson.settings.notificationsEnabled ?? true,
            voiceSessionEnabled: settingsJson.settings.voiceSessionEnabled ?? false
          });
        }
      } catch (e: any) {
        setErr(e?.message ?? "Failed to load profile.");
      } finally {
        setLoading(false);
      }
    };
    void run();
  }, []);

  return (
    <div style={{ minHeight: "100dvh", padding: 24 }}>
      <div style={{ maxWidth: 980, margin: "0 auto" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
          <div>
            <div style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-0.03em" }}>Profile</div>
            <div style={{ color: "var(--ds-text-2)", marginTop: 8, fontSize: 13 }}>
              Account and workspace preferences.
            </div>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <IconButton title={`Theme: ${theme}`} name="sun-moon" onClick={toggleTheme} />
            {me?.role === "ADMIN" ? <IconButton title="Admin" name="shield" href="/admin" /> : null}
            <IconButton title="Back to chat" name="chevron-left" href="/" />
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, minmax(0, 1fr))", gap: 12, marginTop: 18 }}>
          <div className="ds-card" style={{ padding: 16 }}>
            <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>Account</div>
            <div style={{ marginTop: 10, color: "var(--ds-text-2)", fontSize: 13 }}>
              {loading ? "Loading…" : null}
            </div>
            <div style={{ marginTop: 10, display: "grid", gap: 8 }}>
              <KV k="Name" v={me?.name ?? "—"} />
              <KV k="Username" v={me?.username ?? "—"} />
              <KV k="Email" v={me?.email ?? "—"} />
              <KV k="Role" v={me?.role ?? "—"} />
              <KV k="Status" v={me?.status ?? "—"} />
              <KV k="Plan" v={(me?.planTier ?? "free").toUpperCase()} />
              <KV k="Entitlement Source" v={me?.entitlement?.source?.toUpperCase() ?? "FREE"} />
              <KV k="Entitlement Status" v={me?.entitlement?.status?.toUpperCase() ?? "INACTIVE"} />
              <KV k="Entitlement Expiry" v={me?.entitlement?.expiresAt ? new Date(me.entitlement.expiresAt).toLocaleString() : "—"} />
              <KV k="User ID" v={me?.id ?? "—"} />
            </div>
            {err ? <div style={{ marginTop: 10, color: "var(--ds-danger)", fontSize: 13 }}>{err}</div> : null}
          </div>

          <div className="ds-card" style={{ padding: 16 }}>
            <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>Preferences</div>
            <div style={{ display: "grid", gap: 10, marginTop: 10 }}>
              <label style={{ display: "grid", gap: 6 }}>
                <span style={{ fontSize: 12, color: "var(--ds-text-3)" }}>Theme</span>
                <select
                  className="ds-input"
                  value={settings.theme}
                  onChange={(e) => setSettings((current) => ({ ...current, theme: e.target.value }))}
                >
                  <option value="dark">Dark</option>
                  <option value="light">Light</option>
                </select>
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <span style={{ fontSize: 12, color: "var(--ds-text-3)" }}>Language</span>
                <select
                  className="ds-input"
                  value={settings.language}
                  onChange={(e) => setSettings((current) => ({ ...current, language: e.target.value }))}
                >
                  <option value="en">English</option>
                  <option value="tr">Turkish</option>
                </select>
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={settings.notificationsEnabled}
                  onChange={(e) => setSettings((current) => ({ ...current, notificationsEnabled: e.target.checked }))}
                />
                <span style={{ fontSize: 13 }}>Notifications enabled</span>
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={settings.voiceSessionEnabled}
                  onChange={(e) => setSettings((current) => ({ ...current, voiceSessionEnabled: e.target.checked }))}
                />
                <span style={{ fontSize: 13 }}>Enable microphone voice input</span>
              </label>
            </div>
            <div style={{ marginTop: 12, display: "flex", gap: 10, flexWrap: "wrap" }}>
              <button
                className="ds-btn"
                onClick={async () => {
                  const res = await fetch(resolveAPIURL("/api/settings"), {
                    method: "PATCH",
                    credentials: "include",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(settings)
                  });
                  const data = await res.json().catch(() => ({}));
                  if (!res.ok) {
                    setErr(data?.error ?? "Failed to save settings.");
                    return;
                  }
                  if (settings.theme === "dark" || settings.theme === "light") {
                    setTheme(settings.theme);
                  } else if (settings.theme !== theme) {
                    toggleTheme();
                  }
                  setNotice("Settings saved.");
                }}
              >
                Save settings
              </button>
            </div>
          </div>
        </div>

        <div className="ds-card" style={{ padding: 16, marginTop: 12 }}>
          <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>Account Security</div>
          <div style={{ display: "grid", gap: 10, marginTop: 12 }}>
            <input className="ds-input" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
            <input className="ds-input" placeholder="Current password" type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} />
            <input className="ds-input" placeholder="New password (optional)" type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
          </div>
          <div style={{ marginTop: 12, display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button
              className="ds-btn"
              onClick={async () => {
                setErr(null);
                setNotice(null);
                const res = await fetch(resolveAPIURL("/api/settings/account"), {
                  method: "PATCH",
                  credentials: "include",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({
                    email,
                    currentPassword,
                    password: newPassword || undefined
                  })
                });
                const data = await res.json().catch(() => ({}));
                if (!res.ok) {
                  setErr(data?.error ?? "Failed to update account.");
                  return;
                }
                setMe(data.user);
                setCurrentPassword("");
                setNewPassword("");
                setNotice("Account updated.");
              }}
            >
              Save account
            </button>
          </div>
          {notice ? <div style={{ marginTop: 10, color: "var(--ds-text-2)", fontSize: 13 }}>{notice}</div> : null}
        </div>

        <div className="ds-card" style={{ padding: 16, marginTop: 12, borderColor: "rgba(255,255,255,0.08)" }}>
          <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>Session</div>
          <div style={{ color: "var(--ds-text-3)", fontSize: 13, marginTop: 8 }}>
            Sign out of this device and return to the login screen.
          </div>
          <div style={{ marginTop: 14, paddingTop: 12, borderTop: "1px solid var(--ds-border)" }}>
            <button
              className="ds-btn"
              style={{ width: "100%", justifyContent: "center", color: "var(--ds-danger)" }}
              onClick={async () => {
                await signout();
                window.location.href = "/";
              }}
            >
              Sign out
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function KV(props: { k: string; v: string }) {
  return (
    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 10 }}>
      <div style={{ color: "var(--ds-text-3)", fontSize: 12 }}>{props.k}</div>
      <div style={{ color: "var(--ds-text)", fontSize: 13, fontWeight: 600, maxWidth: 520, textAlign: "right", overflow: "hidden", textOverflow: "ellipsis" }}>
        {props.v}
      </div>
    </div>
  );
}
