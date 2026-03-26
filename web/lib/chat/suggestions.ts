import type { ChatMsg } from "@/lib/chats/store";

export type PromptSuggestion = { id: string; text: string };

export const EMPTY_CHAT_SUGGESTIONS: PromptSuggestion[] = [
  { id: "plan-day", text: "Plan my day with three priorities and a time-block schedule." },
  { id: "summarize", text: "Summarize this topic for a beginner, then give practical next steps." },
  { id: "email", text: "Draft a professional email reply with a warm and concise tone." },
  { id: "code-review", text: "Review this code for bugs and performance issues." },
  { id: "travel", text: "Build a 3-day travel itinerary with budget-friendly options." },
  { id: "ideas", text: "Give me 10 startup ideas based on my skills and constraints." }
];

function topicSeed(text: string): string {
  const compact = text.replace(/\s+/g, " ").trim();
  if (!compact) return "this topic";
  return compact.length > 80 ? `${compact.slice(0, 80)}…` : compact;
}

export function followupSuggestions(messages: ChatMsg[]): PromptSuggestion[] {
  const lastAssistant = [...messages].reverse().find((m) => m.role === "assistant")?.content ?? "";
  const lastUser = [...messages].reverse().find((m) => m.role === "user")?.content ?? "";
  const seed = topicSeed(lastAssistant || lastUser);

  return [
    { id: "explain-simple", text: `Explain "${seed}" in simpler terms with one example.` },
    { id: "action-plan", text: `Turn "${seed}" into an actionable checklist.` },
    { id: "compare", text: `Compare two alternatives for "${seed}" with pros/cons.` },
    { id: "risks", text: `What are the key risks or mistakes to avoid for "${seed}"?` }
  ];
}
