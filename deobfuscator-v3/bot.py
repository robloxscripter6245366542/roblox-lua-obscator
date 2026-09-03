import aiohttp
import asyncio
import os
import re
import subprocess
import sys
import time
import pathlib
from datetime import datetime

import aiohttp
import discord

import router

# ------------------------------------------------------------------ config from .env
ROOT = pathlib.Path(__file__).resolve().parent
ENV  = ROOT / ".env"

def _env(key: str, default: str = "") -> str:
    if ENV.is_file():
        for line in ENV.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                if k.strip() == key:
                    return v.strip()
    return os.environ.get(key, default)

TOKEN      = _env("DISCORD_TOKEN", "ur bot token")
# Configure the channel explicitly in .env; do not embed a real channel ID in source.
CHANNEL_ID = int(_env("CHANNEL_ID", "0"))
PREFIX     = _env("PREFIX", ".l")
TIMEOUT    = int(_env("TIMEOUT", "100"))
MAX_DL     = int(_env("MAX_DL", str(8 * 1024 * 1024)))

_default_lute = "lute.exe" if sys.platform == "win32" else "lute"
LUTE = ROOT / _env("HOOKOP_BIN", _default_lute)
TMP  = ROOT / "bot_tmp"
TMP.mkdir(exist_ok=True)

ACCENT  = 0x5865F2
GOOD    = 0x57F287
BAD     = 0xED4245
WARN    = 0xFEE75C

URL_RE  = re.compile(r"https?://[^\s<>()]+", re.I)
OK_EXT  = (".lua", ".txt")

ENGINE_LABEL = {"envlog": "env logger", "prom": "prometheus"}

# .l always uses the original env logger; .d prompts, .prom/.envlog force one.
CMD_ENGINE = {PREFIX: "envlog", ".prom": "prom", ".envlog": "envlog"}

# many script hosts 403 the default aiohttp UA — look like a browser
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
      "AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/124.0 Safari/537.36")

def _raw_url(url: str) -> str:
    """Turn common share links into their raw/plaintext form."""
    # github.com/u/r/blob/... -> raw.githubusercontent.com/u/r/...
    m = re.match(r"https?://github\.com/([^/]+/[^/]+)/blob/(.+)", url, re.I)
    if m:
        return f"https://raw.githubusercontent.com/{m.group(1)}/{m.group(2)}"
    # pastebin.com/xxxx -> pastebin.com/raw/xxxx
    m = re.match(r"https?://pastebin\.com/(?!raw/)([A-Za-z0-9]+)$", url, re.I)
    if m:
        return f"https://pastebin.com/raw/{m.group(1)}"
    # pastes.dev/xxxx -> api.pastes.dev/xxxx (the site is an SPA)
    m = re.match(r"https?://pastes\.dev/([A-Za-z0-9]+)$", url, re.I)
    if m:
        return f"https://api.pastes.dev/{m.group(1)}"
    return url

# ------------------------------------------------------------------ engine
def _dump_blocking(in_path: pathlib.Path, out_path: pathlib.Path, engine=None):
    """Route to the right engine. Returns (ok, reason, took, engine)."""
    return router.run(in_path, out_path, engine=engine,
                      timeout=TIMEOUT, lute_bin=LUTE)

# ------------------------------------------------------------------ bot
intents = discord.Intents.default()
intents.message_content = True
bot = discord.Client(intents=intents)
queue: "asyncio.Queue[dict]" = asyncio.Queue()
http: aiohttp.ClientSession | None = None


async def react(msg, emoji):
    try: await msg.add_reaction(emoji)
    except discord.HTTPException: pass

async def unreact(msg, emoji):
    try: await msg.remove_reaction(emoji, bot.user)
    except discord.HTTPException: pass


async def safe_reply(msg, *args, **kwargs):
    """Reply, falling back to a plain channel send if the message was deleted."""
    mention_author = kwargs.pop("mention_author", False)
    try:
        return await msg.reply(*args, mention_author=mention_author, **kwargs)
    except discord.HTTPException as ex:
        if ex.code not in (50035, 10008):
            raise
    for f in kwargs.get("files", []) or ([kwargs["file"]] if kwargs.get("file") else []):
        try: f.reset()
        except Exception: pass
    return await msg.channel.send(*args, **kwargs)


