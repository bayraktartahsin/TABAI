"use client";

import React from "react";
import { tokens } from "@/lib/design-system/tokens";

export type AppIconName =
  | "sun-moon"
  | "plus"
  | "folder-plus"
  | "trash"
  | "link"
  | "copy-plus"
  | "pencil"
  | "chevron-left"
  | "chevron-right"
  | "shield"
  | "external-link"
  | "user"
  | "menu"
  | "search"
  | "send"
  | "stop"
  | "refresh"
  | "copy"
  | "paperclip"
  | "mic"
  | "image"
  | "settings"
  | "logout"
  | "panel-left"
  | "close";

export type AppIconIntent = "default" | "muted" | "active" | "danger";

type IconProps = {
  size?: number;
  className?: string;
  style?: React.CSSProperties;
  strokeWidth?: number;
};

type IconDef = (p: IconProps) => React.ReactElement;

function BaseSvg(props: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      width={props.size ?? 20}
      height={props.size ?? 20}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={props.strokeWidth ?? 1.85}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={props.className}
      style={props.style}
      aria-hidden="true"
      focusable="false"
    >
      {props.children}
    </svg>
  );
}

const Icons: Record<AppIconName, IconDef> = {
  "sun-moon": (p) => <BaseSvg {...p}><circle cx="12" cy="12" r="4" /><path d="M12 3v1" /><path d="M12 20v1" /><path d="M3 12h1" /><path d="M20 12h1" /></BaseSvg>,
  plus: (p) => <BaseSvg {...p}><path d="M12 5v14" /><path d="M5 12h14" /></BaseSvg>,
  "folder-plus": (p) => <BaseSvg {...p}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" /><path d="M12 10v6" /><path d="M9 13h6" /></BaseSvg>,
  trash: (p) => <BaseSvg {...p}><path d="M3 6h18" /><path d="M8 6V4h8v2" /><path d="M19 6l-1 14H6L5 6" /><path d="M10 11v6" /><path d="M14 11v6" /></BaseSvg>,
  link: (p) => <BaseSvg {...p}><path d="M10 13a5 5 0 0 0 7.07 0l2.83-2.83a5 5 0 1 0-7.07-7.07L11 4" /><path d="M14 11a5 5 0 0 0-7.07 0L4.1 13.83a5 5 0 1 0 7.07 7.07L13 20" /></BaseSvg>,
  "copy-plus": (p) => <BaseSvg {...p}><rect x="9" y="9" width="11" height="11" rx="2" /><path d="M5 15V5a2 2 0 0 1 2-2h6" /><path d="M15 12v5" /><path d="M12.5 14.5h5" /></BaseSvg>,
  pencil: (p) => <BaseSvg {...p}><path d="M12 20h9" /><path d="m16.5 3.5 4 4L8 20l-4 1 1-4Z" /></BaseSvg>,
  "chevron-left": (p) => <BaseSvg {...p}><path d="M15 18l-6-6 6-6" /></BaseSvg>,
  "chevron-right": (p) => <BaseSvg {...p}><path d="M9 18l6-6-6-6" /></BaseSvg>,
  shield: (p) => <BaseSvg {...p}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></BaseSvg>,
  "external-link": (p) => <BaseSvg {...p}><path d="M15 3h6v6" /><path d="M10 14L21 3" /><path d="M21 14v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h6" /></BaseSvg>,
  user: (p) => <BaseSvg {...p}><circle cx="12" cy="8" r="4" /><path d="M20 21a8 8 0 0 0-16 0" /></BaseSvg>,
  menu: (p) => <BaseSvg {...p}><path d="M4 7h16" /><path d="M4 12h16" /><path d="M4 17h16" /></BaseSvg>,
  search: (p) => <BaseSvg {...p}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></BaseSvg>,
  send: (p) => <BaseSvg {...p}><path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" /></BaseSvg>,
  stop: (p) => <BaseSvg {...p}><rect x="6" y="6" width="12" height="12" rx="2" /></BaseSvg>,
  refresh: (p) => <BaseSvg {...p}><path d="M3 12a9 9 0 0 1 15-6l3 3" /><path d="M21 12a9 9 0 0 1-15 6l-3-3" /><path d="M21 3v6h-6" /><path d="M3 21v-6h6" /></BaseSvg>,
  copy: (p) => <BaseSvg {...p}><rect x="9" y="9" width="11" height="11" rx="2" /><path d="M5 15V5a2 2 0 0 1 2-2h10" /></BaseSvg>,
  paperclip: (p) => <BaseSvg {...p}><path d="m21.44 11.05-8.49 8.49a5 5 0 0 1-7.07-7.07l9.19-9.19a3.5 3.5 0 1 1 4.95 4.95L10.8 17.45a2 2 0 0 1-2.83-2.83l8.49-8.48" /></BaseSvg>,
  mic: (p) => <BaseSvg {...p}><rect x="9" y="2" width="6" height="12" rx="3" /><path d="M5 10a7 7 0 0 0 14 0" /><path d="M12 19v3" /></BaseSvg>,
  image: (p) => <BaseSvg {...p}><rect x="3" y="4" width="18" height="16" rx="2" /><circle cx="8.5" cy="9.5" r="1.5" /><path d="m21 15-5-5L5 21" /></BaseSvg>,
  settings: (p) => <BaseSvg {...p}><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1 1 0 0 0 .2 1.1l.1.1a2 2 0 0 1-2.8 2.8l-.1-.1a1 1 0 0 0-1.1-.2 1 1 0 0 0-.6.9V20a2 2 0 1 1-4 0v-.2a1 1 0 0 0-.6-.9 1 1 0 0 0-1.1.2l-.1.1a2 2 0 0 1-2.8-2.8l.1-.1a1 1 0 0 0 .2-1.1 1 1 0 0 0-.9-.6H4a2 2 0 1 1 0-4h.2a1 1 0 0 0 .9-.6 1 1 0 0 0-.2-1.1l-.1-.1a2 2 0 0 1 2.8-2.8l.1.1a1 1 0 0 0 1.1.2 1 1 0 0 0 .6-.9V4a2 2 0 1 1 4 0v.2a1 1 0 0 0 .6.9 1 1 0 0 0 1.1-.2l.1-.1a2 2 0 0 1 2.8 2.8l-.1.1a1 1 0 0 0-.2 1.1 1 1 0 0 0 .9.6H20a2 2 0 1 1 0 4h-.2a1 1 0 0 0-.9.6z" /></BaseSvg>,
  logout: (p) => <BaseSvg {...p}><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="m16 17 5-5-5-5" /><path d="M21 12H9" /></BaseSvg>,
  "panel-left": (p) => <BaseSvg {...p}><rect x="3" y="3" width="18" height="18" rx="2" /><path d="M9 3v18" /></BaseSvg>,
  close: (p) => <BaseSvg {...p}><path d="M18 6 6 18" /><path d="m6 6 12 12" /></BaseSvg>
};

