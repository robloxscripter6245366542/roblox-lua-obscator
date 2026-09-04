#!/usr/bin/env python3
# ============================================================
#  bot.py  --  Discord front-end for the luraph-deobf pipeline
#
#  One slash command, /deobfuscate, takes an uploaded .lua file and runs
#  it through pipeline.py (unpack -> IOC triage -> dynamic constants/
#  behaviour -> disassembly -> lift), then posts back report.md plus the
#  recovered artifacts as attachments.
#
#  This executes arbitrary user-submitted code (the dynamic/lift stages
#  run the sample under a real Luau interpreter). pipeline.py's own
#  sandbox already blocks network access from inside the sample; this
#  file adds the bot-side guardrails: a hard wall-clock timeout per job,
#  a concurrency cap, a per-user cooldown, and an upload size limit.
#  Run this on infrastructure you're comfortable executing untrusted
#  Lua on -- a disposable VM/container, not your main host.
#
#  Setup:
#     pip install -r requirements.txt
#     bash ../dynamic/build_luau.sh   # optional but recommended: enables
#                                      # the dynamic/disasm/lift stages
#     cp .env.example .env  && edit DISCORD_BOT_TOKEN
#     python3 bot.py
# ============================================================

import asyncio
import logging
import os
import re
import shutil
import tempfile
import time
import uuid

import discord
from discord import app_commands
from discord.ext import commands

LURAPH_DEOBF_DIR = os.path.abspath(
    os.environ.get("LURAPH_DEOBF_DIR", os.path.join(os.path.dirname(__file__), ".."))
)
PIPELINE_PY = os.path.join(LURAPH_DEOBF_DIR, "pipeline.py")

MAX_UPLOAD_BYTES = int(os.environ.get("MAX_UPLOAD_BYTES", 3 * 1024 * 1024))       # 3 MB in
MAX_ATTACH_BYTES = int(os.environ.get("MAX_ATTACH_BYTES", 8 * 1024 * 1024))       # 8 MB out/file
JOB_TIMEOUT_SECONDS = int(os.environ.get("JOB_TIMEOUT_SECONDS", 240))
MAX_CONCURRENT_JOBS = int(os.environ.get("MAX_CONCURRENT_JOBS", 2))
COOLDOWN_SECONDS = int(os.environ.get("COOLDOWN_SECONDS", 60))

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s %(message)s")
log = logging.getLogger("luraph-deobf-bot")

_job_semaphore = asyncio.Semaphore(MAX_CONCURRENT_JOBS)

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)


def _human_size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f}{unit}"
        n /= 1024
    return f"{n:.0f}TB"


def _parse_status_table(report_text):
    """Pull the '9. Status' markdown table out of report.md for a quick
    embed summary, so users don't have to open report.md just to see
    pass/fail per stage."""
    m = re.search(r"## 9\. Status\n\n(.+?)(\n\n|\Z)", report_text, re.S)
    if not m:
        return None
    rows = [l for l in m.group(1).splitlines() if l.startswith("|") and "---" not in l]
    return rows[1:] if len(rows) > 1 else None


async def _run_pipeline(sample_path, outdir, luau_path):
    """Run pipeline.py as a subprocess with a hard wall-clock timeout.
    Returns (returncode_or_None_on_timeout, combined_output)."""
    cmd = ["python3", PIPELINE_PY, sample_path, "-o", outdir]
    if luau_path:
        cmd += ["--luau", luau_path]

    proc = await asyncio.create_subprocess_exec(
        *cmd, cwd=LURAPH_DEOBF_DIR,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT,
    )
    try:
        out, _ = await asyncio.wait_for(proc.communicate(), timeout=JOB_TIMEOUT_SECONDS)
        return proc.returncode, out.decode("utf-8", "replace")
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        return None, "(pipeline exceeded the job timeout and was killed)"


def _find_luau():
    for c in (os.path.join(LURAPH_DEOBF_DIR, "dynamic", "luau"),
              os.path.join(LURAPH_DEOBF_DIR, "devirt", "luau"),
              shutil.which("luau")):
        if c and os.path.exists(c):
            return c
    return None


