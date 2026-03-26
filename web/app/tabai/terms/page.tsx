import type { Metadata } from "next";
import LegalDocumentPage from "@/components/legal/LegalDocumentPage";

export const metadata: Metadata = {
  title: "Terms of Service | TABAI AI Assistant",
  description: "Terms of Service for TABAI AI Assistant by TABA TASARIM İNŞAAT A.Ş."
};

export default function TermsPage() {
  return (
    <LegalDocumentPage
      title="Terms of Service"
      intro="These Terms of Service govern your use of TABAI AI Assistant. By using the service, you agree to these terms with TABA TASARIM İNŞAAT A.Ş."
      lastUpdated="March 18, 2026"
      sections={[
        {
          heading: "1. Nature of the Service",
          paragraphs: [
            "TABAI AI Assistant is a software service that helps users generate and organize AI-assisted content. Features may change over time as the product evolves.",
            "The service may include integrations with third-party model providers and app platforms."
          ]
        },
        {
          heading: "2. User Responsibility for AI Output",
          paragraphs: [
            "AI-generated content may be incomplete, inaccurate, or unsuitable for your use case. You are responsible for reviewing and validating outputs before relying on them.",
            "You are solely responsible for how you use generated content, including legal, regulatory, business, and safety implications."
          ]
        },
        {
          heading: "3. Prohibited Conduct",
          paragraphs: [
            "You may not use the service for unlawful, abusive, fraudulent, or rights-infringing activity.",
            "Detailed restrictions are described in our Acceptable Use Policy, which forms part of these Terms."
          ]
        },
        {
          heading: "4. Subscriptions and Paid Access",
          paragraphs: [
            "Certain features require a paid plan. Pricing, limits, and feature sets may differ by plan and platform.",
            "Where purchases are made through Apple App Store or Google Play, billing and renewals are managed by those platforms under their own terms."
          ]
        },
        {
          heading: "5. Availability and No Uptime Guarantee",
          paragraphs: [
            "We aim to operate a stable service, but uptime and uninterrupted availability are not guaranteed.",
            "Maintenance, incidents, provider outages, and force majeure events may affect performance or access."
          ]
        },
        {
          heading: "6. Limitation of Liability",
          paragraphs: [
            "To the maximum extent permitted by law, TABA TASARIM İNŞAAT A.Ş. is not liable for indirect, incidental, special, consequential, or punitive damages, or for loss of profits, data, goodwill, or business opportunities.",
            "Our aggregate liability for claims related to the service is limited to the amount you paid for the service during the 12 months preceding the claim, unless a different minimum standard is required by applicable law."
          ]
        },
        {
          heading: "7. Suspension and Termination",
          paragraphs: [
            "We may suspend or terminate access if we reasonably believe your use violates these Terms, the Acceptable Use Policy, or applicable law, or if necessary to protect the service, users, or third parties.",
            "You may stop using the service at any time. Subscription cancellation terms are described on the Subscription & Billing page."
          ]
        },
        {
          heading: "8. Governing Law",
          paragraphs: [
            "These Terms are governed by and construed in accordance with the laws of Türkiye. Any disputes arising from or relating to these Terms or the service shall be subject to the exclusive jurisdiction of the courts of Istanbul, Türkiye."
          ]
        },
        {
          heading: "9. Governing Business Identity",
          paragraphs: [
            "Service operator: TABA TASARIM İNŞAAT A.Ş.",
            "Address: Şehit Şakir Elkovan cad. No:3 Ataşehir Istanbul Türkiye.",
            "Product name: TABAI AI Assistant.",
            "Website: ai.gravitilabs.com."
          ]
        }
      ]}
      contactNote={
        <p style={{ margin: 0 }}>
          Questions about these terms can be sent to support@tahsinbayraktar.com.
        </p>
      }
    />
  );
}
