"use client";

import React from "react";
import Link from "next/link";
import {
  confirmPasswordReset,
  confirmVerification,
  requestPasswordReset,
  requestVerification,
  signin,
  signup
} from "@/lib/owui/client";

type Mode = "signin" | "signup" | "verify" | "verifying" | "verified" | "reset-request" | "reset-confirm" | "reset-done";

export default function LoginScreen(props: { onSignedIn: () => void | Promise<void> }) {
  const [mode, setMode] = React.useState<Mode>("signin");
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [username, setUsername] = React.useState("");
  const [displayName, setDisplayName] = React.useState("");
  const [token, setToken] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [confirmPw, setConfirmPw] = React.useState("");
  const [busy, setBusy] = React.useState(false);
  const [err, setErr] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);

  // Auto-detect auth URL params and auto-verify
  const autoVerifyRef = React.useRef(false);
  React.useEffect(() => {
    if (typeof window === "undefined") return;
    const url = new URL(window.location.href);
    const authAction = url.searchParams.get("auth");
    const linkToken = url.searchParams.get("token") ?? "";
    const linkEmail = url.searchParams.get("email") ?? "";
    if (linkEmail) setEmail(linkEmail);
    if (!linkToken) return;
    setToken(linkToken);
    if (authAction === "verify" && !autoVerifyRef.current) {
      autoVerifyRef.current = true;
      setMode("verifying");
      // Auto-submit verification
      confirmVerification(linkToken)
        .then(() => { setMode("verified"); clearAuthQuery(); })
        .catch((e: any) => {
          const code = e?.code as string | undefined;
          if (code === "TOKEN_EXPIRED") setErr("This verification link has expired.");
          else if (code === "TOKEN_INVALID" || code === "TOKEN_USED") setErr("This verification link is invalid.");
          else setErr(e?.message ?? "Verification failed.");
          setMode("verify");
        });
    }
    if (authAction === "reset") {
      setMode("reset-confirm");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const clearAuthQuery = React.useCallback(() => {
    if (typeof window === "undefined") return;
    const next = `${window.location.origin}${window.location.pathname}${window.location.hash}`;
    window.history.replaceState({}, "", next);
  }, []);

  const pwMatch = mode === "reset-confirm" ? newPassword === confirmPw : true;

  const canSubmit =
    !busy &&
    ((mode === "signin" && !!email && !!password) ||
      (mode === "signup" && !!email && !!password) ||
      (mode === "verify" && (!!token || !!email)) ||
      (mode === "reset-request" && !!email) ||
      (mode === "reset-confirm" && !!token && !!newPassword && !!confirmPw && pwMatch));

  const submit = async () => {
    if (!canSubmit) return;
    setBusy(true);
    setErr(null);
    setNotice(null);
    try {
      if (mode === "signin") {
        await signin(email.trim(), password);
        await props.onSignedIn();
        return;
      }

      if (mode === "signup") {
        const data = await signup({
          email: email.trim(),
          password,
          username: username.trim() || undefined,
          displayName: displayName.trim() || undefined
        });
        const tokenHint = typeof data?.verificationToken === "string" ? ` Debug token: ${data.verificationToken}` : "";
        const deliveryNote = data?.verificationEmailSent === false
          ? "Account created, but we couldn't send the verification email right now."
          : "Account created. Check your email for a verification link.";
        setNotice(`${deliveryNote}${tokenHint}`);
        setMode("verify");
        if (typeof data?.verificationToken === "string") setToken(data.verificationToken);
        return;
      }

      if (mode === "verify") {
        if (token.trim()) {
          setMode("verifying");
          await confirmVerification(token.trim());
          setMode("verified");
          clearAuthQuery();
          return;
        }
        const data = await requestVerification(email.trim());
        const tokenHint = typeof data?.verificationToken === "string" ? ` Debug token: ${data.verificationToken}` : "";
        setNotice(`If an account exists for this email, we've sent a verification link.${tokenHint}`);
        if (typeof data?.verificationToken === "string") setToken(data.verificationToken);
        return;
      }

      if (mode === "reset-request") {
        const data = await requestPasswordReset(email.trim());
        const tokenHint = typeof data?.resetToken === "string" ? ` Debug token: ${data.resetToken}` : "";
        setNotice(`If an account exists for this email, we've sent instructions to reset your password.${tokenHint}`);
        if (typeof data?.resetToken === "string") {
          setToken(data.resetToken);
          setMode("reset-confirm");
        }
        return;
      }

      if (mode === "reset-confirm") {
        if (newPassword !== confirmPw) {
          setErr("Passwords do not match.");
          return;
        }
        await confirmPasswordReset(token.trim(), newPassword);
        setMode("reset-done");
        clearAuthQuery();
      }
    } catch (e: any) {
      const code = e?.code as string | undefined;
      if (code === "EMAIL_NOT_VERIFIED") {
        setErr("Verify your email to sign in. Check your inbox for the verification link.");
        setMode("verify");
      } else if (code === "TOKEN_EXPIRED") {
        setErr("This link has expired. Please request a new one.");

      } else if (code === "TOKEN_INVALID" || code === "TOKEN_USED") {
        setErr("This link is invalid. Please request a new one.");

      } else {
        setErr(e?.message ?? "Something went wrong. Please try again.");
      }
    } finally {
      setBusy(false);
    }
  };

  const heading =
    mode === "signin" ? "Sign in to TABAI" :
    mode === "signup" ? "Create your account" :
    mode === "verify" ? "Verify your email" :
    mode === "verifying" ? "Verifying your email..." :
    mode === "verified" ? "Email verified" :
    mode === "reset-request" ? "Reset your password" :
    mode === "reset-confirm" ? "Set a new password" :
    mode === "reset-done" ? "Password reset" : "";

  const subtitle =
    mode === "signin" ? "Enter your email and password to continue." :
    mode === "signup" ? "Create a free account to get started." :
    mode === "verify" ? "Enter the token from your email or request a new verification link." :
    mode === "verifying" ? "" :
    mode === "verified" ? "Your email has been verified. You can now sign in." :
    mode === "reset-request" ? "Enter your email and we'll send you a link to reset your password." :
    mode === "reset-confirm" ? "" :
    mode === "reset-done" ? "Your password has been reset. You can now sign in." : "";

  // Verifying spinner state
  if (mode === "verifying") {
    return (
      <div style={styles.page}>
        <div style={styles.card}>
          <div style={styles.wordmark}>TABAI</div>
          <div style={styles.divider} />
          <div style={styles.heading}>Verifying your email...</div>
          <div style={{ display: "flex", justifyContent: "center", padding: "32px 0" }}>
            <div style={styles.spinner} />
          </div>
        </div>
      </div>
    );
  }

  // Success states
  if (mode === "verified" || mode === "reset-done") {
    return (
      <div style={styles.page}>
        <div style={styles.card}>
          <div style={styles.wordmark}>TABAI</div>
          <div style={styles.divider} />
          <div style={{ display: "flex", justifyContent: "center", padding: "24px 0 16px" }}>
            <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
              <circle cx="24" cy="24" r="24" fill="#34C759" opacity="0.12" />
              <path d="M15 24.5L21 30.5L33 18.5" stroke="#34C759" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div style={styles.heading}>{heading}</div>
          <div style={styles.subtitle}>{subtitle}</div>
          <button
            style={styles.primaryBtn}
            onClick={() => { setMode("signin"); setErr(null); setNotice(null); }}
          >
            {mode === "verified" ? "Continue to Sign In" : "Sign In"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.page}>
      <form
        style={styles.card}
        onSubmit={(e) => { e.preventDefault(); void submit(); }}
      >
        <div style={styles.wordmark}>TABAI</div>
        <div style={styles.divider} />
        <div style={styles.heading}>{heading}</div>
        {subtitle && <div style={styles.subtitle}>{subtitle}</div>}

        <div style={{ display: "grid", gap: 12, width: "100%", marginTop: 24 }}>
          {/* Email field */}
          {(mode === "signin" || mode === "signup" || mode === "verify" || mode === "reset-request") && (
            <input
              style={styles.input}
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoCapitalize="none"
              autoCorrect="off"
              inputMode="email"
              autoComplete="email"
              type="email"
            />
          )}

          {/* Password field */}
          {(mode === "signin" || mode === "signup") && (
            <input
              style={styles.input}
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              type="password"
              autoComplete={mode === "signin" ? "current-password" : "new-password"}
            />
          )}

          {/* Forgot password link */}
          {mode === "signin" && (
            <div style={{ textAlign: "right", marginTop: -4 }}>
              <button
                type="button"
                onClick={() => { setMode("reset-request"); setErr(null); setNotice(null); }}
                style={styles.linkBtn}
              >
                Forgot Password?
              </button>
            </div>
          )}

          {/* Signup extra fields */}
          {mode === "signup" && (
            <>
              <input
                style={styles.input}
                placeholder="Username (optional)"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoCapitalize="none"
                autoCorrect="off"
              />
              <input
                style={styles.input}
                placeholder="Display name (optional)"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
              />
              <div style={styles.hint}>
                Password must be 8+ characters with uppercase, lowercase, number, and special character.
              </div>
            </>
          )}

          {/* Verification token */}
          {mode === "verify" && (
            <input
              style={styles.input}
              placeholder="Verification token"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              autoCapitalize="none"
              autoCorrect="off"
            />
          )}

          {/* Reset confirm: email (read-only) + new password + confirm */}
          {mode === "reset-confirm" && (
            <>
              <input
                style={{ ...styles.input, opacity: 0.6, cursor: "default" }}
                value={email}
                readOnly
                tabIndex={-1}
              />
              <input
                style={styles.input}
                placeholder="New password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                type="password"
                autoComplete="new-password"
              />
              <input
                style={styles.input}
                placeholder="Confirm new password"
                value={confirmPw}
                onChange={(e) => setConfirmPw(e.target.value)}
                type="password"
                autoComplete="new-password"
              />
              {confirmPw && !pwMatch && (
                <div style={{ ...styles.hint, color: "#FF3B30" }}>Passwords do not match.</div>
              )}
              <div style={styles.hint}>
                8+ characters, uppercase, lowercase, number, and special character.
              </div>
            </>
          )}
        </div>

        {/* Error */}
        {err && <div style={styles.error}>{err}</div>}

        {/* Notice */}
        {notice && <div style={styles.notice}>{notice}</div>}

        {/* Resend verification link */}
        {mode === "verify" && email && (
          <button
            type="button"
            onClick={async () => {
              setErr(null);
              const data = await requestVerification(email.trim()).catch(() => null);
              const tokenHint = typeof data?.verificationToken === "string" ? ` Debug token: ${data.verificationToken}` : "";
              setNotice(`Verification email sent.${tokenHint}`);
              if (typeof data?.verificationToken === "string") setToken(data.verificationToken);
            }}
            style={{ ...styles.linkBtn, marginTop: 8 }}
          >
            Resend Verification Email
          </button>
        )}

        {/* Submit button */}
        <button
          style={{
            ...styles.primaryBtn,
            marginTop: 20,
            opacity: canSubmit ? 1 : 0.5,
            cursor: canSubmit ? "pointer" : "default",
          }}
          disabled={!canSubmit}
          type="submit"
        >
          {busy
            ? "Working..."
            : mode === "signin" ? "Sign In"
            : mode === "signup" ? "Create Account"
            : mode === "verify" ? (token.trim() ? "Verify Email" : "Send Verification Link")
            : mode === "reset-request" ? "Send Reset Link"
            : "Reset Password"}
        </button>

        {/* Mode switchers */}
        <div style={{ marginTop: 20, textAlign: "center", fontSize: 14, color: "#86868b" }}>
          {mode === "signin" && (
            <>Don&apos;t have an account?{" "}
              <button type="button" onClick={() => { setMode("signup"); setErr(null); setNotice(null); }} style={styles.linkBtn}>Sign Up</button>
            </>
          )}
          {mode === "signup" && (
            <>Already have an account?{" "}
              <button type="button" onClick={() => { setMode("signin"); setErr(null); setNotice(null); }} style={styles.linkBtn}>Sign In</button>
            </>
          )}
          {(mode === "verify" || mode === "reset-request" || mode === "reset-confirm") && (
            <button type="button" onClick={() => { setMode("signin"); setErr(null); setNotice(null); }} style={styles.linkBtn}>Back to Sign In</button>
          )}
        </div>

        {/* Legal links */}
        <div style={styles.legalLinks}>
          <Link href="/tabai/privacy" style={styles.legalLink}>Privacy</Link>
          <span style={{ color: "#d2d2d7" }}>&middot;</span>
          <Link href="/tabai/terms" style={styles.legalLink}>Terms</Link>
          <span style={{ color: "#d2d2d7" }}>&middot;</span>
          <Link href="/tabai/support" style={styles.legalLink}>Support</Link>
        </div>
      </form>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  page: {
    minHeight: "100dvh",
    display: "grid",
    placeItems: "center",
    padding: 24,
    background: "#f5f5f7",
  },
  card: {
    width: "min(440px, 92vw)",
    padding: "48px 40px",
    background: "#ffffff",
    borderRadius: 12,
    boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
  },
  wordmark: {
    fontSize: 28,
    fontWeight: 700,
    letterSpacing: 6,
    color: "#1d1d1f",
    textAlign: "center",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  divider: {
    width: 40,
    height: 1,
    background: "#d2d2d7",
    margin: "20px 0",
  },
  heading: {
    fontSize: 22,
    fontWeight: 600,
    color: "#1d1d1f",
    textAlign: "center",
    lineHeight: "1.25",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  subtitle: {
    fontSize: 15,
    color: "#424245",
    textAlign: "center",
    lineHeight: "1.5",
    marginTop: 8,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  input: {
    width: "100%",
    padding: "12px 16px",
    fontSize: 16,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
    border: "1px solid #d2d2d7",
    borderRadius: 10,
    outline: "none",
    color: "#1d1d1f",
    background: "#ffffff",
    boxSizing: "border-box",
    transition: "border-color 0.2s",
  },
  primaryBtn: {
    width: "100%",
    padding: "14px 44px",
    fontSize: 16,
    fontWeight: 600,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
    background: "#0071e3",
    color: "#ffffff",
    border: "none",
    borderRadius: 980,
    cursor: "pointer",
    textAlign: "center" as const,
  },
  linkBtn: {
    background: "none",
    border: "none",
    color: "#0071e3",
    fontSize: 14,
    cursor: "pointer",
    padding: 0,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  hint: {
    fontSize: 13,
    color: "#86868b",
    lineHeight: "1.4",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  error: {
    marginTop: 16,
    fontSize: 14,
    color: "#FF3B30",
    textAlign: "center",
    lineHeight: "1.4",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  notice: {
    marginTop: 16,
    fontSize: 14,
    color: "#424245",
    textAlign: "center",
    lineHeight: "1.4",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
  legalLinks: {
    marginTop: 24,
    display: "flex",
    gap: 8,
    fontSize: 12,
    justifyContent: "center",
    flexWrap: "wrap" as const,
  },
  legalLink: {
    color: "#86868b",
    textDecoration: "none",
  },
  spinner: {
    width: 32,
    height: 32,
    border: "3px solid #d2d2d7",
    borderTopColor: "#0071e3",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
  },
};

// Add spinner keyframes via a style tag
if (typeof document !== "undefined" && !document.getElementById("login-spinner-style")) {
  const style = document.createElement("style");
  style.id = "login-spinner-style";
  style.textContent = "@keyframes spin { to { transform: rotate(360deg); } }";
  document.head.appendChild(style);
}
