-- Crystal Language VM
-- Custom register-less stack machine that executes Crystal Bytecode (CBC)
-- Includes anti-tamper integrity verification before execution

local compilerModule = require(script.Parent.compiler)
local OP = compilerModule.OP

-- ── Anti-Tamper ──────────────────────────────────────────────────────────────

local AntiTamper = {}

function AntiTamper.verify(chunk)
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
    if sum ~= chunk.checksum then
        error("[Crystal VM] TAMPER DETECTED: bytecode integrity check failed! "
            .. "Expected " .. tostring(chunk.checksum) .. " got " .. tostring(sum))
    end
    return true
end

function AntiTamper.seal(chunk)
    -- Recursively verify all child chunks too
    AntiTamper.verify(chunk)
    for _, child in ipairs(chunk.children) do
        AntiTamper.seal(child)
    end
end

-- ── VM Call Frame ─────────────────────────────────────────────────────────────

local function newFrame(chunk, base, returnTo)
    return {
        chunk    = chunk,
        ip       = 1,           -- instruction pointer
        base     = base,        -- stack base for locals
        returnTo = returnTo,    -- instruction to return to (in caller)
    }
end

-- ── Closure ──────────────────────────────────────────────────────────────────

local function newClosure(chunk, upvalues)
    return {
        __type__  = "closure",
        chunk     = chunk,
        upvalues  = upvalues or {},
    }
end

-- ── Range iterator ───────────────────────────────────────────────────────────

local function newRange(from, to)
    return {
        __type__ = "range",
        current  = from - 1,
        to       = to,
    }
end

-- ── VM ───────────────────────────────────────────────────────────────────────

local VM = {}
VM.__index = VM

function VM.new(globals)
    local vm = setmetatable({
        stack    = {},
        sp       = 0,   -- stack pointer (top index)
        frames   = {},
        fp       = 0,   -- frame pointer
        globals  = globals or {},
        handlers = {},  -- try/catch handler stack
    }, VM)

    -- Inject built-ins
    vm:injectBuiltins()
    return vm
end

function VM:push(v)
    self.sp = self.sp + 1
    self.stack[self.sp] = v
end

function VM:pop()
    local v = self.stack[self.sp]
    self.stack[self.sp] = nil
    self.sp = self.sp - 1
    return v
end

function VM:peek(offset)
    return self.stack[self.sp - (offset or 0)]
end

function VM:pushFrame(chunk, base)
    self.fp = self.fp + 1
    self.frames[self.fp] = newFrame(chunk, base, nil)
    return self.frames[self.fp]
end

function VM:popFrame()
    local f = self.frames[self.fp]
    self.frames[self.fp] = nil
    self.fp = self.fp - 1
    return f
end

function VM:currentFrame()
    return self.frames[self.fp]
end

function VM:injectBuiltins()
    local g = self.globals
    g["print"]   = print
    g["tostring"] = tostring
    g["tonumber"] = tonumber
    g["type"]    = type
    g["error"]   = error
    g["assert"]  = assert
    g["pairs"]   = pairs
    g["ipairs"]  = ipairs
    g["select"]  = select
    g["unpack"]  = table.unpack or unpack
    g["math"]    = math
    g["string"]  = string
    g["table"]   = table
    g["os"]      = { clock = os.clock, time = os.time }

    -- Crystal new() helper: creates a class instance
    g["__crystal_new__"] = function(class, ...)
        local instance = setmetatable({}, {
            __index = class,
            __type__ = class.__name__ or "Object",
        })
        if class.init then
            class.init(instance, ...)
        end
        return instance
    end

    -- Crystal import stub (can be overridden by host)
    g["__crystal_import__"] = function(path)
        error("Crystal: import '" .. tostring(path) .. "' not resolved by host")
    end

    -- typeof operator
    g["typeof"] = function(v)
        local mt = getmetatable(v)
        if mt and mt.__type__ then return mt.__type__ end
        return type(v)
    end
end

-- ── Execute ───────────────────────────────────────────────────────────────────

function VM:execute(chunk)
    -- Anti-tamper check before ANY execution
    AntiTamper.seal(chunk)

    self:pushFrame(chunk, self.sp + 1)
    return self:run()
end

