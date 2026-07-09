-- ferret/lexer.lua
-- Tokenizer for the Lua subset accepted by the ferret VM obfuscator.
-- Produces a flat list of tokens: { type=, value=, line= }.
-- Ported to pure Lua from the design of LuaCrypt/ferret's parse stage.

local Lexer = {}

local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true,
}

-- Multi-char operators, longest first so greedy matching is correct.
local SYMBOLS = {
    "...", "..", "::", "==", "~=", "<=", ">=", "//", "<<", ">>",
    "+", "-", "*", "/", "%", "^", "#", "&", "~", "|", "<", ">", "=",
    "(", ")", "{", "}", "[", "]", ";", ":", ",", ".",
}

local function isDigit(c) return c >= "0" and c <= "9" end
local function isHex(c)
    return (c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F")
end
local function isAlpha(c)
    return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"
end
local function isAlphaNum(c) return isAlpha(c) or isDigit(c) end

function Lexer.tokenize(src, chunkname)
    chunkname = chunkname or "input"
    local tokens = {}
    local pos, line = 1, 1
    local n = #src

    local function err(msg)
        error(string.format("%s:%d: %s", chunkname, line, msg), 0)
    end

    local function peek(o) return src:sub(pos + (o or 0), pos + (o or 0)) end

    local function newline()
        -- handles \n, \r, \r\n, \n\r
        local c = peek()
        pos = pos + 1
        local c2 = peek()
        if (c2 == "\n" or c2 == "\r") and c2 ~= c then pos = pos + 1 end
        line = line + 1
    end

    -- Reads a long bracket [[ ... ]] / [=[ ... ]=]. Returns content or nil if not one.
    local function readLongBracket()
        local start = pos
        if peek() ~= "[" then return nil end
        local level = 0
        local p = pos + 1
        while src:sub(p, p) == "=" do level = level + 1; p = p + 1 end
        if src:sub(p, p) ~= "[" then return nil end
        pos = p + 1
        -- a leading newline immediately after the opening bracket is skipped
        if peek() == "\r" or peek() == "\n" then newline() end
        local buf = {}
        local close = "]" .. string.rep("=", level) .. "]"
        while true do
            if pos > n then err("unfinished long bracket (started earlier)") end
            local c = peek()
            if c == "]" and src:sub(pos, pos + #close - 1) == close then
                pos = pos + #close
                return table.concat(buf)
            elseif c == "\n" or c == "\r" then
                buf[#buf + 1] = "\n"
                newline()
            else
                buf[#buf + 1] = c
                pos = pos + 1
            end
        end
    end

    local function readString(quote)
        pos = pos + 1 -- consume opening quote
        local buf = {}
        while true do
            if pos > n then err("unfinished string") end
            local c = peek()
            if c == quote then
                pos = pos + 1
                break
            elseif c == "\n" or c == "\r" then
                err("unfinished string")
            elseif c == "\\" then
                pos = pos + 1
                local e = peek()
                if e == "n" then buf[#buf + 1] = "\n"; pos = pos + 1
                elseif e == "t" then buf[#buf + 1] = "\t"; pos = pos + 1
                elseif e == "r" then buf[#buf + 1] = "\r"; pos = pos + 1
                elseif e == "a" then buf[#buf + 1] = "\a"; pos = pos + 1
                elseif e == "b" then buf[#buf + 1] = "\b"; pos = pos + 1
                elseif e == "f" then buf[#buf + 1] = "\f"; pos = pos + 1
                elseif e == "v" then buf[#buf + 1] = "\v"; pos = pos + 1
                elseif e == "\\" then buf[#buf + 1] = "\\"; pos = pos + 1
                elseif e == '"' then buf[#buf + 1] = '"'; pos = pos + 1
                elseif e == "'" then buf[#buf + 1] = "'"; pos = pos + 1
                elseif e == "\n" or e == "\r" then buf[#buf + 1] = "\n"; newline()
                elseif e == "x" then
                    pos = pos + 1
                    local h = ""
                    for _ = 1, 2 do
                        if isHex(peek()) then h = h .. peek(); pos = pos + 1 end
                    end
                    if #h == 0 then err("hexadecimal digit expected") end
                    buf[#buf + 1] = string.char(tonumber(h, 16))
                elseif e == "z" then
                    pos = pos + 1
                    while pos <= n do
                        local w = peek()
                        if w == "\n" or w == "\r" then newline()
                        elseif w == " " or w == "\t" or w == "\f" or w == "\v" then pos = pos + 1
                        else break end
                    end
                elseif isDigit(e) then
                    local d = ""
                    for _ = 1, 3 do
                        if isDigit(peek()) then d = d .. peek(); pos = pos + 1 else break end
                    end
                    local num = tonumber(d)
                    if num > 255 then err("decimal escape too large") end
                    buf[#buf + 1] = string.char(num)
                else
                    err("invalid escape sequence '\\" .. e .. "'")
                end
            else
                buf[#buf + 1] = c
                pos = pos + 1
            end
        end
        return table.concat(buf)
    end

    local function readNumber()
        local start = pos
        if peek() == "0" and (peek(1) == "x" or peek(1) == "X") then
            pos = pos + 2
            while isHex(peek()) or peek() == "." do pos = pos + 1 end
            if peek() == "p" or peek() == "P" then
                pos = pos + 1
                if peek() == "+" or peek() == "-" then pos = pos + 1 end
                while isDigit(peek()) do pos = pos + 1 end
            end
        else
            while isDigit(peek()) or peek() == "." do pos = pos + 1 end
            if peek() == "e" or peek() == "E" then
                pos = pos + 1
                if peek() == "+" or peek() == "-" then pos = pos + 1 end
                while isDigit(peek()) do pos = pos + 1 end
            end
        end
        local text = src:sub(start, pos - 1)
        local value = tonumber(text)
        if value == nil then err("malformed number near '" .. text .. "'") end
        return value, text
    end

    while pos <= n do
        local c = peek()
        local tokStart = pos
        if c == "\n" or c == "\r" then
            newline()
        elseif c == " " or c == "\t" or c == "\f" or c == "\v" then
            pos = pos + 1
        elseif c == "-" and peek(1) == "-" then
            pos = pos + 2
            if peek() == "[" then
                local saved = pos
                local content = readLongBracket()
                if content == nil then
                    pos = saved
                    while pos <= n and peek() ~= "\n" and peek() ~= "\r" do pos = pos + 1 end
                end
            else
                while pos <= n and peek() ~= "\n" and peek() ~= "\r" do pos = pos + 1 end
            end
        elseif isAlpha(c) then
            while isAlphaNum(peek()) do pos = pos + 1 end
            local word = src:sub(tokStart, pos - 1)
            if KEYWORDS[word] then
                tokens[#tokens + 1] = { type = "keyword", value = word, line = line, raw = word }
            else
                tokens[#tokens + 1] = { type = "name", value = word, line = line, raw = word }
            end
        elseif isDigit(c) or (c == "." and isDigit(peek(1))) then
            local ln = line
            local value = readNumber()
            tokens[#tokens + 1] = { type = "number", value = value, line = ln, raw = src:sub(tokStart, pos - 1) }
        elseif c == '"' or c == "'" then
            local ln = line
            local value = readString(c)
            tokens[#tokens + 1] = { type = "string", value = value, line = ln, raw = src:sub(tokStart, pos - 1), long = false }
        elseif c == "[" and (peek(1) == "[" or peek(1) == "=") then
            local ln = line
            local content = readLongBracket()
            if content ~= nil then
                tokens[#tokens + 1] = { type = "string", value = content, line = ln, raw = src:sub(tokStart, pos - 1), long = true }
            else
                tokens[#tokens + 1] = { type = "symbol", value = "[", line = ln, raw = "[" }
                pos = pos + 1
            end
        else
            local matched = nil
            for _, sym in ipairs(SYMBOLS) do
                if src:sub(pos, pos + #sym - 1) == sym then matched = sym; break end
            end
            if not matched then err("unexpected symbol near '" .. c .. "'") end
            tokens[#tokens + 1] = { type = "symbol", value = matched, line = line, raw = matched }
            pos = pos + #matched
        end
    end

    tokens[#tokens + 1] = { type = "eof", value = "<eof>", line = line }
    return tokens
end

return Lexer
