"use client";

import React from "react";
import AppIcon, { type AppIconIntent, type AppIconName } from "@/components/ui/AppIcon";

export type IconSlotSize = "compact" | "default" | "large";

export default function IconSlot(props: {
  name: AppIconName;
  title: string;
  intent?: AppIconIntent;
  size?: IconSlotSize;
  optical?: boolean;
  round?: boolean;
  onClick?: () => void;
  href?: string;
  target?: string;
  rel?: string;
  className?: string;
}) {
  const size = props.size ?? "default";
  const intent = props.intent ?? "default";

  const cls = [
    "ds-iconSlot",
    size === "compact" ? "ds-iconSlot--compact" : "",
    size === "large" ? "ds-iconSlot--large" : "",
    props.round ? "ds-iconSlot--round" : "",
    props.className ?? ""
  ]
    .filter(Boolean)
    .join(" ");

  const iconSize = size === "compact" ? 18 : size === "large" ? 22 : 20;

  const content = (
    <span className="ds-iconSlot__inner">
      <AppIcon name={props.name} size={iconSize} optical={props.optical ?? true} />
    </span>
  );

  const style = {
    ["--ds-iconSlot-color" as any]:
      intent === "danger"
        ? "var(--ds-icon-color-danger)"
        : intent === "active"
          ? "var(--ds-icon-color-active)"
          : intent === "muted"
            ? "var(--ds-icon-color-muted)"
            : "var(--ds-icon-color-default)",
    ["--ds-iconSlot-color-hover" as any]:
      intent === "danger"
        ? "var(--ds-icon-color-danger)"
        : "var(--ds-icon-color-active)",
    ["--ds-iconSlot-color-active" as any]:
      intent === "danger"
        ? "var(--ds-icon-color-danger)"
        : "var(--ds-icon-color-active)"
  } as React.CSSProperties;

  if (props.href) {
    return (
      <a
        className={cls}
        title={props.title}
        aria-label={props.title}
        href={props.href}
        target={props.target}
        rel={props.rel}
        style={style}
      >
        {content}
      </a>
    );
  }

  return (
    <button
      className={cls}
      title={props.title}
      aria-label={props.title}
      onClick={props.onClick}
      type="button"
      style={style}
    >
      {content}
    </button>
  );
}
