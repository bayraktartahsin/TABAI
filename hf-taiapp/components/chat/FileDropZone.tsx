"use client";

import React from "react";

export default function FileDropZone(props: {
  files: File[];
  setFiles: (f: File[]) => void;
}) {
  const [over, setOver] = React.useState(false);
  const inputRef = React.useRef<HTMLInputElement | null>(null);

  const add = (list: FileList | null) => {
    if (!list || list.length === 0) return;
    const next = [...props.files, ...Array.from(list)].slice(0, 8);
    props.setFiles(next);
  };

  return (
    <div
      onDragEnter={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setOver(true);
      }}
      onDragOver={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setOver(true);
      }}
      onDragLeave={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setOver(false);
      }}
      onDrop={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setOver(false);
        add(e.dataTransfer.files);
      }}
      style={{
        border: `1px dashed ${over ? "rgba(255,255,255,0.22)" : "var(--ds-border)"}`,
        borderRadius: "16px",
        padding: 12,
        background: over ? "rgba(255,255,255,0.04)" : "transparent",
        transition: `background var(--ds-motion-fast) var(--ds-ease), border-color var(--ds-motion-fast) var(--ds-ease)`
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ color: "var(--ds-text-2)", fontSize: 13 }}>
          Drag & drop files, or{" "}
          <button
            className="ds-btn"
            style={{ padding: "6px 8px" }}
            onClick={() => inputRef.current?.click()}
            type="button"
          >
            Browse
          </button>
        </div>
        <div style={{ flex: 1 }} />
        <div style={{ color: "var(--ds-text-3)", fontSize: 12 }}>
          {props.files.length}/8
        </div>
      </div>

      <input
        ref={inputRef}
        type="file"
        multiple
        style={{ display: "none" }}
        onChange={(e) => add(e.target.files)}
      />

      {props.files.length ? (
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 10 }}>
          {props.files.map((f) => (
            <div
              key={f.name + f.size}
              style={{
                padding: "8px 10px",
                borderRadius: 14,
                border: "1px solid var(--ds-border)",
                background: "rgba(255,255,255,0.03)",
                display: "flex",
                alignItems: "center",
                gap: 10
              }}
            >
              <div style={{ fontSize: 12, color: "var(--ds-text-2)" }}>{f.name}</div>
              <button
                className="ds-btn"
                style={{ padding: "6px 8px" }}
                type="button"
                onClick={() => props.setFiles(props.files.filter((x) => x !== f))}
              >
                Remove
              </button>
            </div>
          ))}
        </div>
      ) : null}

      <div style={{ marginTop: 10, color: "var(--ds-text-3)", fontSize: 12 }}>
        Upload pipeline is UI-only for now (backend unchanged).
      </div>
    </div>
  );
}