async def gather_jobs(message) -> list[dict]:
    """Pull every dumpable script out of a message (and the one it replies to)."""
    sources = [message]
    if message.reference and message.reference.resolved:
        sources.append(message.reference.resolved)

    jobs, seen = [], set()
    for src in sources:
        for att in getattr(src, "attachments", []):
            if att.filename.lower().endswith(OK_EXT) and att.id not in seen:
                seen.add(att.id)
                jobs.append({"name": att.filename, "att": att, "url": None})

        text = getattr(src, "content", "") or ""
        for url in URL_RE.findall(text):
            url = url.rstrip(".,)`'\"")
            if url in CMD_ENGINE or url in seen:
                continue
            seen.add(url)
            name = url.split("?")[0].rstrip("/").split("/")[-1] or "script"
            if not name.lower().endswith(OK_EXT):
                name += ".lua"
            jobs.append({"name": name, "att": None, "url": url})
    return jobs


async def fetch_source(job) -> str:
    if job["att"] is not None:
        return (await job["att"].read()).decode("utf-8", "ignore")
    url = _raw_url(job["url"])
    headers = {"User-Agent": UA, "Accept": "*/*"}
    async with http.get(url, headers=headers,
                        timeout=aiohttp.ClientTimeout(total=30)) as r:
        r.raise_for_status()
        ctype = r.headers.get("Content-Type", "").lower()
        if "text/html" in ctype:
            raise ValueError("got an HTML page, not a raw script — use a raw link")
        chunks, total = [], 0
        async for part in r.content.iter_chunked(65536):
            total += len(part)
            if total > MAX_DL:
                raise ValueError("file too large")
            chunks.append(part)
        body = b"".join(chunks).decode("utf-8", "ignore")
        if body.lstrip()[:1] == "<":
            raise ValueError("got an HTML page, not a raw script — use a raw link")
        return body


async def worker():
    await bot.wait_until_ready()
    while True:
        job = await queue.get()
        message, name = job["message"], job["name"]
        stamp = f"{int(time.time()*1000)}_{os.getpid()}"
        in_rel  = f"bot_tmp/{stamp}.lua"
        out_rel = f"bot_tmp/{stamp}_out.lua"
        in_path, out_path = ROOT / in_rel, ROOT / out_rel

        await unreact(message, "🕓")
        await react(message, "⏳")
        try:
            src = await fetch_source(job)
            in_path.write_text(src, encoding="utf-8", errors="ignore")

            ok, reason, took, used = await asyncio.to_thread(
                _dump_blocking, in_path, out_path, job.get("engine"))

            if ok:
                data = out_path.read_text(errors="ignore")
                lines = data.count("\n") + 1
                e = discord.Embed(color=GOOD, timestamp=datetime.now())
                e.description = (
                    f"**`{name}`**\n"
                    f"`{ENGINE_LABEL[used]}` · `{lines:,} lines` · "
                    f"`{len(data)/1024:.1f} KB` · `{took:.2f}s`"
                )
                e.set_footer(text="Crock")
                out_name = re.sub(r"\.(lua|txt)$", "", name, flags=re.I) + ".dump.lua"
                with open(out_path, "rb") as fh:
                    await safe_reply(
                        message,
                        content=message.author.mention,
                        embed=e,
                        file=discord.File(fh, filename=out_name),
                        mention_author=True,
                    )
                await unreact(message, "⏳")
                await react(message, "✅")
            else:
                label = f"skipped — took over {TIMEOUT}s" if reason == "timeout" else reason
                e = discord.Embed(color=WARN if reason == "timeout" else BAD,
                                  timestamp=datetime.now())
                e.description = f"**`{name}`**\n{label}"
                e.set_footer(text="Crock")
                await safe_reply(message, content=message.author.mention, embed=e,
                                 mention_author=True)
                await unreact(message, "⏳")
                await react(message, "⏱️" if reason == "timeout" else "❌")

        except Exception as ex:
            e = discord.Embed(color=BAD, timestamp=datetime.now())
            e.description = f"**`{name}`**\ncouldn't grab that — {ex}"
            e.set_footer(text="Crock")
            try:
                await safe_reply(message, content=message.author.mention, embed=e,
                                 mention_author=True)
            except discord.HTTPException:
                pass
            await unreact(message, "⏳")
            await react(message, "❌")
        finally:
            for p in (in_path, out_path):
                try: p.unlink()
                except OSError: pass
            queue.task_done()


@bot.event
async def on_ready():
    global http
    if http is None:
        http = aiohttp.ClientSession()
    bot.loop.create_task(worker())
    await bot.change_presence(activity=discord.Activity(
        type=discord.ActivityType.watching, name=f"{PREFIX} · dumps"))
    print(f"online as {bot.user} · channel {CHANNEL_ID}")


