import Link from "next/link";

export default function PricingPage() {
  return (
    <div style={{ minHeight: "100dvh", padding: 24 }}>
      <div style={{ maxWidth: 1080, margin: "0 auto" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
          <div>
            <div style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-0.03em" }}>Pricing</div>
            <div style={{ color: "var(--ds-text-2)", marginTop: 8, fontSize: 13 }}>
              Clean, enterprise-grade plans. No noise.
            </div>
          </div>
          <Link className="ds-btn" href="/">
            Back to Chat
          </Link>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, minmax(0, 1fr))", gap: 12, marginTop: 18 }}>
          <Plan
            title="Free"
            price="$0"
            badge="Free"
            items={[
              "8 free AI models",
              "30 messages / day",
              "1 concurrent chat",
            ]}
            cta="Current plan"
            emphasized={false}
          />
          <Plan
            title="Starter"
            price="$9.99"
            yearlyPrice="$79.99"
            badge="Essential"
            items={[
              "Top AI models access",
              "100+ messages / day",
              "5 AI images / month",
              "Vision models",
              "2 concurrent chats",
            ]}
            cta="Upgrade"
            emphasized={false}
          />
          <Plan
            title="Pro"
            price="$49.99"
            yearlyPrice="$399.99"
            badge="Recommended"
            items={[
              "Advanced reasoning models",
              "200+ messages / day",
              "15 images + 1 video / mo",
              "Image understanding",
              "3 concurrent chats",
            ]}
            cta="Upgrade"
            emphasized={true}
          />
          <Plan
            title="Power"
            price="$119.99"
            yearlyPrice="$999.99"
            badge="Maximum"
            items={[
              "All AI models unlocked",
              "500+ messages / day",
              "60 images + 3 videos / mo",
              "Premium reasoning (O1, O3)",
              "4 concurrent chats",
              "Priority access",
            ]}
            cta="Upgrade"
            emphasized={false}
          />
        </div>

        <div style={{ marginTop: 16, color: "var(--ds-text-3)", fontSize: 12 }}>
          Manage subscription:
          <Link className="ds-btn" href="/subscription" style={{ padding: "6px 8px", marginLeft: 6 }}>
            Open billing details
          </Link>
        </div>

        <div
          style={{
            marginTop: 14,
            display: "flex",
            flexWrap: "wrap",
            gap: 8,
            alignItems: "center",
            color: "var(--ds-text-3)",
            fontSize: 12
          }}
        >
          <Link href="/privacy">Privacy</Link>
          <span>•</span>
          <Link href="/terms">Terms</Link>
          <span>•</span>
          <Link href="/acceptable-use">Acceptable Use</Link>
          <span>•</span>
          <Link href="/subscription">Subscription</Link>
          <span>•</span>
          <Link href="/support">Support</Link>
        </div>
      </div>
    </div>
  );
}

function Plan(props: {
  title: string;
  price: string;
  yearlyPrice?: string;
  badge: string;
  items: string[];
  cta: string;
  emphasized: boolean;
}) {
  return (
    <div
      className="ds-card"
      style={{
        padding: 16,
        borderColor: props.emphasized ? "rgba(255,255,255,0.20)" : "var(--ds-border)"
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontWeight: 600, letterSpacing: "-0.02em" }}>{props.title}</div>
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
          {props.badge}
        </span>
      </div>
      <div style={{ marginTop: 10, fontSize: 30, fontWeight: 600, letterSpacing: "-0.03em" }}>
        {props.price}<span style={{ fontSize: 13, color: "var(--ds-text-3)", marginLeft: 6 }}>/mo</span>
      </div>
      {props.yearlyPrice && (
        <div style={{ marginTop: 4, fontSize: 12, color: "var(--ds-text-3)" }}>
          or {props.yearlyPrice}/yr <span style={{ color: "var(--ds-accent)", fontWeight: 600 }}>save 33%</span>
        </div>
      )}
      <div style={{ marginTop: 12, display: "grid", gap: 8, color: "var(--ds-text-2)", fontSize: 13 }}>
        {props.items.map((x) => (
          <div key={x} style={{ display: "flex", gap: 8 }}>
            <span style={{ color: "var(--ds-text-3)" }}>•</span>
            <span>{x}</span>
          </div>
        ))}
      </div>
      <button
        className="ds-btn"
        style={{
          width: "100%",
          marginTop: 14,
          background: props.emphasized ? "var(--ds-accent-soft)" : "rgba(255,255,255,0.03)"
        }}
      >
        {props.cta}
      </button>
    </div>
  );
}
