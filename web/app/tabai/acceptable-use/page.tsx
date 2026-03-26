import type { Metadata } from "next";
import LegalDocumentPage from "@/components/legal/LegalDocumentPage";

export const metadata: Metadata = {
  title: "Acceptable Use Policy | TABAI AI Assistant",
  description: "Acceptable Use Policy for TABAI AI Assistant by TABA TASARIM İNŞAAT A.Ş."
};

export default function AcceptableUsePage() {
  return (
    <LegalDocumentPage
      title="Acceptable Use Policy"
      intro="This Acceptable Use Policy defines prohibited behavior when using TABAI AI Assistant. It is designed to protect users, infrastructure, and third parties from misuse."
      lastUpdated="March 18, 2026"
      sections={[
        {
          heading: "1. Illegal or Harmful Use",
          paragraphs: [
            "You may not use the service to violate laws, regulations, or third-party rights.",
            "You may not use the service to create, facilitate, or promote violence, harassment, exploitation, or other harmful conduct."
          ]
        },
        {
          heading: "2. Spam and Automation Abuse",
          paragraphs: [
            "You may not use bots, scripts, or bulk workflows to generate spam, manipulate platform behavior, or create abusive traffic.",
            "Automated usage must remain within documented limits and must not degrade service for other users."
          ]
        },
        {
          heading: "3. Scraping, Resale, and Unauthorized Distribution",
          paragraphs: [
            "You may not scrape, harvest, or systematically extract service data, model outputs, or user content without authorization.",
            "You may not resell, sublicense, or white-label access to the service unless expressly permitted in writing."
          ]
        },
        {
          heading: "4. Reverse Engineering and Security Interference",
          paragraphs: [
            "You may not reverse engineer, decompile, disassemble, or attempt to discover source code, model internals, or hidden interfaces, except where mandatory law allows such actions.",
            "You may not probe, scan, or test the platform for vulnerabilities without prior written permission."
          ]
        },
        {
          heading: "5. Rate-Limit and Access Controls",
          paragraphs: [
            "You may not bypass rate limits, quota systems, authentication controls, or plan restrictions.",
            "Attempts to circumvent account, billing, or entitlement controls are treated as misuse."
          ]
        },
        {
          heading: "6. Enforcement",
          paragraphs: [
            "If we detect misuse, we may throttle requests, suspend capabilities, or terminate accounts based on severity and recurrence.",
            "We may preserve relevant technical evidence for security, fraud prevention, and legal compliance."
          ],
          bullets: [
            "Warnings or temporary restrictions for lower-risk first incidents.",
            "Immediate suspension for severe abuse or legal risk.",
            "Permanent termination for repeated or intentional misuse."
          ]
        }
      ]}
      contactNote={
        <p style={{ margin: 0 }}>
          To report abuse or security concerns, contact support@tahsinbayraktar.com.
        </p>
      }
    />
  );
}
