--[[==========================================================================
  DropKick.lua  —  honest deobfuscation / reconstruction
  ==========================================================================

  Source     : loadstring(game:HttpGet(
                 "https://raw.githubusercontent.com/platinww/CrustyMain/"..
                 "refs/heads/main/universal/DropKick.lua"))()
  Protection : Luraph Obfuscator v15.0  (confirmed from the file header and
               fingerprint())
  Committed  : luraph-deobf/sample_v15.lua  (the raw protected input)
  Method     : luraph-deobf toolkit —
                 peel.py            (container: substitution map + base-85)
                 dynamic/run.py     (booted the VM in a stubbed Luau env,
                                     captured the decrypted constant pool)
                 dynamic/run_v15.py (VM handler/dispatch trace)
                 devirt/v15_opcodes.py (opcode/handler map)

  ------------------------------------------------------------------------
  HONESTY STATEMENT — READ THIS
  ------------------------------------------------------------------------
  This is NOT a byte-perfect decompile. Luraph v15 virtualises the program
  into custom, XOR-encrypted bytecode run by a threaded VM (see ../v15.md).
  Two things limit a full recovery of THIS sample:

    1. The program logic is VM bytecode. Lifting it back to exact Lua needs
       the per-opcode semantic map, which is not finished (68/145 handlers
       observed, 77 never exercised — ../devirt/v15_opcode_map.md).
    2. When booted under a stubbed environment, the VM aborts during its own
       bootstrap (an executor/debug integrity gate) BEFORE it runs the drop
       payload. So the program's own strings — remote names, any URLs, target
       logic — were NOT decoded and are NOT known.

  Everything below marked [RECOVERED] is real, evidenced by the tool output.
  Everything marked [PLACEHOLDER] is NOT recovered; it is a labelled stub, not
  reconstructed logic. No behaviour has been invented or guessed.

  ========================================================================== ]]


-- ==========================================================================
-- [RECOVERED] Outer structure — the Luraph v15 loader
-- ==========================================================================
-- The entire protected file is a single expression of this exact shape
-- (verified in sample_v15.lua):
--
--     return setmetatable({ <~145 handler fields + ~83 cached lib slots> },
--                         {}):XA()(...)
--
--   * the table's named fields (s, Fu, tA, X, Mu, Nu, ...) are threaded VM
--     handlers; each returns (next_handler_id, regs...) and the driver
--     fetches them into locals and calls them in a `while true` loop;
--   * numeric fields cache host functions ([94]=buffer.readu8,
--     [37]=buffer.writeu8, [68]=bit32.bxor, ...);
--   * `:XA()` is the bootstrap; the trailing `(...)` invokes the recovered
--     top-level program function with the script varargs.
--
-- The bytecode arrives in one packed string, decoded WITHOUT any compression:
--
--     local blob = [=[LPH@G_Fcc ... ]=]                 -- ~165 KB
--     blob = blob:gsub(<per-build 1->many char map>)    -- substitution table
--     blob = base85_decode(blob)                        -- Ascii85 variant
--     local code = buffer.fromstring(blob)              -- 132 KB VM buffer
--     -- code stays XOR-encrypted; each byte is decrypted on read:
--     --   buffer.writeu8(dst, i, bit32.bxor(k, buffer.readu8(code, i), k2))
--
-- See peel.py (recovers the buffer) and ../v15.md for the measured details.

local PROTECTED_BLOB = "[=[LPH@G_Fcc ...165030 chars omitted... ]=]"
--                     ^ [RECOVERED as data] the real packed VM buffer;
--                       see sample_v15.lua. It is XOR-encrypted at rest.


-- ==========================================================================
-- [RECOVERED] Program API surface — the decrypted VM constant pool
-- ==========================================================================
-- Booting the VM under dynamic/run.py decrypted this exact set of names the
-- program resolves from the host (67 constants, in decode order). This tells
-- us WHICH host APIs DropKick touches, even though the call sites are still
-- in bytecode. Grouped by purpose:

local USES = {
  scheduler   = { "task", "spawn", "defer", "delay", "cancel", "wait" },
  coroutine   = { "create", "status", "yield", "close", "resume", "wrap",
                  "running", "isyieldable" },
  environment = { "identifyexecutor", "loadstring", "getfenv", "setfenv",
                  "getmetatable", "setmetatable", "rawget", "rawset" },
  -- Anti-tamper / introspection. The VM REQUIRES the Luau debug library and
  -- reads debug.info/getinfo fields; if absent it raises the recovered
  -- string below. This is the gate that stops a naive stubbed run.
  antitamper  = { "debug", "info", "getinfo", "traceback",
                  "lastlinedefined", "namewhat", "short_src", "source",
                  "isvararg", "nparams", "what", "currentline", "linedefined",
                  ["error_string"] =
                    "The debug library is required on Luau platforms. " ..
                    "Please open a support ticket." },
  datatypes   = { "Random", "Vector3", "Vector2", "Instance", "UDim", "UDim2",
                  "Path2DControlPoint", "new", "typeof", "type" },
  string_lib  = { "format", "match", "gmatch", "find", "char", "byte",
                  "gsub", "sub", "rep" },
  table_lib   = { "unpack", "pack", "concat", "insert" },
  core        = { "tonumber", "tostring", "select", "xpcall", "assert",
                  "error", "pcall", "next" },
}

-- NOTE what is ABSENT from the pool: no `game`, `GetService`, `HttpGet`,
-- `FireServer`/remote names, and no URLs. Those would be program-payload
-- constants decoded later at runtime — the VM aborted (see gate above) before
-- reaching them, so DropKick's actual drop/kick mechanism is NOT in evidence.


-- ==========================================================================
-- [RECOVERED, reconstructed faithfully] Anti-tamper / environment gate
-- ==========================================================================
-- Reconstructed from the constant pool: the loader verifies a real Luau debug
-- library is present (Luraph uses debug.info for integrity + line info) and
-- errors out otherwise. Exact expression is in bytecode; this is the behaviour
-- the constants dictate, not a guess at the surrounding control flow.
local function assert_luau_debug_present()
    if type(debug) ~= "table" or type(debug.info or debug.getinfo) ~= "function" then
        error("The debug library is required on Luau platforms. " ..
              "Please open a support ticket.")
    end
    -- Reads getinfo fields: lastlinedefined, namewhat, short_src, source,
    -- isvararg, nparams, what, currentline, linedefined  [RECOVERED names].
end


-- ==========================================================================
-- [PLACEHOLDER] The DropKick program logic
-- ==========================================================================
-- This is the part that is genuinely NOT recovered. It lives as virtualised,
-- runtime-XOR-decrypted bytecode and the VM did not execute it under stubs, so
-- neither a static lift nor a dynamic capture produced its real behaviour.
--
-- What is honestly known about it: from the name and the recovered API surface
-- it is a client-side script that uses the task scheduler, coroutines, and
-- Roblox datatypes (Vector3/Instance/Random). Its actual target selection,
-- any remotes it fires, and any endpoints it contacts are UNKNOWN — those
-- strings were never decoded.
--
-- Do NOT treat the body below as the script's logic. It is an explicit stub.
local function DropKick_main(...)
    assert_luau_debug_present()

    --[[ PLACEHOLDER: unrecovered virtualised body.
         To recover it, either:
           (a) finish the v15 opcode lift — assign semantics to the observed
               handlers (../devirt/v15_opcode_map.md) and codegen; or
           (b) satisfy the executor/debug integrity gate in dynamic/run.py so
               the VM runs to the payload, then re-capture strings + behaviour
               (HttpGet/GetService/FireServer). See ../v15.md "remaining last
               mile".
         Until then the drop/kick mechanism, targets, and any network calls
         are unknown and are left as this placeholder. ]]
    return nil
end


-- ==========================================================================
-- Entry point (mirrors the recovered `:XA()(...)` invocation)
-- ==========================================================================
return DropKick_main(...)
