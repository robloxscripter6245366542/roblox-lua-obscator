import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const kbFile = path.resolve(__dirname, "..", "knowledge.json");
const exampleFile = path.resolve(__dirname, "..", "knowledge.example.json");

/**
 * The company knowledge base: the answers the agent is allowed to give.
 *
 * Grounding replies in this file is what stops the model inventing fees,
 * settlement times, or policies. If a question isn't covered here, the agent
 * is instructed to escalate rather than guess.
 */
let entries = [];

export function loadKnowledge() {
  const file = fs.existsSync(kbFile) ? kbFile : exampleFile;
  try {
    const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
    entries = Array.isArray(parsed) ? parsed : parsed.entries || [];
    const which = file === kbFile ? "knowledge.json" : "knowledge.example.json (sample data)";
    console.log(`[knowledge] Loaded ${entries.length} entries from ${which}.`);
  } catch (err) {
    console.error("[knowledge] Could not load knowledge base:", err.message);
    entries = [];
  }
  return entries;
}

const STOPWORDS = new Set([
  "the", "a", "an", "is", "are", "do", "does", "can", "i", "you", "we", "my",
  "your", "to", "of", "for", "and", "or", "in", "on", "it", "this", "that",
  "how", "what", "when", "where", "with", "have", "has", "be", "will", "would",
  "there", "any", "me", "please", "hi", "hello",
]);

function tokenize(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/[^\w\s]/g, " ")
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOPWORDS.has(t));
}

/**
 * Score entries by term overlap against the question, tags weighted higher.
 * Deliberately simple — no embeddings, no extra service to run — and good
 * enough to pull the right FAQ for a short customer question.
 */
export function searchKnowledge(query, limit = 4) {
  const terms = tokenize(query);
  if (!terms.length) return [];

  const scored = entries.map((entry) => {
    const haystack = tokenize(`${entry.question} ${entry.answer}`);
    const tags = (entry.tags || []).map((t) => String(t).toLowerCase());

    let score = 0;
    for (const term of terms) {
      if (tags.some((tag) => tag === term || tag.includes(term))) score += 3;
      if (haystack.includes(term)) score += 2;
      else if (haystack.some((h) => h.startsWith(term) || term.startsWith(h))) score += 1;
    }
    return { entry, score };
  });

  return scored
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((s) => ({
      question: s.entry.question,
      answer: s.entry.answer,
      tags: s.entry.tags || [],
      confidence: s.score >= 6 ? "high" : s.score >= 3 ? "medium" : "low",
    }));
}

export function allTopics() {
  const tags = new Set();
  for (const e of entries) for (const t of e.tags || []) tags.add(t);
  return [...tags].sort();
}

export function entryCount() {
  return entries.length;
}

loadKnowledge();
