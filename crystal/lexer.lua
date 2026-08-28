-- Crystal Language Lexer
-- Tokenizes Crystal source code into a stream of tokens

local Lexer = {}
Lexer.__index = Lexer

local TOKEN = {
    -- Literals
    NUMBER   = "NUMBER",
    STRING   = "STRING",
    BOOL     = "BOOL",
    NIL      = "NIL",
    IDENT    = "IDENT",

    -- Keywords
    LET      = "LET",
    CONST    = "CONST",
    FN       = "FN",
    RETURN   = "RETURN",
    IF       = "IF",
    ELIF     = "ELIF",
    ELSE     = "ELSE",
    WHILE    = "WHILE",
    FOR      = "FOR",
    IN       = "IN",
    BREAK    = "BREAK",
    CONTINUE = "CONTINUE",
    CLASS    = "CLASS",
    EXTENDS  = "EXTENDS",
    SELF     = "SELF",
    NEW      = "NEW",
    IMPORT   = "IMPORT",
    TRY      = "TRY",
    CATCH    = "CATCH",
    MATCH    = "MATCH",
    TRUE     = "TRUE",
    FALSE    = "FALSE",

    -- Operators
    PLUS     = "PLUS",
    MINUS    = "MINUS",
    STAR     = "STAR",
    SLASH    = "SLASH",
    PERCENT  = "PERCENT",
    EQ       = "EQ",
    NEQ      = "NEQ",
    LT       = "LT",
    GT       = "GT",
    LTE      = "LTE",
    GTE      = "GTE",
    AND      = "AND",
    OR       = "OR",
    NOT      = "NOT",
    CONCAT   = "CONCAT",
    RANGE    = "RANGE",
    ARROW    = "ARROW",
    FAT_ARROW = "FAT_ARROW",

    -- Assignment
    ASSIGN      = "ASSIGN",
    PLUS_ASSIGN = "PLUS_ASSIGN",
    MINUS_ASSIGN = "MINUS_ASSIGN",
    MUL_ASSIGN  = "MUL_ASSIGN",
    DIV_ASSIGN  = "DIV_ASSIGN",

    -- Punctuation
    LPAREN   = "LPAREN",
    RPAREN   = "RPAREN",
    LBRACE   = "LBRACE",
    RBRACE   = "RBRACE",
    LBRACKET = "LBRACKET",
    RBRACKET = "RBRACKET",
    COMMA    = "COMMA",
    DOT      = "DOT",
    COLON    = "COLON",
    SEMICOLON = "SEMICOLON",
    UNDERSCORE = "UNDERSCORE",

    -- Special
    EOF      = "EOF",
}

local KEYWORDS = {
    ["let"]      = TOKEN.LET,
    ["const"]    = TOKEN.CONST,
    ["fn"]       = TOKEN.FN,
    ["return"]   = TOKEN.RETURN,
    ["if"]       = TOKEN.IF,
    ["elif"]     = TOKEN.ELIF,
    ["else"]     = TOKEN.ELSE,
    ["while"]    = TOKEN.WHILE,
    ["for"]      = TOKEN.FOR,
    ["in"]       = TOKEN.IN,
    ["break"]    = TOKEN.BREAK,
    ["continue"] = TOKEN.CONTINUE,
    ["class"]    = TOKEN.CLASS,
    ["extends"]  = TOKEN.EXTENDS,
    ["self"]     = TOKEN.SELF,
    ["new"]      = TOKEN.NEW,
    ["import"]   = TOKEN.IMPORT,
    ["try"]      = TOKEN.TRY,
    ["catch"]    = TOKEN.CATCH,
    ["match"]    = TOKEN.MATCH,
    ["true"]     = TOKEN.TRUE,
    ["false"]    = TOKEN.FALSE,
    ["nil"]      = TOKEN.NIL,
    ["and"]      = TOKEN.AND,
    ["or"]       = TOKEN.OR,
    ["not"]      = TOKEN.NOT,
}

function Lexer.new(source)
    return setmetatable({
        source = source,
        pos    = 1,
        line   = 1,
        col    = 1,
        tokens = {},
    }, Lexer)
end

function Lexer:peek(offset)
    return self.source:sub(self.pos + (offset or 0), self.pos + (offset or 0))
end

