"use client";

import React from "react";
import type { OWModel } from "@/lib/owui/client";
import { displayForModel } from "@/lib/models/catalog";
import IconSlot from "@/components/ui/IconSlot";

export default function ModelSelector(props: {
  open: boolean;
  onClose: () => void;
  models: OWModel[];
  selectedId: string | null;
  onSelect: (m: OWModel) => void;
}) {
  const { open, onClose } = props;
  const [query, setQuery] = React.useState("");

  const filteredModels = React.useMemo(() => {
    const term = query.trim().toLowerCase();
    const ranked = [...props.models].sort((a, b) => {
      const aMeta = displayForModel(a);
      const bMeta = displayForModel(b);
      if (aMeta.verified !== bMeta.verified) return aMeta.verified ? -1 : 1;
      return aMeta.name.localeCompare(bMeta.name);
    });
    if (!term) return ranked;
    return ranked.filter((model) => {
      const meta = displayForModel(model);
      const haystack = [
        meta.name,
        model.provider?.name,
        model.providerModelId,
        meta.vendor,
        ...(meta.tags ?? [])
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      return haystack.includes(term);
    });
  }, [props.models, query]);

  React.useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (!open) return;
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 50,
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
          width: "min(920px, 96vw)",
          maxHeight: "80dvh",
          overflow: "auto",
          padding: 14,
          boxShadow: "var(--ds-shadow-panel)",
          transform: "translateY(0) scale(1)",
          transition: `transform var(--ds-motion-base) var(--ds-ease), opacity var(--ds-motion-base) var(--ds-ease)`
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "4px 4px 10px 4px" }}>
          <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>Select Model</div>
          <div style={{ color: "var(--ds-text-3)", fontSize: 12 }}>{filteredModels.length} available</div>
          <div style={{ flex: 1 }} />
          <IconSlot name="close" title="Close" onClick={onClose} />
        </div>

        <div style={{ padding: "0 4px 12px 4px" }}>
          <input
            className="ds-input"
            placeholder="Search models, vendors, or capabilities"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, minmax(0, 1fr))", gap: 10 }}>
          {filteredModels.map((m) => (
            <ModelCard
              key={m.id}
              model={m}
              selected={props.selectedId === m.id}
              onSelect={() => props.onSelect(m)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function ModelCard(props: { model: OWModel; selected: boolean; onSelect: () => void }) {
  const m = props.model;
  const meta = displayForModel(m);
  const logo = meta.logo;
  const isFree = meta.tier === "free";
  const isFast = meta.speed === "fast";
  const locked = m.canAccess === false;
  const notChatCompatible = m.supportsTextChat === false;
  const disabled = locked || notChatCompatible;

  return (
    <button
      onClick={props.onSelect}
      className="ds-btn"
      disabled={disabled}
      style={{
        textAlign: "left",
        padding: 14,
        borderRadius: "16px",
        background: disabled
          ? "rgba(255,255,255,0.015)"
          : props.selected
            ? "rgba(255,255,255,0.06)"
            : "rgba(255,255,255,0.03)",
        borderColor: props.selected ? "rgba(255,255,255,0.18)" : "var(--ds-border)",
        transform: "translateZ(0)",
        opacity: disabled ? 0.72 : 1,
        cursor: disabled ? "not-allowed" : "pointer"
      }}
    >
      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <div
          style={{
            width: 34,
            height: 34,
            borderRadius: 12,
            border: "1px solid var(--ds-border)",
            background: "rgba(255,255,255,0.03)",
            display: "grid",
            placeItems: "center",
            overflow: "hidden"
          }}
        >
          {logo ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logo} alt="" style={{ width: 22, height: 22, objectFit: "contain" }} />
          ) : (
            <span style={{ fontSize: 12, color: "var(--ds-text-3)" }}>AI</span>
          )}
        </div>

        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontWeight: 600, letterSpacing: "-0.02em", fontSize: 14, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {meta.name}
          </div>
          <div style={{ marginTop: 4, fontSize: 12, color: "var(--ds-text-3)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {meta.vendor ?? m.provider?.name ?? "AI"}
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 8, flexWrap: "wrap" }}>
            <Tag label={isFast ? "Fast" : "Standard"} />
            {(meta.tags.length ? meta.tags : ["Chat"]).slice(0, 3).map((t) => <Tag key={t} label={t} />)}
            {meta.tier !== "unknown" ? <Tag label={isFree ? "Free" : "Paid"} /> : null}
            {m.requiredPlanTier ? <Tag label={`Plan: ${m.requiredPlanTier.toUpperCase()}`} /> : null}
            {locked ? <Tag label="Locked" /> : null}
            {notChatCompatible ? <Tag label="No Chat" /> : null}
          </div>
          {locked && m.lockReason ? (
            <div style={{ marginTop: 8, fontSize: 12, color: "var(--ds-text-3)" }}>
              {m.lockReason}
            </div>
          ) : null}
          {notChatCompatible ? (
            <div style={{ marginTop: 8, fontSize: 12, color: "var(--ds-text-3)" }}>
              This model is not chat-compatible in this app yet.
            </div>
          ) : null}
        </div>

        <div style={{ color: "var(--ds-text-3)", fontSize: 12 }}>
          {locked ? "Locked" : notChatCompatible ? "Unavailable" : props.selected ? "Selected" : meta.verified ? "Ready" : ""}
        </div>
      </div>
    </button>
  );
}

function Tag(props: { label: string }) {
  return (
    <span
      style={{
        fontSize: 12,
        padding: "6px 8px",
        borderRadius: 999,
        border: "1px solid var(--ds-border)",
        background: "rgba(255,255,255,0.03)",
        color: "var(--ds-text-2)"
      }}
    >
      {props.label}
    </span>
  );
}
