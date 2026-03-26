import type { OWModel } from "@/lib/owui/client";

export type ModelTier = "free" | "paid" | "unknown";

export type ModelMeta = {
  id: string;
  name: string;
  logo: string;
  tier: ModelTier;
  tags: string[];
  speed: "fast" | "standard";
  vendor?: string;
  verified: boolean;
  verificationStatus: "verified" | "unverified" | "failed";
};

function normalizeVendor(model: OWModel): string {
  const source = model.vendor || model.provider?.name || model.provider?.slug || model.meta?.provider || "AI";
  return source.trim() || "AI";
}

function capabilityTags(model: OWModel): string[] {
  const tags = new Set<string>();
  if (model.supportsTextChat !== false) tags.add("Text");
  for (const capability of model.capabilities ?? []) {
    if (capability === "reasoning") tags.add("Reasoning");
    if (capability === "vision") tags.add("Vision");
    if (capability === "image_generation") tags.add("Image Gen");
    if (capability === "tools") tags.add("Tools");
    if (capability === "streaming") tags.add("Streaming");
  }
  if (model.supportsVision) tags.add("Vision");
  if (model.supportsReasoning) tags.add("Reasoning");
  if (model.supportsImageGeneration) tags.add("Image Gen");
  return Array.from(tags);
}

function inferTier(model: OWModel): ModelTier {
  if (model.pricingTier === "free") return "free";
  if (model.pricingTier === "paid") return "paid";
  const source = `${model.providerModelId ?? ""} ${model.name}`.toLowerCase();
  if (source.includes(":free") || source.includes(" free")) return "free";
  if (source.includes("pro") || source.includes("premium")) return "paid";
  return "unknown";
}

function inferSpeed(model: OWModel): "fast" | "standard" {
  const source = `${model.providerModelId ?? ""} ${model.name}`.toLowerCase();
  if (/mini|nano|flash|haiku|small|3b|4b|8b/.test(source)) return "fast";
  return "standard";
}

export function displayForModel(model: OWModel): ModelMeta {
  const vendor = normalizeVendor(model);
  return {
    id: model.id,
    name: model.displayName ?? model.name ?? model.providerModelId ?? model.id,
    logo: model.logoUrl ?? model.meta?.profile_image_url ?? "/tai-icons/default.svg",
    tier: inferTier(model),
    tags: capabilityTags(model),
    speed: inferSpeed(model),
    vendor,
    verified: model.verified === true,
    verificationStatus: model.verificationStatus ?? "unverified"
  };
}

export function supportsVision(model: OWModel | null): boolean {
  if (!model) return false;
  return !!model.supportsVision || (model.capabilities ?? []).includes("vision");
}

export function supportsImageGeneration(model: OWModel | null): boolean {
  if (!model) return false;
  return !!model.supportsImageGeneration || (model.capabilities ?? []).includes("image_generation");
}

export function supportsTextChat(model: OWModel | null): boolean {
  if (!model) return false;
  return model.supportsTextChat !== false;
}
