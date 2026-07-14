-- Crystal Language Parser
-- Builds an AST from the token stream produced by the Lexer

local lexerModule = require(script.Parent.lexer)
local TOKEN = lexerModule.TOKEN

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    return setmetatable({ tokens = tokens, pos = 1 }, Parser)
end

function Parser:peek(offset)
    local idx = self.pos + (offset or 0)
    return self.tokens[idx] or { kind = TOKEN.EOF }
end

function Parser:advance()
    local t = self.tokens[self.pos]
    self.pos = self.pos + 1
    return t
end

function Parser:check(kind)
    return self:peek().kind == kind
end

function Parser:match(...)
    for _, kind in ipairs({...}) do
        if self:check(kind) then
            return self:advance()
        end
    end
    return nil
end

function Parser:expect(kind, msg)
    if not self:check(kind) then
        local t = self:peek()
        error(("Crystal Parse Error [line %d col %d]: expected %s, got %s ('%s')")
            :format(t.line, t.col, kind, t.kind, tostring(t.value)))
    end
    return self:advance()
end

-- ── Program ──────────────────────────────────────────────────────────────────

function Parser:parse()
    local stmts = {}
    while not self:check(TOKEN.EOF) do
        stmts[#stmts+1] = self:parseStatement()
        self:match(TOKEN.SEMICOLON)
    end
    return { kind = "Program", body = stmts }
end

-- ── Statements ───────────────────────────────────────────────────────────────

function Parser:parseStatement()
    local t = self:peek()

    if t.kind == TOKEN.LET   then return self:parseVarDecl(false)
    elseif t.kind == TOKEN.CONST  then return self:parseVarDecl(true)
    elseif t.kind == TOKEN.FN    then return self:parseFnDecl()
    elseif t.kind == TOKEN.CLASS  then return self:parseClassDecl()
    elseif t.kind == TOKEN.RETURN then return self:parseReturn()
    elseif t.kind == TOKEN.IF    then return self:parseIf()
    elseif t.kind == TOKEN.WHILE  then return self:parseWhile()
    elseif t.kind == TOKEN.FOR   then return self:parseFor()
    elseif t.kind == TOKEN.BREAK  then self:advance(); return { kind = "Break" }
    elseif t.kind == TOKEN.CONTINUE then self:advance(); return { kind = "Continue" }
    elseif t.kind == TOKEN.TRY   then return self:parseTry()
    elseif t.kind == TOKEN.MATCH  then return self:parseMatch()
    elseif t.kind == TOKEN.IMPORT then return self:parseImport()
    elseif t.kind == TOKEN.LBRACE then return self:parseBlock()
    else
        return self:parseExprStatement()
    end
end

function Parser:parseBlock()
    self:expect(TOKEN.LBRACE)
    local stmts = {}
    while not self:check(TOKEN.RBRACE) and not self:check(TOKEN.EOF) do
        stmts[#stmts+1] = self:parseStatement()
        self:match(TOKEN.SEMICOLON)
    end
    self:expect(TOKEN.RBRACE)
    return { kind = "Block", body = stmts }
end

function Parser:parseVarDecl(isConst)
    self:advance() -- consume let/const
    local name = self:expect(TOKEN.IDENT).value
    local value = nil
    if self:match(TOKEN.ASSIGN) then
        value = self:parseExpression()
    end
    return { kind = "VarDecl", name = name, value = value, const = isConst }
end

function Parser:parseFnDecl(isMethod)
    self:advance() -- consume fn
    local name = nil
    if self:check(TOKEN.IDENT) then
        name = self:advance().value
    end
    self:expect(TOKEN.LPAREN)
    local params = {}
    if not self:check(TOKEN.RPAREN) then
        repeat
            params[#params+1] = self:expect(TOKEN.IDENT).value
        until not self:match(TOKEN.COMMA)
    end
    self:expect(TOKEN.RPAREN)
    local body = self:parseBlock()
    return { kind = "FnDecl", name = name, params = params, body = body }
end

function Parser:parseClassDecl()
    self:advance() -- consume class
    local name    = self:expect(TOKEN.IDENT).value
    local superClass = nil
    if self:match(TOKEN.EXTENDS) then
        superClass = self:expect(TOKEN.IDENT).value
    end
    self:expect(TOKEN.LBRACE)
    local methods = {}
    while not self:check(TOKEN.RBRACE) and not self:check(TOKEN.EOF) do
        if self:check(TOKEN.FN) then
            methods[#methods+1] = self:parseFnDecl(true)
        else
            self:advance() -- skip unexpected tokens inside class
        end
    end
    self:expect(TOKEN.RBRACE)
    return { kind = "ClassDecl", name = name, super = superClass, methods = methods }
end

function Parser:parseReturn()
    self:advance()
    local value = nil
    if not self:check(TOKEN.RBRACE) and not self:check(TOKEN.EOF) and not self:check(TOKEN.SEMICOLON) then
        value = self:parseExpression()
    end
    return { kind = "Return", value = value }
end

function Parser:parseIf()
    self:advance() -- consume if
    local cond = self:parseExpression()
    local thenBlock = self:parseBlock()
    local elseBlock = nil
    if self:match(TOKEN.ELIF) then
        -- treat elif as nested if in else
        self.pos = self.pos - 1 -- put ELIF back as IF? No, let's just recurse
        -- We already consumed ELIF so build an if node
        local elifCond = self:parseExpression()
        local elifThen = self:parseBlock()
        local elifElse = nil
        if self:check(TOKEN.ELIF) or self:check(TOKEN.ELSE) then
            elifElse = self:parseElsePart()
        end
        elseBlock = { kind = "Block", body = {{ kind = "If", cond = elifCond, thenBlock = elifThen, elseBlock = elifElse }} }
    elseif self:check(TOKEN.ELSE) then
        self:advance()
        elseBlock = self:parseBlock()
    end
    return { kind = "If", cond = cond, thenBlock = thenBlock, elseBlock = elseBlock }
end

function Parser:parseElsePart()
    if self:match(TOKEN.ELIF) then
        local cond = self:parseExpression()
        local thenBlock = self:parseBlock()
        local elseBlock = nil
        if self:check(TOKEN.ELIF) or self:check(TOKEN.ELSE) then
            elseBlock = self:parseElsePart()
        end
        return { kind = "Block", body = {{ kind = "If", cond = cond, thenBlock = thenBlock, elseBlock = elseBlock }} }
    elseif self:match(TOKEN.ELSE) then
        return self:parseBlock()
    end
end

function Parser:parseWhile()
    self:advance()
    local cond = self:parseExpression()
    local body = self:parseBlock()
    return { kind = "While", cond = cond, body = body }
end

function Parser:parseFor()
    self:advance()
    local var = self:expect(TOKEN.IDENT).value
    self:expect(TOKEN.IN)
    local iter = self:parseExpression()
    -- Check for range syntax already parsed as BinaryOp("..", ...)
    local body = self:parseBlock()
    return { kind = "For", var = var, iter = iter, body = body }
end

function Parser:parseTry()
    self:advance()
    local tryBlock  = self:parseBlock()
    local catchVar  = nil
    local catchBlock = nil
    if self:match(TOKEN.CATCH) then
        self:expect(TOKEN.LPAREN)
        catchVar = self:expect(TOKEN.IDENT).value
        self:expect(TOKEN.RPAREN)
        catchBlock = self:parseBlock()
    end
    return { kind = "Try", tryBlock = tryBlock, catchVar = catchVar, catchBlock = catchBlock }
end

function Parser:parseMatch()
    self:advance()
    local subject = self:parseExpression()
    self:expect(TOKEN.LBRACE)
    local arms = {}
    while not self:check(TOKEN.RBRACE) and not self:check(TOKEN.EOF) do
        local pattern
        if self:check(TOKEN.UNDERSCORE) then
            self:advance()
            pattern = { kind = "Wildcard" }
        else
            pattern = self:parseExpression()
        end
        self:expect(TOKEN.FAT_ARROW)
        local action = self:parseStatement()
        arms[#arms+1] = { pattern = pattern, action = action }
        self:match(TOKEN.SEMICOLON)
        self:match(TOKEN.COMMA)
    end
    self:expect(TOKEN.RBRACE)
    return { kind = "Match", subject = subject, arms = arms }
end

function Parser:parseImport()
    self:advance()
    local path = self:expect(TOKEN.STRING).value
    return { kind = "Import", path = path }
end

function Parser:parseExprStatement()
    local expr = self:parseExpression()
    -- Compound assignment expansion
    local op = self:match(TOKEN.PLUS_ASSIGN, TOKEN.MINUS_ASSIGN, TOKEN.MUL_ASSIGN, TOKEN.DIV_ASSIGN)
    if op then
        local opChar = op.value:sub(1,1) -- "+", "-", "*", "/"
        local rhs    = self:parseExpression()
        return {
            kind  = "Assign",
            target = expr,
            value  = { kind = "BinaryOp", op = opChar, left = expr, right = rhs },
        }
    end
    if self:match(TOKEN.ASSIGN) then
        local value = self:parseExpression()
        return { kind = "Assign", target = expr, value = value }
    end
    return { kind = "ExprStmt", expr = expr }
end

-- ── Expressions ──────────────────────────────────────────────────────────────

function Parser:parseExpression()
    return self:parseOr()
end

function Parser:parseOr()
    local left = self:parseAnd()
    while self:match(TOKEN.OR) do
        local right = self:parseAnd()
        left = { kind = "BinaryOp", op = "or", left = left, right = right }
    end
    return left
end

function Parser:parseAnd()
    local left = self:parseEquality()
    while self:match(TOKEN.AND) do
        local right = self:parseEquality()
        left = { kind = "BinaryOp", op = "and", left = left, right = right }
    end
    return left
end

function Parser:parseEquality()
    local left = self:parseComparison()
    while true do
        local op = self:match(TOKEN.EQ, TOKEN.NEQ)
        if not op then break end
        local right = self:parseComparison()
        left = { kind = "BinaryOp", op = op.value, left = left, right = right }
    end
    return left
end

function Parser:parseComparison()
    local left = self:parseRange()
    while true do
        local op = self:match(TOKEN.LT, TOKEN.GT, TOKEN.LTE, TOKEN.GTE)
        if not op then break end
        local right = self:parseRange()
        left = { kind = "BinaryOp", op = op.value, left = left, right = right }
    end
    return left
end

function Parser:parseRange()
    local left = self:parseConcat()
    if self:match(TOKEN.RANGE) then
        local right = self:parseConcat()
        return { kind = "Range", from = left, to = right }
    end
    return left
end

function Parser:parseConcat()
    local left = self:parseAddSub()
    while self:match(TOKEN.CONCAT) do
        local right = self:parseAddSub()
        left = { kind = "BinaryOp", op = "..", left = left, right = right }
    end
    return left
end

function Parser:parseAddSub()
    local left = self:parseMulDiv()
    while true do
        local op = self:match(TOKEN.PLUS, TOKEN.MINUS)
        if not op then break end
        local right = self:parseMulDiv()
        left = { kind = "BinaryOp", op = op.value, left = left, right = right }
    end
    return left
end

function Parser:parseMulDiv()
    local left = self:parseUnary()
    while true do
        local op = self:match(TOKEN.STAR, TOKEN.SLASH, TOKEN.PERCENT)
        if not op then break end
        local right = self:parseUnary()
        left = { kind = "BinaryOp", op = op.value, left = left, right = right }
    end
    return left
end

function Parser:parseUnary()
    if self:match(TOKEN.NOT) then
        return { kind = "UnaryOp", op = "not", operand = self:parseUnary() }
    end
    if self:match(TOKEN.MINUS) then
        return { kind = "UnaryOp", op = "-", operand = self:parseUnary() }
    end
    if self:match("HASH") then
        return { kind = "UnaryOp", op = "#", operand = self:parseUnary() }
    end
    return self:parseCall()
end

function Parser:parseCall()
    local expr = self:parsePrimary()
    while true do
        if self:match(TOKEN.LPAREN) then
            local args = {}
            if not self:check(TOKEN.RPAREN) then
                repeat
                    args[#args+1] = self:parseExpression()
                until not self:match(TOKEN.COMMA)
            end
            self:expect(TOKEN.RPAREN)
            expr = { kind = "Call", callee = expr, args = args }
        elseif self:match(TOKEN.DOT) then
            local field = self:expect(TOKEN.IDENT).value
            expr = { kind = "FieldAccess", object = expr, field = field }
        elseif self:match(TOKEN.LBRACKET) then
            local index = self:parseExpression()
            self:expect(TOKEN.RBRACKET)
            expr = { kind = "IndexAccess", object = expr, index = index }
        elseif self:match(TOKEN.COLON) then
            local method = self:expect(TOKEN.IDENT).value
            self:expect(TOKEN.LPAREN)
            local args = {}
            if not self:check(TOKEN.RPAREN) then
                repeat
                    args[#args+1] = self:parseExpression()
                until not self:match(TOKEN.COMMA)
            end
            self:expect(TOKEN.RPAREN)
            expr = { kind = "MethodCall", object = expr, method = method, args = args }
        else
            break
        end
    end
    return expr
end

function Parser:parsePrimary()
    local t = self:peek()

    if t.kind == TOKEN.NUMBER then
        self:advance()
        return { kind = "Literal", type = "number", value = t.value }
    elseif t.kind == TOKEN.STRING then
        self:advance()
        return { kind = "Literal", type = "string", value = t.value }
    elseif t.kind == "FSTRING" then
        self:advance()
        return { kind = "FString", parts = t.value }
    elseif t.kind == TOKEN.TRUE then
        self:advance()
        return { kind = "Literal", type = "bool", value = true }
    elseif t.kind == TOKEN.FALSE then
        self:advance()
        return { kind = "Literal", type = "bool", value = false }
    elseif t.kind == TOKEN.NIL then
        self:advance()
        return { kind = "Literal", type = "nil", value = nil }
    elseif t.kind == TOKEN.SELF then
        self:advance()
        return { kind = "Self" }
    elseif t.kind == TOKEN.IDENT then
        self:advance()
        -- Arrow function: name => expr  or  (params) => expr
        if self:check(TOKEN.FAT_ARROW) then
            self:advance()
            local body = self:parseLambdaBody()
            return { kind = "Lambda", params = { t.value }, body = body }
        end
        return { kind = "Identifier", name = t.value }
    elseif t.kind == TOKEN.LPAREN then
        self:advance()
        -- Arrow function: (params) => expr
        if self:check(TOKEN.RPAREN) then
            self:advance()
            if self:match(TOKEN.FAT_ARROW) then
                local body = self:parseLambdaBody()
                return { kind = "Lambda", params = {}, body = body }
            end
            return { kind = "Literal", type = "nil", value = nil }
        end
        local expr = self:parseExpression()
        -- check if this is a param list
        if self:match(TOKEN.COMMA) then
            local params = { expr.name or tostring(expr) }
            repeat
                params[#params+1] = self:expect(TOKEN.IDENT).value
            until not self:match(TOKEN.COMMA)
            self:expect(TOKEN.RPAREN)
            self:expect(TOKEN.FAT_ARROW)
            local body = self:parseLambdaBody()
            return { kind = "Lambda", params = params, body = body }
        end
        self:expect(TOKEN.RPAREN)
        if self:match(TOKEN.FAT_ARROW) then
            local param = expr.name
            local body  = self:parseLambdaBody()
            return { kind = "Lambda", params = { param }, body = body }
        end
        return expr
    elseif t.kind == TOKEN.LBRACKET then
        self:advance()
        local items = {}
        if not self:check(TOKEN.RBRACKET) then
            repeat
                items[#items+1] = self:parseExpression()
            until not self:match(TOKEN.COMMA)
        end
        self:expect(TOKEN.RBRACKET)
        return { kind = "ArrayLiteral", items = items }
    elseif t.kind == TOKEN.LBRACE then
        return self:parseTableLiteral()
    elseif t.kind == TOKEN.FN then
        -- anonymous fn
        self:advance()
        self:expect(TOKEN.LPAREN)
        local params = {}
        if not self:check(TOKEN.RPAREN) then
            repeat
                params[#params+1] = self:expect(TOKEN.IDENT).value
            until not self:match(TOKEN.COMMA)
        end
        self:expect(TOKEN.RPAREN)
        local body = self:parseBlock()
        return { kind = "Lambda", params = params, body = body }
    elseif t.kind == TOKEN.NEW then
        self:advance()
        local className = self:expect(TOKEN.IDENT).value
        self:expect(TOKEN.LPAREN)
        local args = {}
        if not self:check(TOKEN.RPAREN) then
            repeat
                args[#args+1] = self:parseExpression()
            until not self:match(TOKEN.COMMA)
        end
        self:expect(TOKEN.RPAREN)
        return { kind = "NewExpr", class = className, args = args }
    end

    error(("Crystal Parse Error [line %d col %d]: unexpected token %s ('%s')")
        :format(t.line, t.col, t.kind, tostring(t.value)))
end

function Parser:parseTableLiteral()
    self:expect(TOKEN.LBRACE)
    local fields = {}
    while not self:check(TOKEN.RBRACE) and not self:check(TOKEN.EOF) do
        local key, value
        if self:check(TOKEN.IDENT) and self:peek(1).kind == TOKEN.COLON then
            key = self:advance().value
            self:expect(TOKEN.COLON)
            value = self:parseExpression()
        elseif self:check(TOKEN.LBRACKET) then
            self:advance()
            key   = self:parseExpression()
            self:expect(TOKEN.RBRACKET)
            self:expect(TOKEN.COLON)
            value = self:parseExpression()
        else
            value = self:parseExpression()
        end
        fields[#fields+1] = { key = key, value = value }
        self:match(TOKEN.COMMA)
        self:match(TOKEN.SEMICOLON)
    end
    self:expect(TOKEN.RBRACE)
    return { kind = "TableLiteral", fields = fields }
end

function Parser:parseLambdaBody()
    if self:check(TOKEN.LBRACE) then
        return self:parseBlock()
    end
    local expr = self:parseExpression()
    return { kind = "Block", body = {{ kind = "Return", value = expr }} }
end

return Parser
