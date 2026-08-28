-- Crystal Language Compiler
-- Compiles AST nodes into Crystal Bytecode (CBC)

local OP = {
    -- Stack
    LOAD_CONST   = 0x01,
    LOAD_LOCAL   = 0x02,
    STORE_LOCAL  = 0x03,
    LOAD_GLOBAL  = 0x04,
    STORE_GLOBAL = 0x05,
    LOAD_UPVAL   = 0x06,
    STORE_UPVAL  = 0x07,
    POP          = 0x08,
    DUP          = 0x09,

    -- Arithmetic
    ADD = 0x10,
    SUB = 0x11,
    MUL = 0x12,
    DIV = 0x13,
    MOD = 0x14,
    NEG = 0x15,
    POW = 0x16,

    -- String
    CONCAT = 0x18,
    LEN    = 0x19,

    -- Comparison
    EQ  = 0x20,
    NEQ = 0x21,
    LT  = 0x22,
    GT  = 0x23,
    LTE = 0x24,
    GTE = 0x25,

    -- Logic
    AND_JUMP  = 0x28,
    OR_JUMP   = 0x29,
    NOT       = 0x2A,

    -- Control flow
    JUMP         = 0x30,
    JUMP_FALSE   = 0x31,
    JUMP_TRUE    = 0x32,

    -- Functions
    MAKE_CLOSURE = 0x38,
    CALL         = 0x39,
    RETURN       = 0x3A,
    TAIL_CALL    = 0x3B,

    -- Tables
    NEW_TABLE    = 0x40,
    SET_FIELD    = 0x41,
    GET_FIELD    = 0x42,
    SET_INDEX    = 0x43,
    GET_INDEX    = 0x44,
    SET_SELF     = 0x45,
    GET_SELF     = 0x46,

    -- Iterators
    MAKE_RANGE   = 0x50,
    FOR_PREP     = 0x51,
    FOR_STEP     = 0x52,
    ITER_NEXT    = 0x53,

    -- Misc
    PUSH_NIL   = 0x60,
    PUSH_TRUE  = 0x61,
    PUSH_FALSE = 0x62,
    NOP        = 0x63,

    -- Exception handling
    TRY_BEGIN  = 0x70,
    TRY_END    = 0x71,
    THROW      = 0x72,
}

-- Chunk: the compiled unit for a function
local function newChunk(name)
    return {
        name      = name or "?",
        code      = {},    -- list of { op, arg1, arg2, ... }
        constants = {},    -- constant pool
        locals    = {},    -- local variable names (index = slot)
        upvalues  = {},    -- upvalue descriptors
        children  = {},    -- nested function chunks
        sourceMap = {},    -- instruction index -> source line
        paramCount = 0,
    }
end

local Compiler = {}
Compiler.__index = Compiler

function Compiler.new()
    return setmetatable({
        chunkStack = {},
        current    = nil,
    }, Compiler)
end