async def enqueue(message, jobs, engine):
    """Queue jobs against a given engine (None = auto-detect)."""
    await react(message, "🕓")
    pos = queue.qsize()
    for j in jobs:
        j["message"] = message
        j["engine"] = engine
        await queue.put(j)
    if pos or len(jobs) > 1:
        note = f"queued `{len(jobs)}` · `{pos}` ahead" if pos else f"queued `{len(jobs)}`"
        try:
            await safe_reply(message, note, delete_after=6)
        except discord.HTTPException:
            pass


class EnginePicker(discord.ui.View):
    """Buttons shown by .d so the user picks the engine themselves."""

    def __init__(self, message, jobs):
        super().__init__(timeout=60)
        self.message = message
        self.jobs = jobs
        self.prompt = None

    async def interaction_check(self, interaction) -> bool:
        if interaction.user.id != self.message.author.id:
            await interaction.response.send_message(
                "that's not your script.", ephemeral=True)
            return False
        return True

    async def on_timeout(self):
        if self.prompt:
            try:
                await self.prompt.delete()
            except discord.HTTPException:
                pass

    async def _pick(self, interaction, engine):
        for child in self.children:
            child.disabled = True
        self.stop()

        label = "auto-detect" if engine is None else ENGINE_LABEL[engine]
        e = discord.Embed(color=ACCENT, description=f"running **{label}**...")
        e.set_footer(text="Crock")
        try:
            await interaction.response.edit_message(embed=e, view=None)
        except discord.HTTPException:
            pass

        await enqueue(self.message, self.jobs, engine)

    @discord.ui.button(label="auto-detect", style=discord.ButtonStyle.primary)
    async def auto(self, interaction, button):
        await self._pick(interaction, None)

    @discord.ui.button(label="prometheus", style=discord.ButtonStyle.secondary)
    async def prom(self, interaction, button):
        await self._pick(interaction, "prom")

    @discord.ui.button(label="env logger", style=discord.ButtonStyle.secondary)
    async def envlog(self, interaction, button):
        await self._pick(interaction, "envlog")


@bot.event
async def on_message(message):
    if message.author.bot or message.channel.id != CHANNEL_ID:
        return

    content = message.content.strip()

    # -- .help command --
    if content == ".help":
        e = discord.Embed(color=ACCENT, timestamp=datetime.now())
        e.title = "ky6r thing"
        e.description = (
            "hosted by me made by @6vf0\n\n"
            "**Commands:**\n"
            f"`{PREFIX}` + attach `.lua`/`.txt` — dump a script (env logger)\n"
            f"`{PREFIX} <raw-url>` — dump from a link\n"
            f"`{PREFIX}` (reply to script) — dump the replied script\n"
            "`.d` — pick the deobfuscator from a menu\n"
            "`.prom` — force the Prometheus deobfuscator\n"
            "`.envlog` — force the Luau env logger\n"
            "`.help` — show this message\n"
            "`.cfg` — show current env logger settings\n\n"
        )
        e.set_footer(text="Crock · hosted by me made by @6vf0")
        await safe_reply(message, embed=e)
        return

    # -- .cfg command --
    if content == ".cfg":
        e = discord.Embed(color=ACCENT, timestamp=datetime.now())
        e.title = "Env Logger Settings"
        e.description = (
            "**General**\n"
            "`output` → `out.lua`\n"
            "`debug` → `false`\n"
            "`prod` → `false`\n\n"
            "**Features**\n"
            "`hookOp` → `true`\n"
            "`explore_funcs` → `true`\n"
            "`minifier` → `true`\n"
            "`inf_loops` → `true`\n"
            "`discord` → `true`\n"
            "`constants` → `false`\n"
            "`type_annotations` → `false`\n\n"
            "**Limits**\n"
            "`while_limit` → `1,500,000`\n\n"
            "Pass settings as extra args: `.l script.lua debug hookOp=false`"
        )
        e.set_footer(text="Crock · hosted by me made by @6vf0")
        await safe_reply(message, embed=e)
        return

    cmd = content.split(None, 1)[0].lower() if content else ""

    # -- .d command: pick the engine from a menu --
    if cmd == ".d":
        jobs = await gather_jobs(message)
        if not jobs:
            e = discord.Embed(color=ACCENT, description=(
                "attach a `.lua`/`.txt`, drop a raw link, or reply to one with `.d`."
            ))
            e.set_footer(text="Crock")
            await safe_reply(message, embed=e)
            return

        names = ", ".join(f"`{j['name']}`" for j in jobs[:3])
        if len(jobs) > 3:
            names += f" +{len(jobs) - 3} more"
        e = discord.Embed(color=ACCENT, timestamp=datetime.now())
        e.title = "pick a deobfuscator"
        e.description = f"{names}\n\nchoose which engine to run:"
        e.set_footer(text="Crock · only you can pick · times out in 60s")

        view = EnginePicker(message, jobs)
        view.prompt = await safe_reply(message, embed=e, view=view)
        return

    if cmd not in CMD_ENGINE:
        return
    engine = CMD_ENGINE[cmd]

    jobs = await gather_jobs(message)
    if not jobs:
        e = discord.Embed(color=ACCENT, description=(
            f"attach a `.lua`/`.txt`, drop a raw link, or reply to one with `{cmd}`."
        ))
        e.set_footer(text="Crock")
        await safe_reply(message, embed=e)
        return

    await enqueue(message, jobs, engine)