function Lexer:advance()
    local ch = self.source:sub(self.pos, self.pos)
    self.pos = self.pos + 1
    if ch == "\n" then
        self.line = self.line + 1
        self.col  = 1
    else
        self.col = self.col + 1
    end
    return ch
end

function Lexer:match(ch)
    if self.source:sub(self.pos, self.pos) == ch then
        self:advance()
        return true
    end
    return false
end

function Lexer:skipWhitespaceAndComments()
    while self.pos <= #self.source do
        local ch = self:peek()
        if ch == " " or ch == "\t" or ch == "\r" or ch == "\n" then
            self:advance()
        elseif ch == "-" and self:peek(1) == "-" then
            -- line comment
            while self.pos <= #self.source and self:peek() ~= "\n" do
                self:advance()
            end
        elseif ch == "/" and self:peek(1) == "/" then
            -- C-style line comment
            while self.pos <= #self.source and self:peek() ~= "\n" do
                self:advance()
            end
        elseif ch == "/" and self:peek(1) == "*" then
            -- block comment
            self:advance(); self:advance()
            while self.pos <= #self.source do
                if self:peek() == "*" and self:peek(1) == "/" then
                    self:advance(); self:advance()
                    break
                end
                self:advance()
            end
        else
            break
        end
    end
end

