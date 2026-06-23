"""Language-specific knowledge base."""

LANGUAGES = {
    # ─── Python ──────────────────────────────────────────────────────────────
    "python": {
        "title": "Python",
        "overview": (
            "Python is a beginner-friendly, general-purpose language known for its\n"
            "clean, readable syntax. It's used for web development, data science,\n"
            "AI/ML, automation, and more.\n\n"
            "Creator: Guido van Rossum (1991)\n"
            "Philosophy: 'There should be one obvious way to do it' (Zen of Python)"
        ),
        "syntax_guide": """
# ── Variables ────────────────────────────────────
name = "Alice"
age  = 25
pi   = 3.14
is_active = True

# ── String formatting ────────────────────────────
greeting = f"Hello, {name}! You are {age} years old."
old_way  = "Hello, %s!" % name
format_  = "Hello, {}!".format(name)

# ── Lists ────────────────────────────────────────
fruits = ["apple", "banana", "cherry"]
fruits.append("date")
fruits.remove("banana")
first  = fruits[0]
last   = fruits[-1]
sliced = fruits[1:3]   # ['banana', 'cherry']

# ── Dictionaries ─────────────────────────────────
person = {"name": "Bob", "age": 30}
person["city"] = "NYC"
name = person.get("name", "Unknown")   # safe get

# ── Conditionals ─────────────────────────────────
if age >= 18:
    print("Adult")
elif age >= 13:
    print("Teen")
else:
    print("Child")

# ── Loops ────────────────────────────────────────
for i in range(5):        # 0 1 2 3 4
    print(i)

for fruit in fruits:
    print(fruit)

while age < 30:
    age += 1

# ── Functions ────────────────────────────────────
def greet(name, greeting="Hello"):
    return f"{greeting}, {name}!"

result = greet("Alice")
result2 = greet("Bob", greeting="Hi")

# ── Lambda (anonymous function) ──────────────────
square = lambda x: x ** 2

# ── List comprehension ───────────────────────────
squares = [x**2 for x in range(10)]
evens   = [x for x in range(20) if x % 2 == 0]

# ── Classes ──────────────────────────────────────
class Animal:
    def __init__(self, name, sound):
        self.name  = name
        self.sound = sound

    def speak(self):
        return f"{self.name} says {self.sound}"

class Dog(Animal):          # inheritance
    def fetch(self):
        return f"{self.name} fetches the ball!"

rex = Dog("Rex", "Woof")
print(rex.speak())          # Rex says Woof
print(rex.fetch())          # Rex fetches the ball!

# ── Error handling ───────────────────────────────
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print(f"Error: {e}")
except (TypeError, ValueError):
    print("Type or value error")
finally:
    print("Always runs")

# ── File I/O ─────────────────────────────────────
with open("file.txt", "r") as f:
    content = f.read()

with open("output.txt", "w") as f:
    f.write("Hello, file!")

# ── Useful built-ins ─────────────────────────────
len([1,2,3])        # 3
type(42)            # <class 'int'>
isinstance(42, int) # True
range(1, 11)        # 1 to 10
enumerate(fruits)   # (index, value) pairs
zip(list1, list2)   # pair elements
map(fn, iterable)   # apply fn to each
filter(fn, iterable)# keep where fn is True
sorted(iterable)    # sorted copy
reversed(iterable)  # reversed iterator
min(), max(), sum()
""",
        "tips": [
            "Use virtual environments: python -m venv venv",
            "Follow PEP 8 style guide for clean code.",
            "Use f-strings (f'...') for string formatting.",
            "List comprehensions are more Pythonic than map/filter.",
            "Use 'with' for file operations – handles closing automatically.",
            "Type hints (def fn(x: int) -> str:) improve readability.",
        ],
        "popular_libraries": {
            "requests":  "HTTP requests",
            "numpy":     "numerical computing",
            "pandas":    "data analysis",
            "matplotlib":"data visualisation",
            "flask":     "lightweight web framework",
            "django":    "full-stack web framework",
            "fastapi":   "modern async API framework",
            "pytest":    "testing",
            "scikit-learn": "machine learning",
            "tensorflow":   "deep learning",
        },
    },

    # ─── JavaScript ──────────────────────────────────────────────────────────
    "javascript": {
        "title": "JavaScript",
        "overview": (
            "JavaScript is the language of the web. It runs in every browser and,\n"
            "with Node.js, on servers too. It's event-driven and supports\n"
            "object-oriented, functional, and imperative styles.\n\n"
            "Creator: Brendan Eich (1995) at Netscape"
        ),
        "syntax_guide": """
// ── Variables ────────────────────────────────────
let   name = "Alice";   // block-scoped, reassignable
const pi   = 3.14;      // block-scoped, constant
var   old  = "avoid";   // function-scoped, avoid using

// ── Template literals ────────────────────────────
const greeting = `Hello, ${name}! Pi is ${pi}.`;

// ── Arrays ───────────────────────────────────────
const fruits = ["apple", "banana", "cherry"];
fruits.push("date");
fruits.pop();                    // remove last
fruits.splice(1, 1);             // remove at index 1
const first = fruits[0];
const slice = fruits.slice(1,3);

// ── Objects ──────────────────────────────────────
const person = { name: "Bob", age: 30 };
person.city = "NYC";
const { name: pName, age } = person;  // destructuring

// ── Conditionals ─────────────────────────────────
if (age >= 18) {
    console.log("Adult");
} else if (age >= 13) {
    console.log("Teen");
} else {
    console.log("Child");
}

// Ternary
const label = age >= 18 ? "Adult" : "Minor";

// ── Loops ────────────────────────────────────────
for (let i = 0; i < 5; i++) console.log(i);
for (const fruit of fruits) console.log(fruit);
for (const key in person) console.log(key, person[key]);

fruits.forEach((f, i) => console.log(i, f));

// ── Functions ────────────────────────────────────
function greet(name, greeting = "Hello") {
    return `${greeting}, ${name}!`;
}

// Arrow function
const square = (x) => x * x;
const add    = (a, b) => a + b;

// ── Array methods ────────────────────────────────
const nums    = [1, 2, 3, 4, 5];
const doubled = nums.map(n => n * 2);
const evens   = nums.filter(n => n % 2 === 0);
const sum     = nums.reduce((acc, n) => acc + n, 0);
const found   = nums.find(n => n > 3);       // 4
const has4    = nums.includes(4);             // true

// ── Classes ──────────────────────────────────────
class Animal {
    constructor(name, sound) {
        this.name  = name;
        this.sound = sound;
    }
    speak() {
        return `${this.name} says ${this.sound}`;
    }
}

class Dog extends Animal {
    fetch() { return `${this.name} fetches the ball!`; }
}

const rex = new Dog("Rex", "Woof");

// ── Promises & async/await ───────────────────────
async function fetchData(url) {
    try {
        const response = await fetch(url);
        const data     = await response.json();
        return data;
    } catch (error) {
        console.error("Error:", error);
    }
}

// ── Modules (ES Modules) ─────────────────────────
// export.js
export const PI = 3.14;
export default function greet(name) { return `Hi ${name}`; }

// import.js
import greet, { PI } from './export.js';

// ── Spread / rest ────────────────────────────────
const arr1 = [1, 2];
const arr2 = [...arr1, 3, 4];       // [1,2,3,4]
function sum(...nums) { return nums.reduce((a,b)=>a+b,0); }
""",
        "tips": [
            "Use const by default; let when you need to reassign; never var.",
            "=== checks value AND type; == does type coercion (avoid ==).",
            "async/await is cleaner than raw Promises.",
            "Use Array methods (map, filter, reduce) instead of for loops.",
            "Check for null/undefined before accessing properties.",
            "Use optional chaining: user?.address?.city",
        ],
        "popular_libraries": {
            "React":      "UI component library (Facebook)",
            "Vue":        "progressive UI framework",
            "Angular":    "full MVC framework (Google)",
            "Node.js":    "server-side JavaScript runtime",
            "Express":    "minimal Node.js web framework",
            "Next.js":    "React framework with SSR",
            "TypeScript": "typed superset of JavaScript",
            "Jest":       "testing framework",
            "axios":      "HTTP client",
            "lodash":     "utility functions",
        },
    },

    # ─── Lua ─────────────────────────────────────────────────────────────────
    "lua": {
        "title": "Lua",
        "overview": (
            "Lua is a lightweight, fast scripting language popular in game\n"
            "development. It's used in Roblox, World of Warcraft, Nginx, and\n"
            "many game engines as an embedded scripting language.\n\n"
            "Creator: PUC-Rio team, Brazil (1993)"
        ),
        "syntax_guide": """
-- ── Variables ─────────────────────────────────────
local name   = "Alice"         -- local (recommended)
age          = 25              -- global (avoid if possible)
local pi     = 3.14
local active = true

-- ── Strings ───────────────────────────────────────
local greeting = "Hello, " .. name .. "!"   -- concatenation
local len = #name                            -- string length

-- ── Tables (arrays AND dicts) ─────────────────────
-- As array (1-indexed!):
local fruits = {"apple", "banana", "cherry"}
fruits[1]                        -- "apple"
table.insert(fruits, "date")     -- append
table.remove(fruits, 2)          -- remove index 2
#fruits                          -- length

-- As dictionary:
local person = {name = "Bob", age = 30}
person.name                      -- "Bob"
person["age"]                    -- 30
person.city = "NYC"              -- add key

-- ── Conditionals ─────────────────────────────────
if age >= 18 then
    print("Adult")
elseif age >= 13 then
    print("Teen")
else
    print("Child")
end

-- ── Loops ────────────────────────────────────────
for i = 1, 5 do              -- numeric for
    print(i)
end

for i = 10, 1, -1 do        -- countdown
    print(i)
end

for i, v in ipairs(fruits) do  -- iterate array
    print(i, v)
end

for k, v in pairs(person) do   -- iterate dict
    print(k, v)
end

local count = 0
while count < 5 do
    count = count + 1
end

repeat                       -- do-while equivalent
    count = count - 1
until count == 0

-- ── Functions ────────────────────────────────────
local function greet(name, greeting)
    greeting = greeting or "Hello"   -- default value trick
    return greeting .. ", " .. name .. "!"
end

-- Multiple return values (Lua superpower!)
local function minmax(t)
    local min, max = t[1], t[1]
    for _, v in ipairs(t) do
        if v < min then min = v end
        if v > max then max = v end
    end
    return min, max
end
local lo, hi = minmax({3,1,4,1,5})

-- ── Closures ─────────────────────────────────────
local function counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end
local c = counter()
c()  -- 1
c()  -- 2

-- ── OOP with metatables ───────────────────────────
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
    return setmetatable({name=name, sound=sound}, Animal)
end

function Animal:speak()    -- colon = self sugar
    return self.name .. " says " .. self.sound
end

local rex = Animal.new("Rex", "Woof")
rex:speak()   -- "Rex says Woof"

-- ── Error handling ───────────────────────────────
local ok, err = pcall(function()
    error("something went wrong")
end)
if not ok then print("Caught:", err) end

-- ── Roblox-specific ───────────────────────────────
-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Events
Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " joined!")
end)

-- Wait
task.wait(1)           -- preferred over wait()
task.delay(2, fn)      -- call fn after 2 seconds
task.spawn(fn)         -- run fn in new thread
""",
        "tips": [
            "Always use 'local' for variables – globals are slow and pollute scope.",
            "Tables are the only data structure in Lua – they do everything.",
            "Use 'or' for default values: local x = arg or 'default'",
            "ipairs iterates arrays in order; pairs iterates all keys.",
            "Lua tables are 1-indexed, not 0-indexed like most languages.",
            "pcall() safely calls a function and catches errors.",
            "Prefer task.wait() over wait() in Roblox (more accurate).",
        ],
        "popular_libraries": {
            "Luau":     "Roblox's typed superset of Lua",
            "LuaSocket":"networking",
            "LÖVE":     "2D game framework",
            "OpenResty":"Nginx + Lua web platform",
        },
    },

    # ─── Java ────────────────────────────────────────────────────────────────
    "java": {
        "title": "Java",
        "overview": (
            "Java is a strongly-typed, object-oriented language that runs on the\n"
            "Java Virtual Machine (JVM). Famous for 'write once, run anywhere'.\n"
            "Used in enterprise software, Android apps, and backend services.\n\n"
            "Creator: James Gosling at Sun Microsystems (1995)"
        ),
        "syntax_guide": """
// ── Variables & types ─────────────────────────────
int    age    = 25;
double pi     = 3.14;
String name   = "Alice";
boolean active = true;
var     x     = 42;     // type inferred (Java 10+)

// ── Arrays ───────────────────────────────────────
int[] nums   = {1, 2, 3, 4, 5};
int   first  = nums[0];
int   length = nums.length;

// ArrayList (dynamic array)
import java.util.ArrayList;
ArrayList<String> fruits = new ArrayList<>();
fruits.add("apple");
fruits.remove("apple");
fruits.get(0);
fruits.size();

// ── Conditionals ─────────────────────────────────
if (age >= 18) {
    System.out.println("Adult");
} else if (age >= 13) {
    System.out.println("Teen");
} else {
    System.out.println("Child");
}

// ── Loops ────────────────────────────────────────
for (int i = 0; i < 5; i++) System.out.println(i);
for (String fruit : fruits) System.out.println(fruit);  // enhanced for

// ── Functions (methods) ───────────────────────────
public static String greet(String name) {
    return "Hello, " + name + "!";
}

// ── Classes ──────────────────────────────────────
public class Animal {
    private String name;
    private String sound;

    public Animal(String name, String sound) {
        this.name  = name;
        this.sound = sound;
    }

    public String speak() {
        return name + " says " + sound;
    }
}

public class Dog extends Animal {
    public Dog(String name) {
        super(name, "Woof");
    }
    public String fetch() {
        return getName() + " fetches!";
    }
}

// ── Exception handling ────────────────────────────
try {
    int result = 10 / 0;
} catch (ArithmeticException e) {
    System.err.println("Error: " + e.getMessage());
} finally {
    System.out.println("Always runs");
}

// ── Main entry point ─────────────────────────────
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
""",
        "tips": [
            "Java is verbose but very explicit – great for large teams.",
            "Every file must have a class with the same name as the file.",
            "Use ArrayList instead of arrays when size is unknown.",
            "Interfaces define contracts; abstract classes share code.",
            "Use 'final' to prevent reassignment (like const).",
        ],
    },

    # ─── C++ ─────────────────────────────────────────────────────────────────
    "c++": {
        "title": "C++",
        "overview": (
            "C++ is a powerful, high-performance language used in game engines,\n"
            "operating systems, embedded systems, and performance-critical software.\n"
            "It gives direct control over memory and hardware.\n\n"
            "Creator: Bjarne Stroustrup (1985)"
        ),
        "syntax_guide": """
#include <iostream>
#include <string>
#include <vector>
using namespace std;

// ── Variables ─────────────────────────────────────
int    age    = 25;
double pi     = 3.14;
string name   = "Alice";
bool   active = true;
auto   x      = 42;    // type inferred

// ── Vectors (dynamic arrays) ──────────────────────
vector<int> nums = {1, 2, 3, 4, 5};
nums.push_back(6);
nums.pop_back();
nums[0];          // access
nums.size();      // length

// ── Conditionals ─────────────────────────────────
if (age >= 18) {
    cout << "Adult" << endl;
} else if (age >= 13) {
    cout << "Teen" << endl;
} else {
    cout << "Child" << endl;
}

// ── Loops ────────────────────────────────────────
for (int i = 0; i < 5; i++) cout << i << endl;
for (auto& n : nums) cout << n << endl;  // range-based

// ── Functions ────────────────────────────────────
string greet(string name, string greeting = "Hello") {
    return greeting + ", " + name + "!";
}

// ── Classes ──────────────────────────────────────
class Animal {
private:
    string name, sound;
public:
    Animal(string name, string sound) : name(name), sound(sound) {}
    virtual string speak() {
        return name + " says " + sound;
    }
    virtual ~Animal() {}   // virtual destructor
};

class Dog : public Animal {
public:
    Dog(string name) : Animal(name, "Woof") {}
    string fetch() { return "Fetching!"; }
};

// ── Pointers & references ─────────────────────────
int  val = 42;
int* ptr = &val;     // pointer to val
int& ref = val;      // reference (alias)
*ptr = 100;          // dereference

// ── Memory management ─────────────────────────────
int* heap = new int(42);   // allocate on heap
delete heap;               // free memory (must do!)
// Prefer smart pointers (C++11+):
#include <memory>
auto sp = make_shared<Dog>("Rex");

// ── Main ─────────────────────────────────────────
int main() {
    cout << "Hello, World!" << endl;
    return 0;
}
""",
        "tips": [
            "Always free memory with delete if you used new (or use smart pointers).",
            "Prefer references over pointers when possible.",
            "Use const wherever you don't intend to modify a value.",
            "Include guards (#pragma once) prevent double-inclusion.",
            "Modern C++ (11/14/17/20) is much nicer than old C++.",
        ],
    },

    # ─── Rust ────────────────────────────────────────────────────────────────
    "rust": {
        "title": "Rust",
        "overview": (
            "Rust is a systems programming language focused on safety, speed, and\n"
            "concurrency. It prevents memory bugs at compile time through its\n"
            "ownership system – no garbage collector needed.\n\n"
            "Creator: Graydon Hoare, Mozilla (2010)"
        ),
        "syntax_guide": """
// ── Variables ─────────────────────────────────────
let x = 5;          // immutable by default!
let mut y = 5;      // mutable
let z: i32 = 5;     // explicit type

// ── Types ─────────────────────────────────────────
// Integer: i8 i16 i32 i64 i128 u8 u16 u32 u64 u128 usize
// Float:   f32 f64
// Bool:    bool
// Char:    char (Unicode)
// String:  String (owned) vs &str (borrowed)

// ── Functions ────────────────────────────────────
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)   // last expression = return value
}

// ── Control flow ─────────────────────────────────
let label = if x > 0 { "positive" } else { "non-positive" };

for i in 0..5 { println!("{}", i); }         // 0 to 4
for n in [1,2,3].iter() { println!("{}", n); }

// ── Ownership ────────────────────────────────────
let s1 = String::from("hello");
let s2 = s1;      // s1 is MOVED; s1 is no longer valid
// let s3 = s1;  // ERROR: value used after move

let s1 = String::from("hello");
let s2 = s1.clone();   // explicit deep copy

// Borrowing:
fn print_len(s: &String) { println!("{}", s.len()); }
print_len(&s1);   // pass reference; s1 still owned by caller

// ── Structs ───────────────────────────────────────
struct Point { x: f64, y: f64 }
impl Point {
    fn new(x: f64, y: f64) -> Self { Point { x, y } }
    fn distance(&self, other: &Point) -> f64 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }
}

// ── Enums & pattern matching ──────────────────────
enum Shape { Circle(f64), Rectangle(f64, f64) }
let area = match shape {
    Shape::Circle(r)         => std::f64::consts::PI * r * r,
    Shape::Rectangle(w, h)  => w * h,
};

// ── Option & Result ───────────────────────────────
fn divide(a: f64, b: f64) -> Option<f64> {
    if b == 0.0 { None } else { Some(a / b) }
}
let result = divide(10.0, 2.0).unwrap_or(0.0);

// ── Error handling ────────────────────────────────
use std::fs;
fn read_file(path: &str) -> Result<String, std::io::Error> {
    fs::read_to_string(path)
}
// The ? operator propagates errors:
fn read_file2(path: &str) -> Result<String, std::io::Error> {
    let content = fs::read_to_string(path)?;
    Ok(content)
}
""",
        "tips": [
            "Embrace the borrow checker – it's teaching you safe memory management.",
            "Use cargo new to create projects; cargo build/run/test.",
            "Option<T> replaces null; Result<T,E> replaces exceptions.",
            "The ? operator propagates errors cleanly.",
            "Rust has no null, no dangling pointers, no data races.",
        ],
    },

    # ─── TypeScript ──────────────────────────────────────────────────────────
    "typescript": {
        "title": "TypeScript",
        "overview": (
            "TypeScript is JavaScript with static type checking. It compiles down\n"
            "to JavaScript and catches type errors at compile time instead of runtime.\n\n"
            "Creator: Anders Hejlsberg at Microsoft (2012)"
        ),
        "syntax_guide": """
// ── Types ─────────────────────────────────────────
let name:    string  = "Alice";
let age:     number  = 25;
let active:  boolean = true;
let nothing: null    = null;

// Union types
let id: string | number = "abc";
id = 123;  // also valid

// ── Interfaces ───────────────────────────────────
interface User {
    id:      number;
    name:    string;
    email?:  string;   // optional
}

const user: User = { id: 1, name: "Alice" };

// ── Type aliases ─────────────────────────────────
type Point  = { x: number; y: number };
type Status = "active" | "inactive" | "pending";

// ── Generics ─────────────────────────────────────
function identity<T>(value: T): T { return value; }
const num    = identity<number>(42);
const strVal = identity("hello");   // inferred

// ── Arrays & tuples ──────────────────────────────
const nums:   number[]       = [1, 2, 3];
const pair:   [string, number] = ["age", 25];  // tuple

// ── Functions ────────────────────────────────────
function greet(name: string, greeting: string = "Hello"): string {
    return `${greeting}, ${name}!`;
}

const arrow = (x: number, y: number): number => x + y;

// ── Classes ──────────────────────────────────────
class Animal {
    constructor(
        private name:  string,   // shorthand for this.name = name
        private sound: string
    ) {}
    speak(): string { return `${this.name} says ${this.sound}`; }
}

// ── Enums ────────────────────────────────────────
enum Direction { Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT" }
let dir: Direction = Direction.Up;

// ── Utility types ─────────────────────────────────
type PartialUser = Partial<User>;         // all fields optional
type ReadonlyUser = Readonly<User>;       // all fields readonly
type PickedUser   = Pick<User, "id"|"name">; // select fields
""",
        "tips": [
            "Start with 'strict: true' in tsconfig.json for maximum safety.",
            "Use interface for object shapes; type for aliases and unions.",
            "Generics make code reusable without sacrificing type safety.",
            "as unknown as T is a type escape hatch – avoid if possible.",
            "Run tsc --watch for continuous compilation.",
        ],
    },

    # ─── SQL ─────────────────────────────────────────────────────────────────
    "sql": {
        "title": "SQL (Structured Query Language)",
        "overview": (
            "SQL is the language for managing relational databases.\n"
            "Used with PostgreSQL, MySQL, SQLite, SQL Server, and more.\n"
            "Every app that stores data likely uses SQL somewhere."
        ),
        "syntax_guide": """
-- ── Create a table ───────────────────────────────
CREATE TABLE users (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT    NOT NULL,
    email    TEXT    UNIQUE NOT NULL,
    age      INTEGER,
    created  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ── Insert data ───────────────────────────────────
INSERT INTO users (name, email, age) VALUES ('Alice', 'alice@ex.com', 25);

-- ── Query data ───────────────────────────────────
SELECT * FROM users;                               -- all rows
SELECT name, email FROM users;                     -- specific columns
SELECT * FROM users WHERE age > 20;               -- filter
SELECT * FROM users WHERE name LIKE 'A%';         -- pattern match
SELECT * FROM users ORDER BY age DESC;            -- sort
SELECT * FROM users LIMIT 10 OFFSET 20;           -- pagination

-- ── Aggregation ──────────────────────────────────
SELECT COUNT(*) FROM users;
SELECT AVG(age), MIN(age), MAX(age) FROM users;
SELECT age, COUNT(*) as cnt FROM users GROUP BY age;
SELECT age, COUNT(*) FROM users GROUP BY age HAVING COUNT(*) > 1;

-- ── Update data ───────────────────────────────────
UPDATE users SET age = 26 WHERE name = 'Alice';

-- ── Delete data ───────────────────────────────────
DELETE FROM users WHERE id = 5;

-- ── Joins (connecting tables) ─────────────────────
SELECT u.name, o.product
FROM   users  u
JOIN   orders o ON o.user_id = u.id;     -- INNER JOIN (default)

SELECT u.name, o.product
FROM   users  u
LEFT JOIN orders o ON o.user_id = u.id;  -- all users, even without orders

-- ── Indexes (make queries faster) ────────────────
CREATE INDEX idx_users_email ON users(email);

-- ── Transactions ─────────────────────────────────
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;   -- or ROLLBACK to undo
""",
        "tips": [
            "Always use WHERE with UPDATE and DELETE or you'll affect all rows!",
            "Use indexes on columns you frequently filter or join on.",
            "Transactions ensure all-or-nothing operations (ACID).",
            "Avoid SELECT * in production – list only needed columns.",
            "Use prepared statements to prevent SQL injection.",
        ],
    },

    # ─── HTML/CSS ─────────────────────────────────────────────────────────────
    "html": {
        "title": "HTML (HyperText Markup Language)",
        "overview": (
            "HTML is the structure of web pages. It defines what content is on\n"
            "the page using elements (tags). CSS styles it; JavaScript makes it\n"
            "interactive."
        ),
        "syntax_guide": """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Page</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <!-- Headings -->
    <h1>Main Title</h1>
    <h2>Subtitle</h2>

    <!-- Paragraph -->
    <p>This is a paragraph with <strong>bold</strong> and <em>italic</em> text.</p>

    <!-- Links & images -->
    <a href="https://example.com" target="_blank">Click me</a>
    <img src="photo.jpg" alt="Description of image">

    <!-- Lists -->
    <ul>  <!-- unordered -->
        <li>Item one</li>
        <li>Item two</li>
    </ul>
    <ol>  <!-- ordered -->
        <li>First</li>
        <li>Second</li>
    </ol>

    <!-- Form -->
    <form action="/submit" method="POST">
        <label for="name">Name:</label>
        <input type="text" id="name" name="name" required>
        <input type="email" name="email" placeholder="Email">
        <button type="submit">Submit</button>
    </form>

    <!-- Semantic elements -->
    <header>  <nav>  <main>  <section>  <article>  <aside>  <footer>

    <!-- Div & span (generic containers) -->
    <div class="card">          <!-- block element -->
        <span class="badge">New</span>  <!-- inline element -->
    </div>

    <script src="app.js"></script>
</body>
</html>
""",
        "tips": [
            "Always include alt text on images for accessibility.",
            "Use semantic tags (header, nav, main) not just divs.",
            "Validate your HTML at validator.w3.org",
            "Every form input should have a corresponding label.",
        ],
    },

    "css": {
        "title": "CSS (Cascading Style Sheets)",
        "overview": "CSS styles HTML elements – colour, layout, typography, animation.",
        "syntax_guide": """
/* ── Selectors ─────────────────────────────────── */
p          { }    /* element */
.card      { }    /* class */
#header    { }    /* id */
a:hover    { }    /* pseudo-class */
p::before  { }    /* pseudo-element */
div > p    { }    /* direct child */
div p      { }    /* any descendant */

/* ── Box model ──────────────────────────────────── */
.box {
    width:   200px;
    height:  100px;
    padding: 10px;          /* space inside */
    border:  2px solid #333;
    margin:  20px;          /* space outside */
    box-sizing: border-box; /* include padding in width */
}

/* ── Flexbox ────────────────────────────────────── */
.container {
    display:         flex;
    flex-direction:  row;        /* row | column */
    justify-content: center;     /* main axis */
    align-items:     center;     /* cross axis */
    gap:             16px;
    flex-wrap:       wrap;
}

/* ── Grid ───────────────────────────────────────── */
.grid {
    display:               grid;
    grid-template-columns: repeat(3, 1fr);
    gap:                   16px;
}

/* ── Typography ─────────────────────────────────── */
body {
    font-family: 'Inter', sans-serif;
    font-size:   16px;
    line-height: 1.5;
    color:       #333;
}

/* ── Colours ────────────────────────────────────── */
color:            #ff6b6b;       /* hex */
color:            rgb(255,107,107);
color:            hsl(0, 100%, 71%);
background-color: rgba(0,0,0,0.5);  /* with opacity */

/* ── Responsive (media queries) ─────────────────── */
@media (max-width: 768px) {
    .container { flex-direction: column; }
}

/* ── Transitions & animations ───────────────────── */
.btn { transition: background 0.3s ease; }
.btn:hover { background: #0056b3; }

@keyframes spin {
    from { transform: rotate(0deg); }
    to   { transform: rotate(360deg); }
}
.spinner { animation: spin 1s linear infinite; }

/* ── CSS variables ──────────────────────────────── */
:root {
    --primary:   #007bff;
    --font-size: 16px;
}
.btn { background: var(--primary); }
""",
        "tips": [
            "Use Flexbox for 1D layout (rows or columns); Grid for 2D.",
            "box-sizing: border-box makes sizing much more predictable.",
            "CSS variables (--name) make themes easy to change.",
            "Mobile-first: write styles for small screens, then expand.",
            "Avoid !important – it's a sign of specificity problems.",
        ],
    },

    # ─── Go ──────────────────────────────────────────────────────────────────
    "go": {
        "title": "Go (Golang)",
        "overview": (
            "Go is a fast, compiled language from Google known for simplicity\n"
            "and excellent built-in concurrency. Used in cloud infrastructure,\n"
            "APIs, CLIs, and DevOps tools.\n\n"
            "Creator: Rob Pike, Ken Thompson, Robert Griesemer at Google (2009)"
        ),
        "syntax_guide": """
package main

import (
    "fmt"
    "errors"
)

// ── Variables ─────────────────────────────────────
var name string = "Alice"
age := 25              // shorthand (inferred)
const PI = 3.14

// ── Functions ────────────────────────────────────
// Multiple return values!
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

result, err := divide(10, 2)
if err != nil {
    fmt.Println("Error:", err)
}

// ── Structs ───────────────────────────────────────
type Animal struct {
    Name  string
    Sound string
}

func (a Animal) Speak() string {
    return fmt.Sprintf("%s says %s", a.Name, a.Sound)
}

rex := Animal{Name: "Rex", Sound: "Woof"}
fmt.Println(rex.Speak())

// ── Slices ────────────────────────────────────────
nums := []int{1, 2, 3, 4, 5}
nums = append(nums, 6)
sub  := nums[1:4]    // [2,3,4]
len(nums); cap(nums)

// ── Maps ─────────────────────────────────────────
scores := map[string]int{"Alice": 95, "Bob": 87}
scores["Carol"] = 91
val, ok := scores["Dave"]  // ok=false if missing

// ── Goroutines & channels (concurrency) ──────────
ch := make(chan int)
go func() { ch <- 42 }()
value := <-ch

// ── Defer ─────────────────────────────────────────
func readFile() {
    f, _ := os.Open("file.txt")
    defer f.Close()   // runs when function exits
    // ... use f
}

func main() {
    fmt.Println("Hello, World!")
}
""",
        "tips": [
            "Go has no exceptions – return errors as values.",
            "Always check err != nil after operations that can fail.",
            "Goroutines are cheap – use them for concurrency.",
            "gofmt formats your code automatically – run it always.",
            "Interfaces are implicit – no 'implements' keyword needed.",
        ],
    },
}

# Aliases for language lookup
LANG_ALIASES = {
    "py":           "python",
    "js":           "javascript",
    "ts":           "typescript",
    "node":         "javascript",
    "nodejs":       "javascript",
    "java":         "java",
    "cpp":          "c++",
    "c plus plus":  "c++",
    "rs":           "rust",
    "golang":       "go",
    "html5":        "html",
    "css3":         "css",
    "mysql":        "sql",
    "postgresql":   "sql",
    "postgres":     "sql",
    "sqlite":       "sql",
    "luau":         "lua",
    "roblox":       "lua",
}