BANNER = r"""
  _____                _    ____
 / ____|              | |  / __ \
| |     _ __ ___  __ _| | | |  | |_ __ ___   __ _ _ __
| |    | '__/ _ \/ _` | | | |  | | '_ ` _ \ / _` | '_ \
| |____| | |  __/ (_| | | | |__| | | | | | | (_| | |_) |
 \_____|_|  \___|\__,_|_|  \____/|_| |_| |_|\__,_| .__/
                                                 | |
                                                 |_|
  hosted by me made by @6vf0
"""


def run_bot_forever():
    """Run the bot, restarting it if it crashes."""
    import traceback
    while True:
        print(f"[{datetime.now():%H:%M:%S}] starting bot...")
        try:
            bot.run(TOKEN)
        except KeyboardInterrupt:
            print("\nstopped.")
            return
        except Exception:
            traceback.print_exc()
        print(f"[{datetime.now():%H:%M:%S}] bot stopped, restarting in 5s...")
        try:
            time.sleep(5)
        except KeyboardInterrupt:
            print("\nstopped.")
            return


def cli_dump():
    inp = input(" input file (.lua): ").strip().strip('"')
    if not inp:
        print("no input file.")
        return
    in_path = pathlib.Path(inp).resolve()
    if not in_path.is_file():
        print(f"no such file: {in_path}")
        return

    out = input(" output file [out.lua]: ").strip().strip('"') or "out.lua"
    out_path = pathlib.Path(out).resolve()

    eng = input(" force engine (prom/envlog, blank = auto): ").strip().lower()
    engine = eng if eng in ("prom", "envlog") else None

    print("\nprocessing...")
    ok, reason, took, used = router.run(in_path, out_path, engine=engine,
                                        timeout=TIMEOUT, lute_bin=LUTE)
    if ok:
        print(f"[{used}] done in {took:.2f}s -> {out_path}")
    else:
        print(f"[{used}] failed after {took:.2f}s: {reason}")


def cli_obfuscate():
    inp = input(" input file (.lua): ").strip().strip('"')
    if not inp:
        print("no input file.")
        return
    in_path = pathlib.Path(inp).resolve()
    if not in_path.is_file():
        print(f"no such file: {in_path}")
        return

    preset = input(" preset (weak/medium/strong/encrypt/yap) [medium]: ").strip() or "medium"
    subprocess.run(["node", "obf.js", preset, str(in_path)],
                   cwd=str(ROOT / "v1sexy"))


def menu():
    while True:
        print(BANNER)
        print("  [1] dump a script (auto-detects engine)")
        print("  [2] run discord bot (auto-restart on crash)")
        print("  [3] obfuscate a script (prometheus)")
        print("  [4] exit\n")
        try:
            choice = input(" select option [1-4]: ").strip()
        except (EOFError, KeyboardInterrupt):
            return

        print()
        if choice == "1":
            cli_dump()
        elif choice == "2":
            run_bot_forever()
            return
        elif choice == "3":
            cli_obfuscate()
        elif choice == "4":
            return
        else:
            print("invalid option.")

        input("\n press enter to continue...")


if __name__ == "__main__":
    # `python bot.py bot` skips the menu (used by Docker).
    if len(sys.argv) > 1 and sys.argv[1] == "bot":
        bot.run(TOKEN)
    else:
        menu()