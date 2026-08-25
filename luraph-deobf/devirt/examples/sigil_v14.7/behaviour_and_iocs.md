# sample_sigil.lua — recovered behaviour & IOCs (dynamic capture, network-blocked)

Captured by running the sample under a stubbed Luau env (Lune), no network egress.

## Program intent / config (decoded, in the clear)
- HttpGet: https://cdn.jnkie.com/SigilUI.lua       (key-system UI loader)
- Discord: discord.gg/jnkie
- Key file name on disk: Jnkie_key
- Shop: "Get Premium" -> jnkie.com ("Buy", "Instant delivery • 24/7 support")
- Appearance: Title="Sigil", Subtitle="Enter your key to continue",
              KeylessSubtitle="No key required for this build - you're verified."
- Service call: { Provider="Mm", Service="Mm", Identifier="1027906" }

## Loader clear-text (pre-VM)
- https://cdn.jnkie.com/SigilUI.lua
- discord.gg/jnkie
- https://lura.ph/            (Luraph obfuscator vendor)
- https://github.com/sarahsophiesee-bot/SigilUI

## Notes
- No webhook / token / HWID exfil endpoint observed in the executed paths.
- Network was blocked throughout; HttpGet was logged, not performed.
