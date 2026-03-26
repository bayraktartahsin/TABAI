"use client";

import React from "react";
import { buildCSSVars, ThemeName } from "@/lib/design-system/tokens";

type ThemeContextValue = {
  theme: ThemeName;
  setTheme: (t: ThemeName) => void;
  toggleTheme: () => void;
};

const ThemeContext = React.createContext<ThemeContextValue | null>(null);

const STORAGE_KEY = "tai.theme";

export function ThemeProvider(props: { children: React.ReactNode }) {
  const [theme, setThemeState] = React.useState<ThemeName>("dark");

  React.useEffect(() => {
    const saved = (localStorage.getItem(STORAGE_KEY) as ThemeName | null) ?? "dark";
    setThemeState(saved === "light" ? "light" : "dark");
  }, []);

  React.useEffect(() => {
    const el = document.documentElement;
    el.dataset.theme = theme;
    // Ensure native UI (scrollbars/form controls) match the selected theme.
    // This also avoids odd tinting in some browsers when switching themes.
    (el.style as any).colorScheme = theme;
    const vars = buildCSSVars(theme);
    for (const [k, v] of Object.entries(vars)) el.style.setProperty(k, v);
    localStorage.setItem(STORAGE_KEY, theme);
  }, [theme]);

  const value = React.useMemo<ThemeContextValue>(() => {
    return {
      theme,
      setTheme: setThemeState,
      toggleTheme: () => setThemeState((t) => (t === "dark" ? "light" : "dark"))
    };
  }, [theme]);

  return <ThemeContext.Provider value={value}>{props.children}</ThemeContext.Provider>;
}

export function useTheme() {
  const ctx = React.useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider");
  return ctx;
}
