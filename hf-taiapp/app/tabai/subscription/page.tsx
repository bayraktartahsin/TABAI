import type { Metadata } from "next";
import LegalDocumentPage from "@/components/legal/LegalDocumentPage";

export const metadata: Metadata = {
  title: "Subscription and Billing | TABAI AI Assistant",
  description: "Subscription and Billing terms for TABAI AI Assistant by TABA TASARIM İNŞAAT A.Ş."
};

export default function SubscriptionPage() {
  return (
    <LegalDocumentPage
      title="Subscription & Billing"
      intro="This page explains plan structure, renewals, cancellations, and billing responsibilities for TABAI AI Assistant paid access."
      lastUpdated="March 18, 2026"
      sections={[
        {
          heading: "1. Plans",
          paragraphs: [
            "TABAI AI Assistant currently offers Starter, Pro, and Power plans. Features, quotas, and model access may vary by plan.",
            "Plan names and details are presented in-product and may be updated as we improve the service."
          ],
          bullets: [
            "Starter: entry-level paid access.",
            "Pro: expanded usage and capabilities.",
            "Power: highest tier with advanced access and limits."
          ]
        },
        {
          heading: "2. Billing Cycles",
          paragraphs: [
            "Subscriptions may be available in monthly and yearly billing periods. Pricing shown at checkout controls for your transaction.",
            "Taxes may apply depending on jurisdiction and platform requirements."
          ]
        },
        {
          heading: "3. Auto-Renew and Platform Handling",
          paragraphs: [
            "Where applicable, subscriptions purchased via Apple App Store or Google Play auto-renew unless canceled before renewal.",
            "Renewal terms, payment methods, and billing operations are controlled by the platform through which you subscribed."
          ]
        },
        {
          heading: "4. Cancellations",
          paragraphs: [
            "You can cancel at any time through the same platform used for purchase. Cancellation typically applies to the next renewal cycle.",
            "After cancellation, paid benefits may continue until the current billing period ends, subject to platform rules."
          ]
        },
        {
          heading: "5. Restore and Revalidation",
          paragraphs: [
            "When supported by the client app, restore and entitlement revalidation help confirm your active subscription status.",
            "Temporary platform, network, or account issues may delay entitlement refresh until validation succeeds."
          ]
        },
        {
          heading: "6. Refunds",
          paragraphs: [
            "Refund eligibility is determined by the platform or payment processor that handled your purchase.",
            "For Apple or Google purchases, refund requests must follow the applicable platform policy."
          ]
        },
        {
          heading: "7. Plan and Feature Changes",
          paragraphs: [
            "We may modify plan names, price points, feature sets, usage limits, or availability over time.",
            "Changes may vary by geography, platform, legal requirements, and technical constraints."
          ]
        }
      ]}
      contactNote={
        <p style={{ margin: 0 }}>
          For billing support, contact support@tahsinbayraktar.com and include your platform
          (Web, Apple, or Google) plus purchase receipt metadata where available.
        </p>
      }
    />
  );
}
