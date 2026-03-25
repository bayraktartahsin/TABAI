"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { useTheme } from "@/components/ui/ThemeProvider";

type Item = { id: string; title: string; hint?: string; run: () => void };

export default function CommandPalette() {
  const router = useRouter();
  const { toggleTheme } = useTheme();
  const [open, setOpen] = React.useState(false);
  const [query, setQuery] = React.useState("");
  const [active, setActive] = React.useState(0);

  const items = React.useMemo<Item[]>(() => {
    return [
      { id: "new", title: "New chat", hint: "Clear current conversation", run: () => window.location.reload() },
      { id: "pricing", title: "Pricing", hint: "Plans and limits", run: () => router.push("/pricing") },
      { id: "theme", title: "Toggle theme", hint: "Dark / Light", run: () => toggleTheme() },
      {
        id: "admin",
        title: "Open admin panel",
        hint: "TAI /admin",
        run: () => router.push("/admin")
      }
    ];
  }, [router, toggleTheme]);

  const filtered = React.useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return items;
    return items.filter((it) => (it.title + " " + (it.hint ?? "")).toLowerCase().includes(q));
  }, [items, query]);

  React.useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const isK = e.key.toLowerCase() === "k";
      if ((e.metaKey || e.ctrlKey) && isK) {
        e.preventDefault();
        setOpen((v) => !v);
        setQuery("");
        setActive(0);
        return;
      }
      if (!open) return;
      if (e.key === "Escape") {
        setOpen(false);
        return;
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        setActive((v) => Math.min(v + 1, Math.max(0, filtered.length - 1)));
        return;
      }
      if (e.key === "ArrowUp") {
        e.preventDefault();
        setActive((v) => Math.max(v - 1, 0));
        return;
      }
      if (e.key === "Enter") {
        e.preventDefault();
        const it = filtered[active];
        if (it) {
          it.run();
          setOpen(false);
        }
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, filtered, active]);

  if (!open) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) setOpen(false);
      }}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 80,
        background: "var(--ds-bg-overlay)",
        backdropFilter: "blur(10px)",
        display: "grid",
        placeItems: "center",
        padding: 18
      }}
    >
      <div
        className="ds-card"
        style={{
          width: "min(680px, 96vw)",
          padding: 12,
          boxShadow: "var(--ds-shadow-panel)"
        }}
      >
        <input
          className="ds-input"
          autoFocus
          placeholder="Search…"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setActive(0);
          }}
        />

        <div style={{ marginTop: 10, display: "grid", gap: 8 }}>
          {filtered.length === 0 ? (
            <div style={{ color: "var(--ds-text-3)", fontSize: 13, padding: 10 }}>No results.</div>
          ) : (
            filtered.map((it, idx) => (
              <button
                key={it.id}
                className="ds-btn"
                onMouseEnter={() => setActive(idx)}
                onClick={() => {
                  it.run();
                  setOpen(false);
                }}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  gap: 10,
                  padding: "10px 12px",
                  background: idx === active ? "rgba(255,255,255,0.06)" : "transparent"
                }}
              >
                <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>{it.title}</div>
                <div style={{ color: "var(--ds-text-3)", fontSize: 12 }}>{it.hint ?? ""}</div>
              </button>
            ))
          )}
        </div>

        <div style={{ marginTop: 10, color: "var(--ds-text-3)", fontSize: 12, padding: "0 4px 2px" }}>
          ↑↓ to navigate, Enter to run, Esc to close
        </div>
      </div>
    </div>
  );
}
