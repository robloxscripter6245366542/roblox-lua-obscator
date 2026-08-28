# Crystal Language Reference

Crystal is a clean, modern scripting language that compiles to custom bytecode
and runs on a sandboxed VM inside Roblox Lua. It has built-in anti-tamper
protection, a glass-morphism IDE, and a richer syntax than raw Lua.

---

## Variables

```crystal
let x = 10          -- mutable variable
const PI = 3.14     -- immutable constant
let name = "Alice"
```

## Strings & Interpolation

```crystal
let greeting = f"Hello, {name}! You are {x} years old."
```

## Functions

```crystal
fn add(a, b) {
    return a + b
}

-- Arrow / lambda
let double = (x) => x * 2
let square = x => x * x
```

## Classes

```crystal
class Animal {
    fn init(name, sound) {
        self.name  = name
        self.sound = sound
    }
    fn speak() {
        print(f"{self.name} says {self.sound}!")
    }
}

class Dog extends Animal {
    fn init(name) {
        self.name  = name
        self.sound = "woof"
    }
    fn fetch(item) {
        print(f"{self.name} fetches the {item}!")
    }
}

let rex = new Dog("Rex")
rex:speak()
rex:fetch("ball")
```

## Control Flow

```crystal
if score >= 90 {
    print("A grade")
} elif score >= 80 {
    print("B grade")
} else {
    print("Try harder")
}
```

## Loops

```crystal
-- Numeric range (inclusive)
for i in 1..10 {
    print(i)
}

-- Generic iteration
let fruits = ["apple", "banana", "cherry"]
for fruit in fruits {
    print(fruit)
}

-- While loop
while hp > 0 {
    hp -= 10
}

-- Break / Continue
for i in 1..100 {
    if i == 50 { break }
    if i % 2 == 0 { continue }
    print(i)
}
```

## Pattern Matching

```crystal
match command {
    "run"   => print("Running!")
    "stop"  => print("Stopping!")
    "help"  => showHelp()
    _       => print(f"Unknown command: {command}")
}
```

## Error Handling

```crystal
try {
    let result = riskyOp()
    print(result)
} catch (err) {
    print(f"Caught error: {err}")
}
```

## Tables / Objects

```crystal
let player = {
    name:   "Alice",
    health: 100,
    level:  1,
}

player.health -= 20
print(player.name)
```

## Arrays

```crystal
let nums = [1, 2, 3, 4, 5]
let doubled = Array.map(nums, x => x * 2)
```

## Imports

```crystal
import "utils"
import "stdlib"
```

---

## VM Architecture

```
Source (.cr)
    │
    ▼
 Lexer  ──── Tokens
    │
    ▼
 Parser ──── AST
    │
    ▼
Compiler ──── Bytecode Chunk (CBC)
                │
                ▼
         Anti-Tamper
         Checksum Verify ── FAIL → Error
                │ PASS
                ▼
            Crystal VM
          (stack machine)
                │
                ▼
            Result
```

### Bytecode Opcodes

| Opcode         | Description                          |
|---------------|--------------------------------------|
| LOAD_CONST    | Push constant from pool              |
| LOAD_LOCAL    | Push local variable                  |
| STORE_LOCAL   | Pop → local variable                 |
| LOAD_GLOBAL   | Push global                          |
| STORE_GLOBAL  | Pop → global                         |
| ADD/SUB/MUL   | Arithmetic                           |
| DIV/MOD/NEG   | Arithmetic                           |
| EQ/NEQ/LT/GT  | Comparison → boolean                 |
| AND_JUMP      | Short-circuit AND                    |
| OR_JUMP       | Short-circuit OR                     |
| JUMP          | Unconditional branch                 |
| JUMP_FALSE    | Branch if stack top is falsy         |
| MAKE_CLOSURE  | Create closure from child chunk      |
| CALL          | Call function with N args            |
| RETURN        | Return from function                 |
| NEW_TABLE     | Create empty table                   |
| GET/SET_FIELD | Table field access                   |
| GET/SET_INDEX | Table index access                   |
| MAKE_RANGE    | Create range iterator                |
| FOR_PREP      | Check range has next value           |
| FOR_STEP      | Advance range, push current          |
| ITER_NEXT     | Generic table iteration              |
| TRY_BEGIN     | Register exception handler           |
| TRY_END       | Deregister exception handler         |
| CONCAT        | String concatenation                 |
| LEN           | String/table length                  |

### Anti-Tamper

Every compiled chunk carries a **checksum** computed over all opcodes and
constants. Before any execution, the VM's `AntiTamper.seal()` function
recursively walks all chunks and verifies checksums. If any byte has been
modified, execution is halted with a tamper-detected error.

---

## IDE Glass UI

The `crystal/ui/editor.lua` LocalScript provides a **glass-morphism IDE**
inside Roblox with:
- Live code editor with line numbers
- ▶ Run / ■ Stop / ⌫ Clear / ⚙ Bytecode buttons  
- Anti-tamper status badge
- Output console (with RichText color coding)
- Bytecode disassembler view
- File browser sidebar
- Draggable window
- Entrance animation with blur