function VM:run()
    while self.fp > 0 do
        local frame = self:currentFrame()
        local chunk = frame.chunk
        local code  = chunk.code

        if frame.ip > #code then
            -- Implicit return nil
            self:popFrame()
            self:push(nil)
            if self.fp == 0 then break end
        else
            local instr = code[frame.ip]
            frame.ip = frame.ip + 1

            local ok, err = pcall(self.step, self, frame, chunk, instr)
            if not ok then
                -- Try to find a handler
                if #self.handlers > 0 then
                    local handler = self.handlers[#self.handlers]
                    self.handlers[#self.handlers] = nil
                    -- Unwind frames until handler's frame depth
                    while self.fp > handler.fp do
                        self:popFrame()
                    end
                    -- Restore stack pointer
                    self.sp = handler.sp
                    -- Push error onto stack
                    self:push(tostring(err))
                    -- Jump to catch address
                    frame = self:currentFrame()
                    frame.ip = handler.catchAddr
                else
                    error(err, 0)
                end
            end
        end
    end

    return self:pop()
end

function VM:step(frame, chunk, instr)
    local op = instr.op

    -- ── Stack ops ────────────────────────────────────────────────────────────
    if op == OP.PUSH_NIL   then self:push(nil)
    elseif op == OP.PUSH_TRUE  then self:push(true)
    elseif op == OP.PUSH_FALSE then self:push(false)
    elseif op == OP.POP        then self:pop()
    elseif op == OP.DUP        then self:push(self:peek())

    elseif op == OP.LOAD_CONST then
        self:push(chunk.constants[instr[1]])

    elseif op == OP.LOAD_LOCAL then
        self:push(self.stack[frame.base + instr[1] - 1])

    elseif op == OP.STORE_LOCAL then
        local slot = frame.base + instr[1] - 1
        self.stack[slot] = self:pop()
        if slot > self.sp then self.sp = slot end

    elseif op == OP.LOAD_GLOBAL then
        local name = chunk.constants[instr[1]]
        self:push(self.globals[name])

    elseif op == OP.STORE_GLOBAL then
        local name = chunk.constants[instr[1]]
        self.globals[name] = self:pop()

    -- ── Arithmetic ───────────────────────────────────────────────────────────
    elseif op == OP.ADD then
        local b, a = self:pop(), self:pop()
        self:push(a + b)
    elseif op == OP.SUB then
        local b, a = self:pop(), self:pop()
        self:push(a - b)
    elseif op == OP.MUL then
        local b, a = self:pop(), self:pop()
        self:push(a * b)
    elseif op == OP.DIV then
        local b, a = self:pop(), self:pop()
        if b == 0 then error("Crystal VM: division by zero") end
        self:push(a / b)
    elseif op == OP.MOD then
        local b, a = self:pop(), self:pop()
        self:push(a % b)
    elseif op == OP.NEG then
        self:push(-self:pop())
    elseif op == OP.POW then
        local b, a = self:pop(), self:pop()
        self:push(a ^ b)

    -- ── String ───────────────────────────────────────────────────────────────
    elseif op == OP.CONCAT then
        local b, a = self:pop(), self:pop()
        self:push(tostring(a) .. tostring(b))
    elseif op == OP.LEN then
        self:push(#self:pop())

    -- ── Comparison ───────────────────────────────────────────────────────────
    elseif op == OP.EQ  then local b,a = self:pop(),self:pop(); self:push(a == b)
    elseif op == OP.NEQ then local b,a = self:pop(),self:pop(); self:push(a ~= b)
    elseif op == OP.LT  then local b,a = self:pop(),self:pop(); self:push(a < b)
    elseif op == OP.GT  then local b,a = self:pop(),self:pop(); self:push(a > b)
    elseif op == OP.LTE then local b,a = self:pop(),self:pop(); self:push(a <= b)
    elseif op == OP.GTE then local b,a = self:pop(),self:pop(); self:push(a >= b)

    -- ── Logic ────────────────────────────────────────────────────────────────
    elseif op == OP.NOT then
        self:push(not self:pop())
    elseif op == OP.AND_JUMP then
        local v = self:peek()
        if not v then
            frame.ip = instr[1]
        else
            self:pop()
        end
    elseif op == OP.OR_JUMP then
        local v = self:peek()
        if v then
            frame.ip = instr[1]
        else
            self:pop()
        end

    -- ── Control flow ─────────────────────────────────────────────────────────
    elseif op == OP.JUMP then
        frame.ip = instr[1]
    elseif op == OP.JUMP_FALSE then
        if not self:pop() then frame.ip = instr[1] end
    elseif op == OP.JUMP_TRUE then
        if self:pop() then frame.ip = instr[1] end

    -- ── Functions ─────────────────────────────────────────────────────────────
    elseif op == OP.MAKE_CLOSURE then
        local childChunk = chunk.children[instr[1]]
        self:push(newClosure(childChunk, {}))

    elseif op == OP.CALL then
        local nargs = instr[1]
        local fn    = self:pop()
        local args  = {}
        for i = nargs, 1, -1 do
            args[i] = self:pop()
        end

        if type(fn) == "function" then
            -- Native Lua function
            local results = table.pack(fn(table.unpack(args)))
            self:push(results[1]) -- single return value
        elseif type(fn) == "table" and fn.__type__ == "closure" then
            -- Crystal closure: push new frame
            local base = self.sp + 1
            -- Push args as locals
            for _, a in ipairs(args) do
                self:push(a)
            end
            -- Ensure enough local slots
            for i = #args + 1, fn.chunk.paramCount do
                self:push(nil)
            end
            self:pushFrame(fn.chunk, base)
        else
            error("Crystal VM: attempt to call a non-function value: " .. type(fn))
        end

    elseif op == OP.RETURN then
        local retVal = self:pop()
        local frame2 = self:popFrame()
        -- Clean up locals from this frame
        self.sp = frame2.base - 1
        self:push(retVal)
        if self.fp == 0 then return end

    -- ── Tables ───────────────────────────────────────────────────────────────
    elseif op == OP.NEW_TABLE then
        self:push({})

    elseif op == OP.SET_FIELD then
        local val  = self:pop()
        local tbl  = self:pop()
        local name = chunk.constants[instr[1]]
        if type(tbl) ~= "table" then
            error("Crystal VM: SET_FIELD on non-table: " .. type(tbl))
        end
        tbl[name] = val

    elseif op == OP.GET_FIELD then
        local tbl  = self:pop()
        local name = chunk.constants[instr[1]]
        if type(tbl) == "table" then
            self:push(tbl[name])
        elseif type(tbl) == "string" then
            self:push(string[name])
        else
            self:push(nil)
        end

    elseif op == OP.SET_INDEX then
        local key = self:pop()
        local val = self:pop()
        local tbl = self:pop()
        tbl[key]  = val

    elseif op == OP.GET_INDEX then
        local key = self:pop()
        local tbl = self:pop()
        if type(tbl) == "table" then
            self:push(tbl[key])
        elseif type(tbl) == "string" then
            self:push(tbl:sub(key, key))
        else
            self:push(nil)
        end

    -- ── Range / iteration ─────────────────────────────────────────────────────
    elseif op == OP.MAKE_RANGE then
        local to   = self:pop()
        local from = self:pop()
        self:push(newRange(from, to))

    elseif op == OP.FOR_PREP then
        local range = self:peek()
        self:push(range.current < range.to)

    elseif op == OP.FOR_STEP then
        local range = self:pop()
        range.current = range.current + 1
        self:push(range)
        self:push(range.current)

    elseif op == OP.ITER_NEXT then
        local idx = self:pop()
        local tbl = self:pop()
        local nextKey, nextVal = next(tbl, idx)
        if nextKey == nil then
            self:push(false)
        else
            self:push(nextVal)
            self:push(nextKey)
            self:push(true)
        end

    -- ── Exception handling ────────────────────────────────────────────────────
    elseif op == OP.TRY_BEGIN then
        self.handlers[#self.handlers+1] = {
            catchAddr = instr[1],
            fp        = self.fp,
            sp        = self.sp,
        }

    elseif op == OP.TRY_END then
        self.handlers[#self.handlers] = nil

    elseif op == OP.THROW then
        error(self:pop())

    elseif op == OP.NOP then
        -- nothing

    else
        error(("Crystal VM: unknown opcode 0x%02X at ip=%d"):format(op, frame.ip - 1))
    end
end

-- ── Disassembler (for debugging) ─────────────────────────────────────────────

local OP_NAMES = {}
for name, val in pairs(OP) do OP_NAMES[val] = name end

local function disassemble(chunk, indent)
    indent = indent or ""
    local out = {}
    out[#out+1] = indent .. "=== Chunk: " .. (chunk.name or "?") .. " ==="
    out[#out+1] = indent .. "Constants: " .. #chunk.constants
    for i, c in ipairs(chunk.constants) do
        out[#out+1] = indent .. ("  [%d] %s"):format(i, tostring(c))
    end
    out[#out+1] = indent .. "Locals: " .. table.concat(chunk.locals, ", ")
    out[#out+1] = indent .. "Code (" .. #chunk.code .. " instructions):"
    for i, instr in ipairs(chunk.code) do
        local args = {}
        for j = 1, #instr do args[#args+1] = tostring(instr[j]) end
        out[#out+1] = indent .. ("  %04d  %-16s %s"):format(
            i, OP_NAMES[instr.op] or ("0x%02X"):format(instr.op),
            table.concat(args, " ")
        )
    end
    out[#out+1] = indent .. ("Checksum: 0x%08X"):format(chunk.checksum or 0)
    for _, child in ipairs(chunk.children) do
        out[#out+1] = disassemble(child, indent .. "  ")
    end
    return table.concat(out, "\n")
end

return { VM = VM, AntiTamper = AntiTamper, disassemble = disassemble }
