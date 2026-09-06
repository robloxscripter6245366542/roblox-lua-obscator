import Anthropic from "@anthropic-ai/sdk";
import { TOOL_DEFS, runTool, type ToolContext } from "./tools";

const SYSTEM =
  "You are Nova Agent, a coding assistant running inside the user's VS Code workspace. " +
  "You can run shell commands and read/write files with the provided tools. " +
  "Work in small, verified steps: inspect before you edit, run tests or builds after changes, " +
  "and report what you did concisely. Never run destructive commands without a clear reason.";

export interface AgentEvents {
  onText: (delta: string) => void;      // streamed assistant text
  onActivity: (line: string) => void;   // tool call line
  onTurnEnd: () => void;
  onError: (message: string) => void;
  onConnectionChange: (connected: boolean) => void;
}

/**
 * Owns the Anthropic client and conversation. The client is created lazily on
 * the first message and torn down after `idleMs` of inactivity (or on dispose)
 * — so the extension holds a connection to Claude only while it is in use.
 */
export class Agent {
  private client: Anthropic | null = null;
  private messages: Anthropic.MessageParam[] = [];
  private idleTimer: ReturnType<typeof setTimeout> | null = null;
  private busy = false;

  private model: string;
  private baseURL?: string;

  constructor(
    private getApiKey: () => Promise<string | undefined>,
    private ctx: ToolContext,
    private events: AgentEvents,
    private opts: { model: string; idleMs: number; baseURL?: string },
  ) {
    this.model = opts.model;
    this.baseURL = opts.baseURL;
  }

  get connected(): boolean {
    return this.client !== null;
  }

  /** Switch the model for the next turn (from the sidebar picker). */
  setModel(model: string): void {
    this.model = model;
  }

  /** Point at a different endpoint (any Anthropic-compatible base URL). */
  setBaseUrl(url: string | undefined): void {
    const clean = url && url.trim() ? url.trim() : undefined;
    if (clean !== this.baseURL) {
      this.baseURL = clean;
      this.disconnect(); // force a fresh client on next send
    }
  }

  private async ensureClient(): Promise<Anthropic | null> {
    if (this.client) return this.client;
    const apiKey = await this.getApiKey();
    if (!apiKey) {
      this.events.onError("No API key set. Run “Nova Agent: Set Anthropic API Key”.");
      return null;
    }
    this.client = new Anthropic(this.baseURL ? { apiKey, baseURL: this.baseURL } : { apiKey });
    this.events.onConnectionChange(true);
    return this.client;
  }

  /** Tear down the connection (idle, manual, or on dispose). */
  disconnect(): void {
    if (this.idleTimer) {
      clearTimeout(this.idleTimer);
      this.idleTimer = null;
    }
    if (this.client) {
      this.client = null;
      this.events.onConnectionChange(false);
    }
  }

  private touch(): void {
    if (this.idleTimer) clearTimeout(this.idleTimer);
    if (this.opts.idleMs > 0) {
      this.idleTimer = setTimeout(() => {
        if (!this.busy) this.disconnect();
      }, this.opts.idleMs);
    }
  }

  reset(): void {
    this.messages = [];
  }

  /** Run one user turn to completion, looping over tool calls. */
  async send(userText: string): Promise<void> {
    if (this.busy) {
      this.events.onError("Still working on the previous message…");
      return;
    }
    const client = await this.ensureClient();
    if (!client) return;

    this.busy = true;
    this.touch();
    this.messages.push({ role: "user", content: userText });

    try {
      // Loop until the model stops asking for tools.
      // A generous cap prevents a runaway loop.
      for (let step = 0; step < 50; step++) {
        const stream = client.messages.stream({
          model: this.model,
          max_tokens: 64000,
          // Opus 5 runs adaptive thinking by default when `thinking` is omitted.
          system: SYSTEM,
          tools: TOOL_DEFS,
          messages: this.messages,
        });
        stream.on("text", (delta) => this.events.onText(delta));

        const final = await stream.finalMessage();
        // Echo the full content (incl. thinking + tool_use blocks) back verbatim.
        this.messages.push({
          role: "assistant",
          content: final.content as unknown as Anthropic.ContentBlockParam[],
        });

        if (final.stop_reason === "refusal") {
          this.events.onError("Claude declined this request.");
          break;
        }
        if (final.stop_reason !== "tool_use") {
          break;
        }

        // Execute every tool_use block, return all results in one user message.
        const results: Anthropic.ToolResultBlockParam[] = [];
        for (const block of final.content) {
          if (block.type === "tool_use") {
            const out = await runTool(block.name, block.input, this.ctx);
            results.push({ type: "tool_result", tool_use_id: block.id, content: out });
          }
        }
        this.messages.push({ role: "user", content: results });
      }
    } catch (e: any) {
      if (e instanceof Anthropic.AuthenticationError) {
        this.events.onError("Invalid API key.");
        this.disconnect();
      } else if (e instanceof Anthropic.RateLimitError) {
        this.events.onError("Rate limited — try again shortly.");
      } else if (e instanceof Anthropic.APIError) {
        this.events.onError(`API error ${e.status}: ${e.message}`);
      } else {
        this.events.onError(`Error: ${e?.message ?? e}`);
      }
    } finally {
      this.busy = false;
      this.touch();
      this.events.onTurnEnd();
    }
  }

  dispose(): void {
    this.disconnect();
  }
}
