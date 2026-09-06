import { exec } from "node:child_process";
import { promisify } from "node:util";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import type Anthropic from "@anthropic-ai/sdk";

const pexec = promisify(exec);

export interface ToolContext {
  /** Absolute path used as the working directory / root for relative paths. */
  root: string;
  bashTimeoutMs: number;
  /** Called with a short human-readable line describing each tool call. */
  onActivity?: (line: string) => void;
}

// Tool definitions sent to Claude. Custom tools with explicit schemas.
export const TOOL_DEFS: Anthropic.Tool[] = [
  {
    name: "bash",
    description:
      "Run a shell command in the workspace root and return its combined stdout and stderr. " +
      "Use for building, testing, git, installing deps, searching, and any task a terminal can do.",
    input_schema: {
      type: "object",
      properties: { command: { type: "string", description: "The shell command to run." } },
      required: ["command"],
      additionalProperties: false,
    },
  },
  {
    name: "read_file",
    description: "Read a UTF-8 text file. Path is relative to the workspace root (or absolute).",
    input_schema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
      additionalProperties: false,
    },
  },
  {
    name: "write_file",
    description: "Create or overwrite a UTF-8 text file with the given content. Creates parent dirs.",
    input_schema: {
      type: "object",
      properties: { path: { type: "string" }, content: { type: "string" } },
      required: ["path", "content"],
      additionalProperties: false,
    },
  },
  {
    name: "list_dir",
    description: "List the entries of a directory (relative to the workspace root, or absolute).",
    input_schema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"],
      additionalProperties: false,
    },
  },
];

function resolveIn(root: string, p: string): string {
  return path.isAbsolute(p) ? p : path.join(root, p);
}

const MAX_OUTPUT = 60_000; // cap tool output so we don't blow the context window
function cap(s: string): string {
  if (s.length <= MAX_OUTPUT) return s;
  return s.slice(0, MAX_OUTPUT) + `\n…[truncated ${s.length - MAX_OUTPUT} chars]`;
}

/** Execute one tool call and return a string result (never throws). */
export async function runTool(
  name: string,
  input: any,
  ctx: ToolContext,
): Promise<string> {
  try {
    switch (name) {
      case "bash": {
        const command = String(input?.command ?? "");
        ctx.onActivity?.(`$ ${command}`);
        try {
          const { stdout, stderr } = await pexec(command, {
            cwd: ctx.root,
            timeout: ctx.bashTimeoutMs,
            maxBuffer: 10 * 1024 * 1024,
            windowsHide: true,
          });
          return cap((stdout || "") + (stderr ? `\n[stderr]\n${stderr}` : "")) || "(no output)";
        } catch (e: any) {
          // exec rejects on non-zero exit; still return the captured output.
          const out = (e?.stdout || "") + (e?.stderr ? `\n[stderr]\n${e.stderr}` : "");
          return cap(`exit ${e?.code ?? "?"}\n${out}`.trim()) || `error: ${e?.message}`;
        }
      }
      case "read_file": {
        const fp = resolveIn(ctx.root, String(input?.path ?? ""));
        ctx.onActivity?.(`read ${input?.path}`);
        return cap(await fs.readFile(fp, "utf8"));
      }
      case "write_file": {
        const fp = resolveIn(ctx.root, String(input?.path ?? ""));
        ctx.onActivity?.(`write ${input?.path}`);
        await fs.mkdir(path.dirname(fp), { recursive: true });
        await fs.writeFile(fp, String(input?.content ?? ""), "utf8");
        return `Wrote ${String(input?.content ?? "").length} bytes to ${input?.path}`;
      }
      case "list_dir": {
        const dp = resolveIn(ctx.root, String(input?.path ?? "."));
        ctx.onActivity?.(`ls ${input?.path ?? "."}`);
        const entries = await fs.readdir(dp, { withFileTypes: true });
        return entries.map((e) => (e.isDirectory() ? `${e.name}/` : e.name)).join("\n") || "(empty)";
      }
      default:
        return `error: unknown tool "${name}"`;
    }
  } catch (e: any) {
    return `error: ${e?.message ?? e}`;
  }
}
