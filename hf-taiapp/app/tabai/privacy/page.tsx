import type { Metadata } from "next";
import LegalDocumentPage from "@/components/legal/LegalDocumentPage";

export const metadata: Metadata = {
  title: "Privacy Policy | TABAI AI Assistant",
  description: "Privacy Policy for TABAI AI Assistant by TABA TASARIM İNŞAAT A.Ş."
};

export default function PrivacyPage() {
  return (
    <LegalDocumentPage
      title="Privacy Policy"
      intro="This Privacy Policy explains how TABA TASARIM İNŞAAT A.Ş. collects, uses, and protects personal data when you use TABAI AI Assistant and related services at gravitilabs.com."
      lastUpdated="March 24, 2026"
      sections={[
        {
          heading: "1. Data We Collect",
          paragraphs: [
            "We collect account and profile information you provide, including email address, account credentials, and settings preferences.",
            "When you use TABAI AI Assistant, we process prompts, model selections, generated responses, and interaction metadata needed to provide the service."
          ],
          bullets: [
            "Account data: email, authentication identifiers, security preferences, subscription status.",
            "AI interaction data: prompts, attachments you submit, model outputs, timestamps, and diagnostic request identifiers.",
            "Usage and diagnostics: device/browser data, performance logs, crash details, and basic analytics events."
          ]
        },
        {
          heading: "2. Third-Party AI Service Providers",
          paragraphs: [
            "When you send a message in TABAI, your prompt text and conversation context are transmitted to third-party AI model providers for processing. These include OpenAI (GPT), Anthropic (Claude), Google (Gemini), Meta (Llama), Mistral, DeepSeek, and others accessed through our infrastructure.",
            "We do not share your email, name, or payment data with AI providers — only message content needed to generate responses. By using TABAI you consent to this as described in the in-app AI Data Sharing Notice."
          ]
        },
        {
          heading: "3. How We Use Data",
          paragraphs: [
            "We use personal data to operate the service, authenticate users, deliver AI responses, prevent abuse, support subscriptions, and improve reliability.",
            "We may use aggregated and de-identified usage signals to improve product quality and capacity planning."
          ]
        },
        {
          heading: "4. Third-Party Processors",
          paragraphs: [
            "We use third-party providers to deliver key platform functions. These providers process data according to their own policies and our contractual controls.",
            "AI model providers may receive prompts and related context needed to generate responses. Payment processors and app platforms may process billing and entitlement data."
          ],
          bullets: [
            "AI inference and model infrastructure providers.",
            "Subscription and billing processors, including Apple App Store and Google Play where applicable.",
            "Infrastructure, monitoring, and error-reporting services used to keep the product stable and secure."
          ]
        },
        {
          heading: "5. Data Retention",
          paragraphs: [
            "We retain data for as long as reasonably necessary to provide the service, meet legal obligations, resolve disputes, and enforce agreements.",
            "Retention periods vary by data category. Security and audit records may be retained longer when required for fraud prevention or compliance."
          ]
        },
        {
          heading: "6. Account Deletion and Contact",
          paragraphs: [
            "You may request account deletion or data access/correction through support. Deletion requests are handled in a commercially reasonable timeframe, subject to lawful retention requirements.",
            "For privacy requests, contact: support@tahsinbayraktar.com",
            "Data controller: TABA TASARIM İNŞAAT A.Ş., Şehit Şakir Elkovan cad. No:3 Ataşehir Istanbul Türkiye."
          ]
        },
        {
          heading: "7. Security",
          paragraphs: [
            "We use administrative, technical, and organizational safeguards designed to protect personal data. No method of transmission or storage is completely secure, and we cannot guarantee absolute security.",
            "You are responsible for keeping account credentials confidential and notifying us promptly of suspected unauthorized access."
          ]
        },
        {
          heading: "8. Changes to This Policy",
          paragraphs: [
            "We may update this Privacy Policy as the service evolves or legal requirements change. The updated version will be posted on this page with a revised effective date.",
            "Continued use of the service after updates means you acknowledge the revised policy."
          ]
        },
        {
          heading: "9. Governing Law",
          paragraphs: [
            "This Privacy Policy is governed by the laws of Türkiye. For questions about data protection, contact support@tahsinbayraktar.com."
          ]
        }
      ]}
      contactNote={
        <p style={{ margin: 0 }}>
          If you need a signed data-processing agreement or enterprise privacy documentation,
          contact support@tahsinbayraktar.com.
        </p>
      }
    />
  );
}
