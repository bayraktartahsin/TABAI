export type ThemeName = "dark" | "light";

export const tokens = {
  color: {
    Background: {
      base: {
        dark: "#0B0F14",
        light: "#F6F3EE"
      },
      elevated: {
        dark: "#0F1720",
        light: "#FBF9F5"
      },
      overlay: {
        dark: "rgba(8, 12, 18, 0.72)",
        light: "rgba(16, 18, 20, 0.38)"
      }
    },
    Surface: {
      glass: {
        dark: "rgba(20, 28, 38, 0.55)",
        light: "rgba(255, 255, 255, 0.65)"
      }
    },
    Text: {
      primary: {
        dark: "rgba(255,255,255,0.92)",
        light: "rgba(17, 24, 39, 0.92)"
      },
      secondary: {
        dark: "rgba(255,255,255,0.70)",
        light: "rgba(17, 24, 39, 0.70)"
      },
      muted: {
        dark: "rgba(255,255,255,0.52)",
        light: "rgba(17, 24, 39, 0.54)"
      }
    },
    Border: {
      subtle: {
        dark: "rgba(255,255,255,0.10)",
        light: "rgba(17,24,39,0.12)"
      }
    },
    Accent: {
      primary: {
        dark: "#E6E6E6",
        light: "#111827"
      },
      soft: {
        dark: "rgba(255,255,255,0.10)",
        light: "rgba(17,24,39,0.08)"
      }
    },
    Status: {
      danger: { dark: "#EF4444", light: "#DC2626" }
    }
  },
  icon: {
    strokeWidth: "1.85",
    color: {
      default: {
        dark: "rgba(255,255,255,0.70)",
        light: "rgba(17, 24, 39, 0.68)"
      },
      muted: {
        dark: "rgba(255,255,255,0.55)",
        light: "rgba(17, 24, 39, 0.55)"
      },
      active: {
        dark: "rgba(255,255,255,0.92)",
        light: "rgba(17, 24, 39, 0.92)"
      },
      danger: {
        dark: "#EF4444",
        light: "#DC2626"
      }
    },
    slot: {
      bg: {
        default: {
          dark: "rgba(255,255,255,0.035)",
          light: "rgba(17,24,39,0.045)"
        },
        hover: {
          dark: "rgba(255,255,255,0.055)",
          light: "rgba(17,24,39,0.060)"
        },
        active: {
          dark: "rgba(255,255,255,0.070)",
          light: "rgba(17,24,39,0.080)"
        }
      },
      border: {
        dark: "rgba(255,255,255,0.10)",
        light: "rgba(17,24,39,0.12)"
      },
      shadow: {
        dark: "0 1px 0 rgba(255,255,255,0.03), 0 10px 26px rgba(0,0,0,0.30)",
        light: "0 1px 0 rgba(255,255,255,0.55), 0 10px 26px rgba(0,0,0,0.10)"
      }
    }
  },
  typography: {
    font: {
      ui: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif"
    },
    size: {
      xs: "12px",
      sm: "13px",
      md: "15px",
      lg: "17px",
      xl: "20px",
      "2xl": "24px",
      "3xl": "30px"
    },
    line: {
      tight: "1.15",
      normal: "1.45",
      relaxed: "1.65"
    },
    weight: {
      regular: "400",
      medium: "500",
      semibold: "600"
    }
  },
  space: {
    1: "4px",
    2: "8px",
    3: "12px",
    4: "16px",
    5: "20px",
    6: "24px",
    8: "32px",
    10: "40px",
    12: "48px"
  },
  radius: {
    sm: "10px",
    md: "14px",
    lg: "18px",
    pill: "999px"
  },
  shadow: {
    sm: "0 1px 0 rgba(255,255,255,0.04), 0 1px 10px rgba(0,0,0,0.25)",
    md: "0 1px 0 rgba(255,255,255,0.05), 0 10px 30px rgba(0,0,0,0.45)",
    panel: "0 1px 0 rgba(255,255,255,0.06), 0 24px 80px rgba(0,0,0,0.60)"
  },
  motion: {
    duration: {
      fast: "200ms",
      base: "240ms",
      slow: "300ms"
    },
    ease: {
      standard: "cubic-bezier(0.4, 0, 0.2, 1)"
    }
  }
} as const;

export function buildCSSVars(theme: ThemeName): Record<string, string> {
  return {
    "--ds-bg-base": tokens.color.Background.base[theme],
    "--ds-bg-elev": tokens.color.Background.elevated[theme],
    "--ds-bg-overlay": tokens.color.Background.overlay[theme],
    "--ds-surface-glass": tokens.color.Surface.glass[theme],
    "--ds-text": tokens.color.Text.primary[theme],
    "--ds-text-2": tokens.color.Text.secondary[theme],
    "--ds-text-3": tokens.color.Text.muted[theme],
    "--ds-border": tokens.color.Border.subtle[theme],
    "--ds-accent": tokens.color.Accent.primary[theme],
    "--ds-accent-soft": tokens.color.Accent.soft[theme],
    "--ds-danger": tokens.color.Status.danger[theme],
    "--ds-font-ui": tokens.typography.font.ui,
    "--ds-radius-sm": tokens.radius.sm,
    "--ds-radius-md": tokens.radius.md,
    "--ds-radius-lg": tokens.radius.lg,
    "--ds-radius-pill": tokens.radius.pill,
    "--ds-shadow-sm": tokens.shadow.sm,
    "--ds-shadow-md": tokens.shadow.md,
    "--ds-shadow-panel": tokens.shadow.panel,
    "--ds-motion-fast": tokens.motion.duration.fast,
    "--ds-motion-base": tokens.motion.duration.base,
    "--ds-motion-slow": tokens.motion.duration.slow,
    "--ds-ease": tokens.motion.ease.standard,
    "--ds-icon-stroke": tokens.icon.strokeWidth,
    "--ds-icon-color-default": tokens.icon.color.default[theme],
    "--ds-icon-color-muted": tokens.icon.color.muted[theme],
    "--ds-icon-color-active": tokens.icon.color.active[theme],
    "--ds-icon-color-danger": tokens.icon.color.danger[theme],
    "--ds-icon-slot-bg": tokens.icon.slot.bg.default[theme],
    "--ds-icon-slot-bg-hover": tokens.icon.slot.bg.hover[theme],
    "--ds-icon-slot-bg-active": tokens.icon.slot.bg.active[theme],
    "--ds-icon-slot-border": tokens.icon.slot.border[theme],
    "--ds-icon-slot-shadow": tokens.icon.slot.shadow[theme]
  };
}

export const motion = {
  fadeIn: { durationMs: 220, easing: tokens.motion.ease.standard },
  scalePress: { durationMs: 200, easing: tokens.motion.ease.standard },
  slideSoft: { durationMs: 260, easing: tokens.motion.ease.standard },
  sidebarCollapse: { durationMs: 280, easing: tokens.motion.ease.standard },
  panelReveal: { durationMs: 240, easing: tokens.motion.ease.standard }
} as const;
