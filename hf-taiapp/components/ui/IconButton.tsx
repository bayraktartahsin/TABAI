"use client";

import React from "react";
import IconSlot, { type IconSlotSize } from "@/components/ui/IconSlot";
import type { AppIconIntent, AppIconName } from "@/components/ui/AppIcon";

// Backwards-compatible wrapper for existing call sites (UI only).
export default function IconButton(props: {
  title: string;
  onClick?: () => void;
  href?: string;
  target?: string;
  rel?: string;
  name: AppIconName;
  intent?: AppIconIntent;
  size?: IconSlotSize;
}) {
  return (
    <IconSlot
      title={props.title}
      name={props.name}
      intent={props.intent}
      size={props.size}
      onClick={props.onClick}
      href={props.href}
      target={props.target}
      rel={props.rel}
    />
  );
}

