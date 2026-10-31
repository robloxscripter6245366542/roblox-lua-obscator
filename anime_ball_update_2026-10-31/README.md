# Anime Ball update — 2026-10-31 dump (paste oF9hMs5L8b)

The dump is **630 scripts of raw Luau bytecode** (no source). It is bytecode
**version 14**, newer than the public Luau format: every function is now
prefixed with its byte size, and `CALL` is re-encoded as opcode 87 followed by
an extra feedback word. `tools/luau_disasm.py` parses all 630 scripts without
errors and disassembles them (opcodes, constants, jump targets). It is a
disassembler, not a full decompiler.

- `disasm/*.txt` — full disassembly of the modules that matter for parrying.
- `script_index.txt` — every script in the dump with its function names.

## What changed that matters for parrying

| Area | Finding |
|---|---|
| **New `AutoParryController`** | The game now has its **own server-side auto parry** (`AutoParryService`). The client toggles it with `AutoParryService.SetEnabled:Invoke(bool)`, and the server replies with the new state, or `nil` when it refuses. The server only shows the panel to some players (`Server.Show`). |
| `SwordController.Block` | Unchanged: `Block:Invoke(Camera.LookVector.Y)` returns `nil` when rejected, `false` when the shield is up, and `true` for an instant parry. |
| `SwordInfo` | Unchanged: `BlockDuration = 0.6`, `DefaultCooldown = 1.0`. |
| `BallController.ChangeBallColor` | Unchanged signature `(ballName, target, color)`. It still skips writing the `Target` attribute under `NoHighlight` and for invisible balls. |
| `BallController.TrackBall` (new) | Records the ball's CFrame into `SmoothStates`, but nothing on the client reads it or moves the ball, so ball positions stay real. |
| `BallController.GetBallAsync` | Still adds an `Invisible`-changed connection on every call (the leak the hub patches). |
| `ClashController.StartClash` | Still only sets `ClashMode` when your *Clash* visual setting is on (the hub works around this). |
| `CharacterController` | New `capVelocity` / `capAngularVelocity` caps on your character's speed. They don't affect blocking. |
| Anti-cheat | No client-side detection strings found in any of the 630 scripts. |
