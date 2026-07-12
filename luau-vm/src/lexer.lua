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

local SYMBOLS = {
  '...', '..', '::', '==', '~=', '<=', '>=', '//', '<<', '>>',
  '+', '-', '*', '/', '%', '^', '#', '&', '~', '|', '<', '>', '=',
  '(', ')', '{', '}', '[', ']', ';', ':', ',', '.',
}

local function isDigit(c) return c >= '0' and c <= '9' end
local function isHex(c)
  return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')
end
local function isAlpha(c)
  return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
end
local function isAlphaNum(c) return isAlpha(c) or isDigit(c) end

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