const opticalTweaks: Partial<Record<AppIconName, { x?: number; y?: number; s?: number }>> = {
  send: { x: 0.2, y: -0.1, s: 1.02 },
  plus: { s: 1.02 },
  "chevron-left": { x: -0.25, s: 1.02 },
  "chevron-right": { x: 0.25, s: 1.02 },
  settings: { s: 0.99 },
  copy: { y: -0.1 },
  paperclip: { y: -0.05 }
};

export default function AppIcon(props: {
  name: AppIconName;
  size?: number;
  className?: string;
  intent?: AppIconIntent;
  optical?: boolean;
}) {
  const Icon = Icons[props.name];
  const tweak = props.optical ? opticalTweaks[props.name] : undefined;

  const transform =
    tweak && (tweak.x || tweak.y || tweak.s)
      ? `translate(${tweak.x ?? 0}px, ${tweak.y ?? 0}px) scale(${tweak.s ?? 1})`
      : undefined;

  const forcedColor =
    props.intent === "muted"
      ? "var(--ds-icon-color-muted)"
      : props.intent === "active"
        ? "var(--ds-icon-color-active)"
        : props.intent === "danger"
          ? "var(--ds-icon-color-danger)"
          : props.intent === "default"
            ? "var(--ds-icon-color-default)"
            : undefined;

  return (
    <span
      className={props.className}
      style={{
        display: "inline-grid",
        placeItems: "center",
        color: forcedColor,
        transform,
        transformOrigin: "center"
      }}
    >
      <Icon size={props.size ?? 20} strokeWidth={Number.parseFloat(tokens.icon.strokeWidth)} />
    </span>
  );
}
