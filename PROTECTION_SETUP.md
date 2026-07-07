# Anime Ball Hub — key + HWID protection

This gates your script behind **per-user keys locked to a device (HWID)**. People
without a valid key can't load it, and a leaked key only works on the one machine
it bound to.

**Honest limit:** no client-side Roblox script is uncopyable — an *authorized*
user can still dump it from memory. This stops unauthorized access and casual
copy-paste, not a determined dumper. Combine it with obfuscation for the best result.

## Pieces

| File | Where it lives | Role |
|------|----------------|------|
| `user_scripts/animeball_loader.lua` | **public** (share this) | reads key + HWID, calls the authenticator, runs what it returns |
| `api/animeballhub.js` | **public code, secret config** | validates key + HWID lock, returns the protected script |
| your real script (obfuscated) | **private** (gist/repo) | the actual code — never at a public URL |

## One-time setup

### 1. Move the real script out of public view
- Run your obfuscator on the real script:
  put the source in `Full_Combined_source.lua` and run `lua obfuscate.lua`
  (or point it at `user_scripts/anime_ball_autoparry.lua`).
- Put the **obfuscated** output in a **private** place the server can fetch:
  - a **secret GitHub gist** (raw URL), or
  - a **private repo** raw URL (needs a token).
- **Delete the public copy** (`user_scripts/anime_ball_autoparry.lua`) once the
  loader works — while it's on the public raw URL it's fully copyable.

### 2. Set Vercel environment variables
Project → Settings → Environment Variables:

| Var | Value |
|-----|-------|
| `ANIMEBALL_KEYS` | JSON of valid keys (below) |
| `PROTECTED_SCRIPT_URL` | raw URL of your private obfuscated script |
| `PROTECTED_SCRIPT_TOKEN` | *(only if the private URL needs auth)* a token |
| `UPSTASH_REDIS_REST_URL` | *(optional)* enables auto-lock on first use |
| `UPSTASH_REDIS_REST_TOKEN` | *(optional)* token for the above |

`ANIMEBALL_KEYS` format:
```json
{
  "ABC-123-XYZ": { "hwid": "", "expires": 0, "note": "buyer1" },
  "DEF-456-QRS": { "hwid": "SPECIFIC-HWID-STRING", "expires": 1767225600, "note": "buyer2 locked+expiry" }
}
```
- `hwid: ""` → unlocked. With Upstash set, it **auto-locks** to the first device
  that uses it. Without Upstash, leave a key unlocked or paste the buyer's HWID.
- `hwid: "..."` → hard-locked to that device now.
- `expires` → unix seconds (`0` = never).

### 3. HWID collection (if not using auto-lock)
Have the buyer run this in their executor and send you the result:
```lua
print(game:GetService("RbxAnalyticsService"):GetClientId())
```
Paste it into that key's `hwid`.

### 4. Ship the loader
- In `user_scripts/animeball_loader.lua`, confirm `ENDPOINT` matches your Vercel
  production domain.
- Give each buyer the loader + their key. They run:
```lua
getgenv().AnimeBallKey = "ABC-123-XYZ"
loadstring(game:HttpGet("https://<your-domain>/raw/animeball_loader.lua"))()
```
(or bake the key into their copy of the loader.)

## How a request flows
1. Loader computes HWID, POSTs `{key, hwid}` to `/api/animeballhub`.
2. Server checks the key exists, isn't expired, and the HWID matches (or binds it).
3. On success it fetches the private obfuscated script and returns it.
4. Loader `loadstring`s and runs it. On failure it warns and does nothing.

## Rotating / revoking
- Revoke a key: remove it from `ANIMEBALL_KEYS`.
- Reset a device lock: clear that key's `hwid` (and delete `animeball:hwid:<key>`
  in Upstash if used).
