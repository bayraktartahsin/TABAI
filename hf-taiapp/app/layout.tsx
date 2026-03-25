import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/ui/ThemeProvider";

export const metadata: Metadata = {
  metadataBase: new URL("https://ai.gravitilabs.com"),
  title: "TABAI",
  description: "TABAI premium multi-model AI assistant",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: "/favicon.png",
    apple: "/apple-touch-icon.png"
  }
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const apiBaseUrl =
    process.env.TAI_API_BASE_URL ??
    process.env.NEXT_PUBLIC_TAI_API_BASE_URL ??
    "";
  return (
    <html lang="en" data-theme="dark">
      <body>
        <script
          dangerouslySetInnerHTML={{
            __html: `window.__TAI_API_BASE_URL__ = ${JSON.stringify(apiBaseUrl)};`
          }}
        />
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
