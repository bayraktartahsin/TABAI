import type { Metadata } from "next";
import LegalDocumentPage from "@/components/legal/LegalDocumentPage";

export const metadata: Metadata = {
  title: "Help and Support | TABAI AI Assistant",
  description: "Help and Support information for TABAI AI Assistant by TABA TASARIM İNŞAAT A.Ş."
};

export default function SupportPage() {
  return (
    <LegalDocumentPage
      title="Help & Support"
      intro="Need help with billing, account access, or technical issues in TABAI AI Assistant? This page explains how to reach support and what to include for faster resolution."
      lastUpdated="March 18, 2026"
      sections={[
        {
          heading: "1. Contact",
          paragraphs: [
            "Primary support contact: support@tahsinbayraktar.com.",
            "Please include your account email and a short description of the issue.",
            "Mailing address: TABA TASARIM İNŞAAT A.Ş., Şehit Şakir Elkovan cad. No:3 Ataşehir Istanbul Türkiye."
          ]
        },
        {
          heading: "2. Billing Help",
          paragraphs: [
            "For subscription or charge questions, include platform details (Web, Apple, or Google), purchase date, and any receipt reference.",
            "If your renewal or entitlement appears incorrect, mention the exact plan and where you purchased it."
          ]
        },
        {
          heading: "3. Account Help",
          paragraphs: [
            "If you cannot sign in, share the email you used and the error message shown.",
            "For account security concerns, mark your request as urgent and include relevant timestamps."
          ]
        },
        {
          heading: "4. Technical Issues",
          paragraphs: [
            "For app or website bugs, include steps to reproduce, expected behavior, actual behavior, and screenshots where possible.",
            "Sharing browser/device details and approximate time of issue helps speed up diagnosis."
          ]
        },
        {
          heading: "5. Response Time",
          paragraphs: [
            "Target first-response time: within 3 business days.",
            "Complex billing, abuse, or security investigations may require additional time."
          ]
        }
      ]}
      contactNote={
        <p style={{ margin: 0 }}>
          For legal notices related to TABAI AI Assistant, send correspondence to
          support@tahsinbayraktar.com with subject line &quot;Legal Notice&quot;.
        </p>
      }
    />
  );
}
