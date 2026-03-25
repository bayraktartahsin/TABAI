import Link from "next/link";
import type { CSSProperties, ReactNode } from "react";

type LegalSection = {
  heading: string;
  paragraphs: string[];
  bullets?: string[];
};

type LegalDocumentPageProps = {
  title: string;
  intro: string;
  lastUpdated: string;
  sections: LegalSection[];
  contactNote?: ReactNode;
};

const legalNav = [
  { href: "/privacy", label: "Privacy" },
  { href: "/terms", label: "Terms" },
  { href: "/acceptable-use", label: "Acceptable Use" },
  { href: "/subscription", label: "Subscription" },
  { href: "/support", label: "Support" }
];

export default function LegalDocumentPage({
  title,
  intro,
  lastUpdated,
  sections,
  contactNote
}: LegalDocumentPageProps) {
  return (
    <main style={styles.page}>
      <div style={styles.container}>
        <nav aria-label="Legal navigation" style={styles.nav}>
          {legalNav.map((item) => (
            <Link key={item.href} href={item.href} style={styles.navLink}>
              {item.label}
            </Link>
          ))}
        </nav>

        <header style={styles.header}>
          <p style={styles.eyebrow}>TABAI AI Assistant</p>
          <h1 style={styles.title}>{title}</h1>
          <p style={styles.intro}>{intro}</p>
          <p style={styles.meta}>Last updated: {lastUpdated}</p>
          <p style={styles.meta}>Business entity: TABA TASARIM İNŞAAT A.Ş.</p>
        </header>

        <article style={styles.article}>
          {sections.map((section) => (
            <section key={section.heading} style={styles.section}>
              <h2 style={styles.sectionHeading}>{section.heading}</h2>
              {section.paragraphs.map((paragraph) => (
                <p key={paragraph} style={styles.paragraph}>
                  {paragraph}
                </p>
              ))}
              {section.bullets && section.bullets.length > 0 ? (
                <ul style={styles.list}>
                  {section.bullets.map((bullet) => (
                    <li key={bullet} style={styles.listItem}>
                      {bullet}
                    </li>
                  ))}
                </ul>
              ) : null}
            </section>
          ))}
        </article>

        {contactNote ? <footer style={styles.footer}>{contactNote}</footer> : null}
      </div>
    </main>
  );
}

const styles: Record<string, CSSProperties> = {
  page: {
    minHeight: "100dvh",
    background:
      "radial-gradient(circle at 16% 0%, rgba(120, 198, 255, 0.16), transparent 38%), radial-gradient(circle at 84% 8%, rgba(100, 230, 190, 0.12), transparent 36%), var(--ds-bg-base)",
    color: "var(--ds-text)",
    padding: "clamp(20px, 4vw, 42px)"
  },
  container: {
    maxWidth: "960px",
    margin: "0 auto",
    display: "grid",
    gap: "18px"
  },
  nav: {
    display: "flex",
    flexWrap: "wrap",
    gap: "10px"
  },
  navLink: {
    border: "1px solid var(--ds-border)",
    borderRadius: "999px",
    padding: "8px 12px",
    fontSize: "12px",
    color: "var(--ds-text-2)",
    background: "rgba(255, 255, 255, 0.03)"
  },
  header: {
    border: "1px solid var(--ds-border)",
    borderRadius: "18px",
    background: "var(--ds-surface-glass)",
    backdropFilter: "blur(8px)",
    padding: "clamp(18px, 3.4vw, 34px)",
    display: "grid",
    gap: "10px"
  },
  eyebrow: {
    margin: 0,
    textTransform: "uppercase",
    letterSpacing: "0.08em",
    fontSize: "11px",
    color: "var(--ds-text-3)"
  },
  title: {
    margin: 0,
    fontSize: "clamp(28px, 5vw, 44px)",
    lineHeight: 1.05,
    letterSpacing: "-0.02em"
  },
  intro: {
    margin: 0,
    maxWidth: "74ch",
    color: "var(--ds-text-2)",
    lineHeight: 1.6
  },
  meta: {
    margin: 0,
    fontSize: "13px",
    color: "var(--ds-text-3)"
  },
  article: {
    border: "1px solid var(--ds-border)",
    borderRadius: "18px",
    background: "rgba(255, 255, 255, 0.02)",
    padding: "clamp(18px, 3vw, 30px)",
    display: "grid",
    gap: "20px"
  },
  section: {
    display: "grid",
    gap: "8px"
  },
  sectionHeading: {
    margin: 0,
    fontSize: "clamp(20px, 2.6vw, 25px)",
    letterSpacing: "-0.01em"
  },
  paragraph: {
    margin: 0,
    color: "var(--ds-text-2)",
    lineHeight: 1.65
  },
  list: {
    margin: "2px 0 0 18px",
    padding: 0,
    display: "grid",
    gap: "8px"
  },
  listItem: {
    color: "var(--ds-text-2)",
    lineHeight: 1.5
  },
  footer: {
    border: "1px solid var(--ds-border)",
    borderRadius: "16px",
    background: "rgba(255, 255, 255, 0.02)",
    padding: "16px",
    color: "var(--ds-text-2)",
    lineHeight: 1.6
  }
};
