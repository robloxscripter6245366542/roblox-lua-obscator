-- ferret/emit.lua
-- Serializes a token stream back into runnable Lua source.
-- Strips comments and redundant whitespace, but preserves original line
-- breaks between tokens so ambiguous call syntax (a = b\n(f)()) never fuses.

local Emit = {}

local SYMCHARS = {}
for ch in ("+-*/%^#&~|<>=(){}[];:,."):gmatch(".") do SYMCHARS[ch] = true end

local function isWord(ch)
    return ch ~= "" and ch:match("[%w_]") ~= nil
end
local function isSym(ch)
    return SYMCHARS[ch] == true
end

-- Re-serialize a string value to a safe single-quoted/decimal-escaped literal.
-- Used when a layer rewrites a string token (value known, raw discarded).
function Emit.stringLiteral(s)
    local out = { '"' }
    for i = 1, #s do
        local b = s:byte(i)
        if b == 34 then out[#out + 1] = '\\"'
        elseif b == 92 then out[#out + 1] = "\\\\"
        elseif b >= 32 and b <= 126 then out[#out + 1] = string.char(b)
        else
            -- Fixed 3-digit decimal escape: greedy \ddd never swallows a
            -- following literal digit, and keeps output pure ASCII.
            out[#out + 1] = string.format("\\%03d", b)
        end
    end
    out[#out + 1] = '"'
    return table.concat(out)
end

-- Decide whether whitespace is required between two adjacent tokens so they
-- do not lex as a single different token.
local function needSpace(prev, cur)
    local lp = prev.raw:sub(-1)
    local fc = cur.raw:sub(1, 1)
    if isWord(lp) and isWord(fc) then return true end       -- name/number adjacency
    if isSym(lp) and isSym(fc) then return true end         -- e.g. - -  ~ =  [ [
    if prev.type == "number" and fc == "." then return true end -- 1..2 hazard
    return false
end

-- tokens: array from Lexer.tokenize (may have been transformed; each token
-- must carry a `raw` field holding its exact emitted text).
function Emit.emit(tokens)
    local out = {}
    local prev = nil
    local prevLine = 1
    for _, tok in ipairs(tokens) do
        if tok.type == "eof" then break end
        if prev == nil then
            prevLine = tok.line
        elseif tok.line and tok.line > prevLine then
            out[#out + 1] = "\n"
            prevLine = tok.line
        elseif needSpace(prev, tok) then
            out[#out + 1] = " "
        end
        out[#out + 1] = tok.raw
        prev = tok
    end
    return table.concat(out)
end

return Emit