function Compiler:pushChunk(name)
    local c = newChunk(name)
    self.chunkStack[#self.chunkStack+1] = c
    self.current = c
    return c
end

function Compiler:popChunk()
    local c = self.current
    self.chunkStack[#self.chunkStack] = nil
    self.current = self.chunkStack[#self.chunkStack]
    return c
end

-- ── Helpers ──────────────────────────────────────────────────────────────────

function Compiler:emit(op, ...)
    local instr = { op = op }
    local args = {...}
    for i, v in ipairs(args) do instr[i] = v end
    self.current.code[#self.current.code+1] = instr
    return #self.current.code
end

function Compiler:emitJump(op)
    return self:emit(op, 0) -- placeholder
end

function Compiler:patchJump(idx)
    self.current.code[idx][1] = #self.current.code + 1
end

function Compiler:addConst(v)
    local consts = self.current.constants
    for i, c in ipairs(consts) do
        if c == v then return i end
    end
    consts[#consts+1] = v
    return #consts
end

function Compiler:resolveLocal(name)
    local locals = self.current.locals
    for i = #locals, 1, -1 do
        if locals[i] == name then return i end
    end
    return nil
end

function Compiler:defineLocal(name)
    local locals = self.current.locals
    locals[#locals+1] = name
    return #locals
end

-- ── Compile entry point ──────────────────────────────────────────────────────

function Compiler:compile(ast)
    self:pushChunk("__main__")
    self:compileBlock(ast.body)
    self:emit(OP.PUSH_NIL)
    self:emit(OP.RETURN)
    local chunk = self:popChunk()
    chunk.checksum = self:computeChecksum(chunk)
    return chunk
end

function Compiler:computeChecksum(chunk)
    local sum = 0
    for _, instr in ipairs(chunk.code) do
        sum = (sum + instr.op) % 0xFFFFFFFF
        for i = 1, #instr do
            if type(instr[i]) == "number" then
                sum = (sum + instr[i]) % 0xFFFFFFFF
            end
        end
    end
    for _, c in ipairs(chunk.constants) do
        if type(c) == "number" then
            sum = (sum + c) % 0xFFFFFFFF
        elseif type(c) == "string" then
            for i = 1, #c do
                sum = (sum + c:byte(i)) % 0xFFFFFFFF
            end
        end
    end
    return sum
end

-- ── Statement compilation ─────────────────────────────────────────────────────

function Compiler:compileBlock(stmts)
    for _, stmt in ipairs(stmts) do
        self:compileStmt(stmt)
    end
end

function Compiler:compileStmt(node)
    local k = node.kind

    if k == "VarDecl" then
        if node.value then
            self:compileExpr(node.value)
        else
            self:emit(OP.PUSH_NIL)
        end
        local idx = self:defineLocal(node.name)
        self:emit(OP.STORE_LOCAL, idx)

    elseif k == "Assign" then
        self:compileExpr(node.value)
        self:compileAssignTarget(node.target)

    elseif k == "FnDecl" then
        local fnChunk = self:compileFn(node)
        self.current.children[#self.current.children+1] = fnChunk
        local cidx = #self.current.children
        self:emit(OP.MAKE_CLOSURE, cidx)
        if node.name then
            local idx = self:defineLocal(node.name)
            self:emit(OP.STORE_LOCAL, idx)
        end

    elseif k == "ClassDecl" then
        self:compileClassDecl(node)

    elseif k == "Return" then
        if node.value then
            self:compileExpr(node.value)
        else
            self:emit(OP.PUSH_NIL)
        end
        self:emit(OP.RETURN)

    elseif k == "If" then
        self:compileIf(node)

    elseif k == "While" then
        self:compileWhile(node)

    elseif k == "For" then
        self:compileFor(node)

    elseif k == "Break" then
        -- handled by loop compilation via break patch list
        self:emit(OP.JUMP, 0) -- patched later
        local breaks = self.current._breaks
        if breaks then breaks[#breaks+1] = #self.current.code end

    elseif k == "Continue" then
        self:emit(OP.JUMP, 0)
        local continues = self.current._continues
        if continues then continues[#continues+1] = #self.current.code end

    elseif k == "Block" then
        self:compileBlock(node.body)

    elseif k == "Try" then
        self:compileTry(node)

    elseif k == "Match" then
        self:compileMatch(node)

    elseif k == "Import" then
        local cidx = self:addConst(node.path)
        self:emit(OP.LOAD_CONST, cidx)
        self:emit(OP.LOAD_GLOBAL, self:addConst("__crystal_import__"))
        self:emit(OP.CALL, 1)
        self:emit(OP.STORE_GLOBAL, self:addConst(node.path:match("([^/]+)$") or node.path))

    elseif k == "ExprStmt" then
        self:compileExpr(node.expr)
        self:emit(OP.POP)

    else
        error("Crystal Compiler: unknown statement kind: " .. tostring(k))
    end
end

function Compiler:compileAssignTarget(target)
    if target.kind == "Identifier" then
        local idx = self:resolveLocal(target.name)
        if idx then
            self:emit(OP.STORE_LOCAL, idx)
        else
            self:emit(OP.STORE_GLOBAL, self:addConst(target.name))
        end
    elseif target.kind == "FieldAccess" then
        self:compileExpr(target.object)
        self:emit(OP.SET_FIELD, self:addConst(target.field))
    elseif target.kind == "IndexAccess" then
        self:compileExpr(target.object)
        self:compileExpr(target.index)
        self:emit(OP.SET_INDEX)
    elseif target.kind == "Self" then
        self:emit(OP.SET_SELF)
    end
end

function Compiler:compileIf(node)
    self:compileExpr(node.cond)
    local jmpFalse = self:emitJump(OP.JUMP_FALSE)
    self:compileBlock(node.thenBlock.body)
    if node.elseBlock then
        local jmpEnd = self:emitJump(OP.JUMP)
        self:patchJump(jmpFalse)
        self:compileBlock(node.elseBlock.body)
        self:patchJump(jmpEnd)
    else
        self:patchJump(jmpFalse)
    end
end

function Compiler:compileWhile(node)
    local loopStart = #self.current.code + 1
    self.current._breaks    = self.current._breaks or {}
    self.current._continues = self.current._continues or {}
    local prevBreaks    = self.current._breaks
    local prevContinues = self.current._continues
    self.current._breaks    = {}
    self.current._continues = {}

    self:compileExpr(node.cond)
    local jmpEnd = self:emitJump(OP.JUMP_FALSE)

    self:compileBlock(node.body.body)
    self:emit(OP.JUMP, loopStart)

    local afterLoop = #self.current.code + 1
    self:patchJump(jmpEnd)

    for _, bi in ipairs(self.current._breaks) do
        self.current.code[bi][1] = afterLoop
    end
    for _, ci in ipairs(self.current._continues) do
        self.current.code[ci][1] = loopStart
    end
    self.current._breaks    = prevBreaks
    self.current._continues = prevContinues
end

function Compiler:compileFor(node)
    -- Range iteration: for i in start..end
    -- Generic iteration: for item in table/array
    local iter = node.iter
    if iter.kind == "Range" then
        -- Numeric for
        self:compileExpr(iter.from)
        self:compileExpr(iter.to)
        self:emit(OP.MAKE_RANGE)
        local rangeLocal = self:defineLocal("__range__" .. node.var)
        self:emit(OP.STORE_LOCAL, rangeLocal)

        local loopStart = #self.current.code + 1
        self:emit(OP.LOAD_LOCAL, rangeLocal)
        self:emit(OP.FOR_PREP)
        local jmpEnd = self:emitJump(OP.JUMP_FALSE)

        -- Load current value into var
        self:emit(OP.LOAD_LOCAL, rangeLocal)
        self:emit(OP.FOR_STEP)
        local varIdx = self:defineLocal(node.var)
        self:emit(OP.STORE_LOCAL, varIdx)

        self.current._breaks    = {}
        self.current._continues = {}
        self:compileBlock(node.body.body)
        self:emit(OP.JUMP, loopStart)

        local afterLoop = #self.current.code + 1
        self:patchJump(jmpEnd)
        for _, bi in ipairs(self.current._breaks)    do self.current.code[bi][1] = afterLoop end
        for _, ci in ipairs(self.current._continues) do self.current.code[ci][1] = loopStart end
    else
        -- Generic iteration (table/array)
        self:compileExpr(iter)
        local iterLocal = self:defineLocal("__iter__" .. node.var)
        self:emit(OP.STORE_LOCAL, iterLocal)
        local idxLocal = self:defineLocal("__idx__" .. node.var)
        self:emit(OP.PUSH_NIL)
        self:emit(OP.STORE_LOCAL, idxLocal)

        local loopStart = #self.current.code + 1
        self:emit(OP.LOAD_LOCAL, iterLocal)
        self:emit(OP.LOAD_LOCAL, idxLocal)
        self:emit(OP.ITER_NEXT)
        local jmpEnd = self:emitJump(OP.JUMP_FALSE)

        local varIdx = self:defineLocal(node.var)
        self:emit(OP.STORE_LOCAL, varIdx)
        -- also update idx
        self:emit(OP.STORE_LOCAL, idxLocal)

        self.current._breaks    = {}
        self.current._continues = {}
        self:compileBlock(node.body.body)
        self:emit(OP.JUMP, loopStart)

        local afterLoop = #self.current.code + 1
        self:patchJump(jmpEnd)
        for _, bi in ipairs(self.current._breaks)    do self.current.code[bi][1] = afterLoop end
        for _, ci in ipairs(self.current._continues) do self.current.code[ci][1] = loopStart end
    end
end

function Compiler:compileTry(node)
    local tryBegin = self:emit(OP.TRY_BEGIN, 0) -- arg = catch address
    self:compileBlock(node.tryBlock.body)
    self:emit(OP.TRY_END)
    local jmpEnd = self:emitJump(OP.JUMP)

    local catchAddr = #self.current.code + 1
    self.current.code[tryBegin][1] = catchAddr

    if node.catchBlock then
        local errIdx = self:defineLocal(node.catchVar or "__err__")
        self:emit(OP.STORE_LOCAL, errIdx)
        self:compileBlock(node.catchBlock.body)
    else
        self:emit(OP.POP)
    end
    self:patchJump(jmpEnd)
end

function Compiler:compileMatch(node)
    self:compileExpr(node.subject)
    local subjectLocal = self:defineLocal("__match__")
    self:emit(OP.STORE_LOCAL, subjectLocal)

    local endJumps = {}
    for i, arm in ipairs(node.arms) do
        if arm.pattern.kind == "Wildcard" then
            self:compileStmt(arm.action)
            if i < #node.arms then
                endJumps[#endJumps+1] = self:emitJump(OP.JUMP)
            end
        else
            self:emit(OP.LOAD_LOCAL, subjectLocal)
            self:compileExpr(arm.pattern)
            self:emit(OP.EQ)
            local skip = self:emitJump(OP.JUMP_FALSE)
            self:compileStmt(arm.action)
            endJumps[#endJumps+1] = self:emitJump(OP.JUMP)
            self:patchJump(skip)
        end
    end
    local endAddr = #self.current.code + 1
    for _, j in ipairs(endJumps) do
        self.current.code[j][1] = endAddr
    end
end

function Compiler:compileFn(node)
    self:pushChunk(node.name or "<lambda>")
    self.current.paramCount = #node.params
    for _, p in ipairs(node.params) do
        self:defineLocal(p)
    end
    self:compileBlock(node.body.body)
    self:emit(OP.PUSH_NIL)
    self:emit(OP.RETURN)
    local chunk = self:popChunk()
    chunk.checksum = self:computeChecksum(chunk)
    return chunk
end

function Compiler:compileClassDecl(node)
    -- Build class table
    self:emit(OP.NEW_TABLE)
    local classLocal = self:defineLocal(node.name)
    self:emit(OP.DUP)
    self:emit(OP.STORE_LOCAL, classLocal)

    -- Store superclass ref if any
    if node.super then
        local sidx = self:resolveLocal(node.super)
        if sidx then
            self:emit(OP.LOAD_LOCAL, sidx)
        else
            self:emit(OP.LOAD_GLOBAL, self:addConst(node.super))
        end
        self:emit(OP.LOAD_LOCAL, classLocal)
        self:emit(OP.SET_FIELD, self:addConst("__super__"))
    end

    -- Compile each method
    for _, method in ipairs(node.methods) do
        local fnChunk = self:compileFn(method)
        self.current.children[#self.current.children+1] = fnChunk
        local cidx = #self.current.children
        self:emit(OP.LOAD_LOCAL, classLocal)
        self:emit(OP.MAKE_CLOSURE, cidx)
        self:emit(OP.SET_FIELD, self:addConst(method.name))
    end

    -- Mark as class
    self:emit(OP.LOAD_LOCAL, classLocal)
    self:emit(OP.LOAD_CONST, self:addConst(node.name))
    self:emit(OP.SET_FIELD, self:addConst("__name__"))
end

-- ── Expression compilation ────────────────────────────────────────────────────

function Compiler:compileExpr(node)
    local k = node.kind

    if k == "Literal" then
        if node.type == "nil" then
            self:emit(OP.PUSH_NIL)
        elseif node.type == "bool" then
            if node.value then self:emit(OP.PUSH_TRUE) else self:emit(OP.PUSH_FALSE) end
        else
            self:emit(OP.LOAD_CONST, self:addConst(node.value))
        end

    elseif k == "Identifier" then
        local idx = self:resolveLocal(node.name)
        if idx then
            self:emit(OP.LOAD_LOCAL, idx)
        else
            self:emit(OP.LOAD_GLOBAL, self:addConst(node.name))
        end

    elseif k == "Self" then
        local idx = self:resolveLocal("self")
        if idx then
            self:emit(OP.LOAD_LOCAL, idx)
        else
            self:emit(OP.LOAD_GLOBAL, self:addConst("self"))
        end

    elseif k == "FString" then
        local count = 0
        for _, part in ipairs(node.parts) do
            if part.kind == "literal" then
                self:emit(OP.LOAD_CONST, self:addConst(part.value))
            else
                -- Compile embedded expression (re-lex and re-parse)
                local lexerModule = require(script.Parent.lexer)
                local Parser      = require(script.Parent.parser)
                local subLexer    = lexerModule.Lexer.new(part.value)
                local subTokens   = subLexer:tokenize()
                local subParser   = Parser.new(subTokens)
                local subExpr     = subParser:parseExpression()
                self:compileExpr(subExpr)
                -- Convert to string
                self:emit(OP.LOAD_GLOBAL, self:addConst("tostring"))
                self:emit(OP.CALL, 1)
            end
            count = count + 1
        end
        -- Concat all parts
        for _ = 1, count - 1 do
            self:emit(OP.CONCAT)
        end

    elseif k == "BinaryOp" then
        local op = node.op
        if op == "and" then
            self:compileExpr(node.left)
            local jmp = self:emitJump(OP.AND_JUMP)
            self:compileExpr(node.right)
            self:patchJump(jmp)
        elseif op == "or" then
            self:compileExpr(node.left)
            local jmp = self:emitJump(OP.OR_JUMP)
            self:compileExpr(node.right)
            self:patchJump(jmp)
        else
            self:compileExpr(node.left)
            self:compileExpr(node.right)
            local opMap = {
                ["+"] = OP.ADD, ["-"] = OP.SUB, ["*"] = OP.MUL,
                ["/"] = OP.DIV, ["%"] = OP.MOD,
                ["=="] = OP.EQ, ["!="] = OP.NEQ,
                ["<"]  = OP.LT, [">"]  = OP.GT,
                ["<="] = OP.LTE, [">="] = OP.GTE,
                [".."] = OP.CONCAT,
            }
            local opCode = opMap[op]
            if opCode then self:emit(opCode) else error("Unknown op: " .. op) end
        end

    elseif k == "UnaryOp" then
        self:compileExpr(node.operand)
        if node.op == "-" then self:emit(OP.NEG)
        elseif node.op == "not" then self:emit(OP.NOT)
        elseif node.op == "#" then self:emit(OP.LEN) end

    elseif k == "Call" then
        for _, arg in ipairs(node.args) do
            self:compileExpr(arg)
        end
        self:compileExpr(node.callee)
        self:emit(OP.CALL, #node.args)

    elseif k == "MethodCall" then
        self:compileExpr(node.object)
        self:emit(OP.DUP) -- push self
        for _, arg in ipairs(node.args) do
            self:compileExpr(arg)
        end
        self:emit(OP.GET_FIELD, self:addConst(node.method))
        self:emit(OP.CALL, #node.args + 1)

    elseif k == "FieldAccess" then
        self:compileExpr(node.object)
        self:emit(OP.GET_FIELD, self:addConst(node.field))

    elseif k == "IndexAccess" then
        self:compileExpr(node.object)
        self:compileExpr(node.index)
        self:emit(OP.GET_INDEX)

    elseif k == "ArrayLiteral" then
        self:emit(OP.NEW_TABLE)
        for i, item in ipairs(node.items) do
            self:emit(OP.DUP)
            self:compileExpr(item)
            self:emit(OP.LOAD_CONST, self:addConst(i))
            self:emit(OP.SET_INDEX)
        end

    elseif k == "TableLiteral" then
        self:emit(OP.NEW_TABLE)
        for _, field in ipairs(node.fields) do
            self:emit(OP.DUP)
            self:compileExpr(field.value)
            if field.key then
                if type(field.key) == "string" then
                    self:emit(OP.SET_FIELD, self:addConst(field.key))
                else
                    self:compileExpr(field.key)
                    self:emit(OP.SET_INDEX)
                end
            else
                -- auto-index
                self:emit(OP.LOAD_CONST, self:addConst(#self.current.code))
                self:emit(OP.SET_INDEX)
            end
        end

    elseif k == "Lambda" then
        local fnChunk = self:compileFn({ name = "<lambda>", params = node.params, body = node.body })
        self.current.children[#self.current.children+1] = fnChunk
        self:emit(OP.MAKE_CLOSURE, #self.current.children)

    elseif k == "Range" then
        self:compileExpr(node.from)
        self:compileExpr(node.to)
        self:emit(OP.MAKE_RANGE)

    elseif k == "NewExpr" then
        -- Load class, call init
        local cidx = self:resolveLocal(node.class)
        if cidx then
            self:emit(OP.LOAD_LOCAL, cidx)
        else
            self:emit(OP.LOAD_GLOBAL, self:addConst(node.class))
        end
        for _, arg in ipairs(node.args) do
            self:compileExpr(arg)
        end
        self:emit(OP.LOAD_GLOBAL, self:addConst("__crystal_new__"))
        self:emit(OP.CALL, #node.args + 1)

    else
        error("Crystal Compiler: unknown expression kind: " .. tostring(k))
    end
end

return { Compiler = Compiler, OP = OP }