function Lexer:readString(delim)
    local buf = {}
    while self.pos <= #self.source do
        local ch = self:advance()
        if ch == delim then break end
        if ch == "\\" then
            local esc = self:advance()
            if     esc == "n"  then buf[#buf+1] = "\n"
            elseif esc == "t"  then buf[#buf+1] = "\t"
            elseif esc == "r"  then buf[#buf+1] = "\r"
            elseif esc == "\\" then buf[#buf+1] = "\\"
            elseif esc == delim then buf[#buf+1] = delim
            else   buf[#buf+1] = "\\" .. esc
            end
        else
            buf[#buf+1] = ch
        end
    end
    return table.concat(buf)
end

function Lexer:readFString()
    -- f"Hello {name}!" -> interpolated string token list
    local parts = {}
    local buf   = {}
    while self.pos <= #self.source do
        local ch = self:peek()
        if ch == '"' then self:advance(); break end
        if ch == "{" then
            self:advance()
            if #buf > 0 then
                parts[#parts+1] = { kind = "literal", value = table.concat(buf) }
                buf = {}
            end
            local expr = {}
            local depth = 1
            while self.pos <= #self.source do
                local c = self:peek()
                if c == "{" then depth = depth + 1
                elseif c == "}" then
                    depth = depth - 1
                    if depth == 0 then self:advance(); break end
                end
                expr[#expr+1] = self:advance()
            end
            parts[#parts+1] = { kind = "expr", value = table.concat(expr) }
        else
            buf[#buf+1] = self:advance()
        end
    end
    if #buf > 0 then
        parts[#parts+1] = { kind = "literal", value = table.concat(buf) }
    end
    return parts
end

function Lexer:readNumber()
    local start = self.pos - 1
    local isFloat = false
    -- We already consumed first digit, so back-track via start
    -- Actually we call this before consuming; let's consume here
    while self.pos <= #self.source do
        local ch = self:peek()
        if ch:match("%d") then
            self:advance()
        elseif ch == "." and self:peek(1):match("%d") and not isFloat then
            isFloat = true
            self:advance()
        elseif ch == "x" or ch == "X" then
            -- hex
            self:advance()
            while self.pos <= #self.source and self:peek():match("[0-9a-fA-F]") do
                self:advance()
            end
            break
        else
            break
        end
    end
    local raw = self.source:sub(start, self.pos - 1)
    return tonumber(raw)
end

function Lexer:token(kind, value, line, col)
    return { kind = kind, value = value, line = line, col = col }
end

function Lexer:tokenize()
    while self.pos <= #self.source do
        self:skipWhitespaceAndComments()
        if self.pos > #self.source then break end

        local line = self.line
        local col  = self.col
        local ch   = self:advance()

        -- Numbers
        if ch:match("%d") then
            local start = self.pos - 1
            while self.pos <= #self.source and self:peek():match("[%d%.x]") do
                if self:peek() == "." and not self:peek(1):match("%d") then break end
                self:advance()
            end
            local raw = self.source:sub(start, self.pos - 1)
            self.tokens[#self.tokens+1] = self:token(TOKEN.NUMBER, tonumber(raw), line, col)

        -- Identifiers / Keywords
        elseif ch:match("[%a_]") then
            local start = self.pos - 1
            while self.pos <= #self.source and self:peek():match("[%w_]") do
                self:advance()
            end
            local word = self.source:sub(start, self.pos - 1)
            if word == "_" then
                self.tokens[#self.tokens+1] = self:token(TOKEN.UNDERSCORE, "_", line, col)
            else
                local kw = KEYWORDS[word]
                self.tokens[#self.tokens+1] = self:token(kw or TOKEN.IDENT, word, line, col)
            end

        -- Strings
        elseif ch == '"' or ch == "'" then
            local s = self:readString(ch)
            self.tokens[#self.tokens+1] = self:token(TOKEN.STRING, s, line, col)

        -- Interpolated f-string
        elseif ch == "f" and self:peek() == '"' then
            self:advance()
            local parts = self:readFString()
            self.tokens[#self.tokens+1] = self:token("FSTRING", parts, line, col)

        -- Operators
        elseif ch == "+" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.PLUS_ASSIGN, "+=", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.PLUS, "+", line, col) end
        elseif ch == "-" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.MINUS_ASSIGN, "-=", line, col)
            elseif self:match(">") then self.tokens[#self.tokens+1] = self:token(TOKEN.ARROW, "->", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.MINUS, "-", line, col) end
        elseif ch == "*" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.MUL_ASSIGN, "*=", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.STAR, "*", line, col) end
        elseif ch == "/" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.DIV_ASSIGN, "/=", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.SLASH, "/", line, col) end
        elseif ch == "%" then
            self.tokens[#self.tokens+1] = self:token(TOKEN.PERCENT, "%", line, col)
        elseif ch == "=" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.EQ, "==", line, col)
            elseif self:match(">") then self.tokens[#self.tokens+1] = self:token(TOKEN.FAT_ARROW, "=>", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.ASSIGN, "=", line, col) end
        elseif ch == "!" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.NEQ, "!=", line, col)
            else error(("Crystal: unexpected '!' at line %d col %d"):format(line, col)) end
        elseif ch == "<" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.LTE, "<=", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.LT, "<", line, col) end
        elseif ch == ">" then
            if self:match("=") then self.tokens[#self.tokens+1] = self:token(TOKEN.GTE, ">=", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.GT, ">", line, col) end
        elseif ch == "." then
            if self:match(".") then self.tokens[#self.tokens+1] = self:token(TOKEN.RANGE, "..", line, col)
            else self.tokens[#self.tokens+1] = self:token(TOKEN.DOT, ".", line, col) end
        elseif ch == "#" then
            -- string length operator (like Lua's #)
            self.tokens[#self.tokens+1] = self:token("HASH", "#", line, col)

        -- Punctuation
        elseif ch == "(" then self.tokens[#self.tokens+1] = self:token(TOKEN.LPAREN,   "(", line, col)
        elseif ch == ")" then self.tokens[#self.tokens+1] = self:token(TOKEN.RPAREN,   ")", line, col)
        elseif ch == "{" then self.tokens[#self.tokens+1] = self:token(TOKEN.LBRACE,   "{", line, col)
        elseif ch == "}" then self.tokens[#self.tokens+1] = self:token(TOKEN.RBRACE,   "}", line, col)
        elseif ch == "[" then self.tokens[#self.tokens+1] = self:token(TOKEN.LBRACKET, "[", line, col)
        elseif ch == "]" then self.tokens[#self.tokens+1] = self:token(TOKEN.RBRACKET, "]", line, col)
        elseif ch == "," then self.tokens[#self.tokens+1] = self:token(TOKEN.COMMA,    ",", line, col)
        elseif ch == ":" then self.tokens[#self.tokens+1] = self:token(TOKEN.COLON,    ":", line, col)
        elseif ch == ";" then self.tokens[#self.tokens+1] = self:token(TOKEN.SEMICOLON,";", line, col)
        else
            -- silently skip unknown chars (could add stricter error)
        end
    end

    self.tokens[#self.tokens+1] = self:token(TOKEN.EOF, nil, self.line, self.col)
    return self.tokens
end

return { Lexer = Lexer, TOKEN = TOKEN }