@bot.event
async def on_ready():
    await bot.tree.sync()
    log.info("logged in as %s (id=%s)", bot.user, bot.user.id)
    log.info("pipeline: %s", PIPELINE_PY)
    log.info("luau: %s", _find_luau() or "NOT FOUND -- dynamic/disasm/lift stages will be skipped "
                                          "(run dynamic/build_luau.sh)")


@bot.tree.command(name="deobfuscate", description="Run a Luraph-obfuscated Lua script through the deobfuscation pipeline")
@app_commands.describe(file="The obfuscated .lua file to analyze")
@app_commands.checks.cooldown(1, COOLDOWN_SECONDS, key=lambda i: i.user.id)
async def deobfuscate(interaction: discord.Interaction, file: discord.Attachment):
    if file.size > MAX_UPLOAD_BYTES:
        await interaction.response.send_message(
            f"That file is {_human_size(file.size)}; the limit is {_human_size(MAX_UPLOAD_BYTES)}.",
            ephemeral=True)
        return

    await interaction.response.defer(thinking=True)

    job_id = uuid.uuid4().hex[:8]
    job_dir = tempfile.mkdtemp(prefix=f"luraph-bot-{job_id}-")
    sample_path = os.path.join(job_dir, "sample.lua")
    outdir = os.path.join(job_dir, "out")

    try:
        data = await file.read()
        with open(sample_path, "wb") as f:
            f.write(data)

        if _job_semaphore.locked():
            await interaction.followup.send(
                f"Queued behind {MAX_CONCURRENT_JOBS} other job(s) already running -- this may take a bit.")

        async with _job_semaphore:
            log.info("job %s: analyzing %s (%s) for %s", job_id, file.filename,
                      _human_size(file.size), interaction.user)
            t0 = time.monotonic()
            rc, out = await _run_pipeline(sample_path, outdir, _find_luau())
            elapsed = time.monotonic() - t0
            log.info("job %s: pipeline finished rc=%s in %.1fs", job_id, rc, elapsed)

        report_path = os.path.join(outdir, "report.md")
        if not os.path.exists(report_path):
            await interaction.followup.send(
                f"Pipeline did not produce a report (rc={rc}, {elapsed:.0f}s).\n"
                f"```\n{out[-1500:]}\n```")
            return

        with open(report_path, "r", encoding="utf-8", errors="replace") as f:
            report_text = f.read()

        embed = discord.Embed(
            title="Luraph deobfuscation report",
            description=f"`{file.filename}` -- {elapsed:.0f}s",
            color=discord.Color.blurple(),
        )
        rows = _parse_status_table(report_text)
        if rows:
            embed.add_field(name="Stages", value="\n".join(
                r.strip("|").replace("|", " -- ") for r in rows)[:1024], inline=False)

        files = []
        candidates = [
            ("report.md", report_path),
            ("stage_0.lua (unpacked VM source)", os.path.join(outdir, "peeled", "stage_0.lua")),
            ("lifted.lua (devirtualised, register-level)", os.path.join(outdir, "lifted.lua")),
            ("disasm.txt", os.path.join(outdir, "disasm.txt")),
        ]
        skipped = []
        for label, path in candidates:
            if not os.path.exists(path):
                continue
            size = os.path.getsize(path)
            if size > MAX_ATTACH_BYTES:
                skipped.append(f"{label} ({_human_size(size)}, too large to attach)")
                continue
            files.append(discord.File(path, filename=os.path.basename(path)))
        if skipped:
            embed.add_field(name="Not attached (too large)", value="\n".join(skipped), inline=False)

        await interaction.followup.send(embed=embed, files=files)

    except Exception:
        log.exception("job %s failed", job_id)
        await interaction.followup.send("Something went wrong running the pipeline -- check the bot logs.")
    finally:
        shutil.rmtree(job_dir, ignore_errors=True)


@deobfuscate.error
async def deobfuscate_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    if isinstance(error, app_commands.CommandOnCooldown):
        await interaction.response.send_message(
            f"Slow down -- try again in {error.retry_after:.0f}s.", ephemeral=True)
    else:
        log.exception("command error", exc_info=error)
        if not interaction.response.is_done():
            await interaction.response.send_message("Something went wrong.", ephemeral=True)


def main():
    token = os.environ.get("DISCORD_BOT_TOKEN")
    if not token:
        raise SystemExit("Set DISCORD_BOT_TOKEN (see .env.example)")
    bot.run(token)


if __name__ == "__main__":
    main()
