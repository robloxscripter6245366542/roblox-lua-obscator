-- luau-vm/src/lexer.lua
-- Tokenizer for the Luau subset the VM compiler accepts. Single pass, minimal
-- allocation (one token table per token, no intermediate substrings beyond the
-- token text). Returns an array of { type, value, line }.

local Lexer = {}

local KEYWORDS = {}
for _, k in ipairs({
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while',
}) do KEYWORDS[k] = true end

-- Longest match wins, so multi-char operators are listed before their prefixes.
-- Luau compound assignments (`+=`, `..=`, `//=`, …) are included.
local SYMBOLS = {
  '...', '//=', '..=',
  '..', '::', '==', '~=', '<=', '>=', '//', '<<', '>>', '->',
  '+=', '-=', '*=', '/=', '%=', '^=',
  '+', '-', '*', '/', '%', '^', '#', '&', '~', '|', '<', '>', '=',
  '(', ')', '{', '}', '[', ']', ';', ':', ',', '.', '?',
}

local function isDigit(c) return c >= '0' and c <= '9' end
local function isHex(c)
  return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')
end
local function isAlpha(c)
  return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
end
local function isAlphaNum(c) return isAlpha(c) or isDigit(c) end

-- Encode a Unicode code point as UTF-8 (mirrors Lua's luaO_utf8esc: up to 6
-- bytes for values through 0x7FFFFFFF), so \u{...} matches native Lua/Luau.
local function utf8esc(cp)
  if cp < 0x80 then return string.char(cp) end
  local cont, mfb, x = {}, 0x3f, cp
  repeat
    cont[#cont + 1] = 0x80 + (x % 0x40)
    x = math.floor(x / 0x40)
    mfb = math.floor(mfb / 2)
  until x <= mfb
  local firstByte = ((255 - mfb) * 2) % 256 + x -- (~mfb << 1) | x, byte-wide
  local out = { string.char(firstByte) }
  for i = #cont, 1, -1 do out[#out + 1] = string.char(cont[i]) end -- continuation bytes, high→low
  return table.concat(out)
end

function Lexer.tokenize(src, chunk)
  chunk = chunk or 'input'
  local tokens = {}
  local pos, line, n = 1, 1, #src

  local function err(msg) error(chunk .. ':' .. line .. ': ' .. msg, 0) end
  local function peek(o) return src:sub(pos + (o or 0), pos + (o or 0)) end

  local function newline()
    local c = peek(); pos = pos + 1
    local c2 = peek()
    if (c2 == '\n' or c2 == '\r') and c2 ~= c then pos = pos + 1 end
    line = line + 1
  end

  local function readLong()
    if peek() ~= '[' then return nil end
    local level, p = 0, pos + 1
    while src:sub(p, p) == '=' do level = level + 1; p = p + 1 end
    if src:sub(p, p) ~= '[' then return nil end
    pos = p + 1
    if peek() == '\r' or peek() == '\n' then newline() end
    local buf, close = {}, ']' .. string.rep('=', level) .. ']'
    while true do
      if pos > n then err('unfinished long bracket') end
      local c = peek()
      if c == ']' and src:sub(pos, pos + #close - 1) == close then
        pos = pos + #close; return table.concat(buf)
      elseif c == '\n' or c == '\r' then buf[#buf + 1] = '\n'; newline()
      else buf[#buf + 1] = c; pos = pos + 1 end
    end
  end

  local function readString(q)
    pos = pos + 1
    local buf = {}
    while true do
      if pos > n then err('unfinished string') end
      local c = peek()
      if c == q then pos = pos + 1; break
      elseif c == '\n' or c == '\r' then err('unfinished string')
      elseif c == '\\' then
        pos = pos + 1
        local e = peek()
        if e == 'n' then buf[#buf + 1] = '\n'; pos = pos + 1
        elseif e == 't' then buf[#buf + 1] = '\t'; pos = pos + 1
        elseif e == 'r' then buf[#buf + 1] = '\r'; pos = pos + 1
        elseif e == 'a' then buf[#buf + 1] = '\a'; pos = pos + 1
        elseif e == 'b' then buf[#buf + 1] = '\b'; pos = pos + 1
        elseif e == 'f' then buf[#buf + 1] = '\f'; pos = pos + 1
        elseif e == 'v' then buf[#buf + 1] = '\v'; pos = pos + 1
        elseif e == '\\' then buf[#buf + 1] = '\\'; pos = pos + 1
        elseif e == '"' then buf[#buf + 1] = '"'; pos = pos + 1
        elseif e == "'" then buf[#buf + 1] = "'"; pos = pos + 1
        elseif e == '\n' or e == '\r' then buf[#buf + 1] = '\n'; newline()
        elseif e == 'x' then
          pos = pos + 1
          local h = ''
          for _ = 1, 2 do if isHex(peek()) then h = h .. peek(); pos = pos + 1 end end
          if #h == 0 then err('hexadecimal digit expected') end
          buf[#buf + 1] = string.char(tonumber(h, 16))
        elseif e == 'z' then
          pos = pos + 1
          while pos <= n do
            local w = peek()
            if w == '\n' or w == '\r' then newline()
            elseif w == ' ' or w == '\t' or w == '\f' or w == '\v' then pos = pos + 1
            else break end
          end
        elseif e == 'u' then
          -- \u{XXXX}: Unicode code point, UTF-8 encoded (Lua 5.3+/Luau)
          pos = pos + 1
          if peek() ~= '{' then err("missing '{' in \\u{XXXX}") end
          pos = pos + 1
          local h = ''
          while isHex(peek()) do h = h .. peek(); pos = pos + 1 end
          if #h == 0 then err('hexadecimal digit expected') end
          if peek() ~= '}' then err("missing '}' in \\u{XXXX}") end
          pos = pos + 1
          local cp = tonumber(h, 16)
          if cp > 0x7FFFFFFF then err('UTF-8 value too large') end
          buf[#buf + 1] = utf8esc(cp)
        elseif isDigit(e) then
          local d = ''
          for _ = 1, 3 do if isDigit(peek()) then d = d .. peek(); pos = pos + 1 else break end end
          local num = tonumber(d)
          if num > 255 then err('decimal escape too large') end
          buf[#buf + 1] = string.char(num)
        else err("invalid escape sequence '\\" .. e .. "'") end
      else buf[#buf + 1] = c; pos = pos + 1 end
    end
    return table.concat(buf)
  end

  -- Luau string interpolation: `text {expr} more`. Produces an 'interp' token
  -- carrying the literal chunks and the raw source of each embedded expression;
  -- the parser turns it into a `..`/tostring concatenation. `\{` is a literal
  -- brace; `{` opens an interpolation whose braces/strings are balanced so a `}`
  -- inside a nested table or string does not close it early.
  local function readInterp()
    pos = pos + 1 -- past the opening backtick
    local literals, exprs = {}, {}
    local buf = {}
    while true do
      if pos > n then err('unfinished interpolated string') end
      local c = peek()
      if c == '`' then pos = pos + 1; literals[#literals + 1] = table.concat(buf); break
      elseif c == '\n' or c == '\r' then err('unfinished interpolated string')
      elseif c == '\\' then
        pos = pos + 1; local e = peek()
        if e == 'n' then buf[#buf + 1] = '\n'; pos = pos + 1
        elseif e == 't' then buf[#buf + 1] = '\t'; pos = pos + 1
        elseif e == 'r' then buf[#buf + 1] = '\r'; pos = pos + 1
        elseif e == '`' then buf[#buf + 1] = '`'; pos = pos + 1
        elseif e == '{' then buf[#buf + 1] = '{'; pos = pos + 1
        elseif e == '}' then buf[#buf + 1] = '}'; pos = pos + 1
        elseif e == '\\' then buf[#buf + 1] = '\\'; pos = pos + 1
        else buf[#buf + 1] = '\\' .. e; pos = pos + 1 end
      elseif c == '{' then
        literals[#literals + 1] = table.concat(buf); buf = {}
        pos = pos + 1
        local estart, depth = pos, 1
        while depth > 0 do
          if pos > n then err('unfinished interpolation expression') end
          local d = peek()
          if d == '{' then depth = depth + 1; pos = pos + 1
          elseif d == '}' then depth = depth - 1; pos = pos + 1
          elseif d == '"' or d == "'" then readString(d) -- skip a nested string literal
          else pos = pos + 1 end
        end
        exprs[#exprs + 1] = src:sub(estart, pos - 2) -- inner source, sans braces
      else buf[#buf + 1] = c; pos = pos + 1 end
    end
    return { literals = literals, exprs = exprs }
  end

  local function readNumber()
    local start = pos
    if peek() == '0' and (peek(1) == 'x' or peek(1) == 'X') then
      pos = pos + 2
      while isHex(peek()) or peek() == '.' do pos = pos + 1 end
      if peek() == 'p' or peek() == 'P' then
        pos = pos + 1
        if peek() == '+' or peek() == '-' then pos = pos + 1 end
        while isDigit(peek()) do pos = pos + 1 end
      end
    else
      while isDigit(peek()) or peek() == '.' do pos = pos + 1 end
      if peek() == 'e' or peek() == 'E' then
        pos = pos + 1
        if peek() == '+' or peek() == '-' then pos = pos + 1 end
        while isDigit(peek()) do pos = pos + 1 end
      end
    end
    return src:sub(start, pos - 1)
  end

  while pos <= n do
    local c = peek()
    local tokStart = pos
    if c == '\n' or c == '\r' then newline()
    elseif c == ' ' or c == '\t' or c == '\f' or c == '\v' then pos = pos + 1
    elseif c == '-' and peek(1) == '-' then
      pos = pos + 2
      if peek() == '[' then
        local saved = pos
        if readLong() == nil then
          pos = saved
          while pos <= n and peek() ~= '\n' and peek() ~= '\r' do pos = pos + 1 end
        end
      else
        while pos <= n and peek() ~= '\n' and peek() ~= '\r' do pos = pos + 1 end
      end
    elseif isAlpha(c) then
      while isAlphaNum(peek()) do pos = pos + 1 end
      local w = src:sub(tokStart, pos - 1)
      tokens[#tokens + 1] = { type = KEYWORDS[w] and 'keyword' or 'name', value = w, line = line }
    elseif isDigit(c) or (c == '.' and isDigit(peek(1))) then
      local ln = line
      tokens[#tokens + 1] = { type = 'number', value = readNumber(), line = ln }
    elseif c == '"' or c == "'" then
      local ln = line
      tokens[#tokens + 1] = { type = 'string', value = readString(c), line = ln }
    elseif c == '`' then
      local ln = line
      local it = readInterp()
      tokens[#tokens + 1] = { type = 'interp', literals = it.literals, exprs = it.exprs, line = ln }
    elseif c == '[' and (peek(1) == '[' or peek(1) == '=') then
      local ln = line
      local s = readLong()
      if s ~= nil then tokens[#tokens + 1] = { type = 'string', value = s, line = ln }
      else tokens[#tokens + 1] = { type = 'symbol', value = '[', line = ln }; pos = pos + 1 end
    else
      local matched
      for _, sym in ipairs(SYMBOLS) do
        if src:sub(pos, pos + #sym - 1) == sym then matched = sym; break end
      end
      if not matched then err("unexpected symbol near '" .. c .. "'") end
      tokens[#tokens + 1] = { type = 'symbol', value = matched, line = line }
      pos = pos + #matched
    end
  end
  tokens[#tokens + 1] = { type = 'eof', value = '<eof>', line = line }
  return tokens
end

return Lexer
