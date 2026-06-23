"""General Computer Science knowledge base."""

CONCEPTS = {
    # ─── Variables & Types ───────────────────────────────────────────────────
    "variable": {
        "title": "Variables",
        "explanation": (
            "A variable is a named container that stores a value in memory.\n"
            "Think of it like a labelled box: you give it a name, put a value inside,\n"
            "and can read or change that value later.\n\n"
            "Examples across languages:\n"
            "  Python:     x = 42\n"
            "  JavaScript: let x = 42;\n"
            "  Java:       int x = 42;\n"
            "  C++:        int x = 42;\n"
            "  Lua:        local x = 42\n"
            "  Rust:       let x: i32 = 42;"
        ),
        "key_points": [
            "Variables hold data that can change during program execution.",
            "Every variable has a name (identifier), a type, and a value.",
            "Some languages infer the type automatically (Python, JS, Lua).",
            "Some languages require you to declare the type (Java, C++).",
            "Variable names should be descriptive (age, not a).",
        ],
        "quiz": [
            {"q": "What is a variable?", "a": "a named container that stores a value"},
            {"q": "Which of these is a valid Python variable name: 2name or name2?", "a": "name2"},
        ],
    },

    "data types": {
        "title": "Data Types",
        "explanation": (
            "Data types tell the computer what kind of value a variable holds.\n\n"
            "Common primitive types:\n"
            "  Integer   – whole numbers:       42, -7, 0\n"
            "  Float     – decimal numbers:     3.14, -0.5\n"
            "  String    – text:                \"Hello\", 'World'\n"
            "  Boolean   – true/false:          True, False\n"
            "  None/Null – absence of a value:  None, null, nil\n\n"
            "Composite types:\n"
            "  Array / List   – ordered collection:  [1, 2, 3]\n"
            "  Object / Dict  – key-value pairs:     {name: 'Bob', age: 30}\n"
            "  Tuple          – immutable list:      (1, 2, 3)"
        ),
        "key_points": [
            "Every value has a type that determines what operations are valid.",
            "Strongly typed languages (Java, C++) enforce types at compile time.",
            "Weakly typed languages (Python, JS) check types at runtime.",
            "Type errors are one of the most common bugs in programming.",
        ],
        "quiz": [
            {"q": "What type is the value 3.14?", "a": "float"},
            {"q": "What type is True or False?", "a": "boolean"},
        ],
    },

    # ─── Control Flow ────────────────────────────────────────────────────────
    "if statement": {
        "title": "If Statements (Conditionals)",
        "explanation": (
            "An if statement runs code only when a condition is true.\n\n"
            "Python:\n"
            "  if age >= 18:\n"
            "      print('Adult')\n"
            "  elif age >= 13:\n"
            "      print('Teen')\n"
            "  else:\n"
            "      print('Child')\n\n"
            "JavaScript:\n"
            "  if (age >= 18) {\n"
            "      console.log('Adult');\n"
            "  } else if (age >= 13) {\n"
            "      console.log('Teen');\n"
            "  } else {\n"
            "      console.log('Child');\n"
            "  }\n\n"
            "Lua:\n"
            "  if age >= 18 then\n"
            "      print('Adult')\n"
            "  elseif age >= 13 then\n"
            "      print('Teen')\n"
            "  else\n"
            "      print('Child')\n"
            "  end"
        ),
        "key_points": [
            "The condition must evaluate to true or false.",
            "else handles all cases not caught by if/elif.",
            "You can nest if statements inside each other.",
            "Comparison operators: ==, !=, <, >, <=, >=",
        ],
        "quiz": [
            {"q": "What keyword handles an alternative condition in Python?", "a": "elif"},
            {"q": "What does an else block do?", "a": "runs when all previous conditions are false"},
        ],
    },

    "loop": {
        "title": "Loops",
        "explanation": (
            "Loops repeat a block of code multiple times.\n\n"
            "FOR loop – iterate a known number of times:\n"
            "  Python:     for i in range(5): print(i)\n"
            "  JavaScript: for (let i = 0; i < 5; i++) console.log(i);\n"
            "  Lua:        for i = 1, 5 do print(i) end\n\n"
            "WHILE loop – repeat while condition is true:\n"
            "  Python:     while count < 5: count += 1\n"
            "  JavaScript: while (count < 5) { count++; }\n"
            "  Lua:        while count < 5 do count = count + 1 end\n\n"
            "Loop control:\n"
            "  break    – exit the loop immediately\n"
            "  continue – skip to the next iteration"
        ),
        "key_points": [
            "for loops are best when you know how many times to repeat.",
            "while loops are best when you repeat until a condition changes.",
            "An infinite loop runs forever unless you use break.",
            "Off-by-one errors are the most common loop bug.",
        ],
        "quiz": [
            {"q": "Which loop is best when you don't know how many iterations?", "a": "while loop"},
            {"q": "What keyword exits a loop immediately?", "a": "break"},
        ],
    },

    # ─── Functions ───────────────────────────────────────────────────────────
    "function": {
        "title": "Functions",
        "explanation": (
            "A function is a reusable block of code that performs a specific task.\n"
            "Functions take input (parameters) and can return output (return value).\n\n"
            "Python:\n"
            "  def greet(name):\n"
            "      return f'Hello, {name}!'\n\n"
            "  result = greet('Alice')   # 'Hello, Alice!'\n\n"
            "JavaScript:\n"
            "  function greet(name) {\n"
            "      return `Hello, ${name}!`;\n"
            "  }\n\n"
            "Lua:\n"
            "  local function greet(name)\n"
            "      return 'Hello, ' .. name .. '!'\n"
            "  end\n\n"
            "Arrow function (JS):\n"
            "  const greet = (name) => `Hello, ${name}!`;"
        ),
        "key_points": [
            "Functions promote code reuse – write once, call many times.",
            "Parameters are variables listed in the function definition.",
            "Arguments are the actual values passed when calling the function.",
            "return sends a value back to the caller.",
            "Functions without return implicitly return None/null/nil.",
        ],
        "quiz": [
            {"q": "What keyword defines a function in Python?", "a": "def"},
            {"q": "What's the difference between a parameter and an argument?", "a": "parameter is the variable name in the definition; argument is the actual value passed"},
        ],
    },

    # ─── OOP ─────────────────────────────────────────────────────────────────
    "class": {
        "title": "Classes & Object-Oriented Programming (OOP)",
        "explanation": (
            "A class is a blueprint for creating objects.\n"
            "OOP organises code around objects that combine data (attributes)\n"
            "and behaviour (methods).\n\n"
            "Python example:\n"
            "  class Dog:\n"
            "      def __init__(self, name, breed):\n"
            "          self.name  = name    # attribute\n"
            "          self.breed = breed\n\n"
            "      def bark(self):           # method\n"
            "          return f'{self.name} says: Woof!'\n\n"
            "  rex = Dog('Rex', 'Labrador')\n"
            "  print(rex.bark())  # Rex says: Woof!\n\n"
            "The 4 pillars of OOP:\n"
            "  1. Encapsulation  – hide internal state behind methods\n"
            "  2. Abstraction    – expose only what's necessary\n"
            "  3. Inheritance    – a class can extend another class\n"
            "  4. Polymorphism   – objects of different types respond to the same interface"
        ),
        "key_points": [
            "__init__ (Python) / constructor (Java/JS) runs when an object is created.",
            "self/this refers to the current object instance.",
            "Inheritance lets a child class reuse code from a parent class.",
            "OOP helps manage complexity in large programs.",
        ],
        "quiz": [
            {"q": "What is a class?", "a": "a blueprint for creating objects"},
            {"q": "What are the 4 pillars of OOP?", "a": "encapsulation, abstraction, inheritance, polymorphism"},
        ],
    },

    # ─── Data Structures ─────────────────────────────────────────────────────
    "array": {
        "title": "Arrays & Lists",
        "explanation": (
            "An array (or list) stores multiple values in a single variable,\n"
            "accessed by index (position). Indexes start at 0 in most languages.\n\n"
            "Python list:\n"
            "  fruits = ['apple', 'banana', 'cherry']\n"
            "  fruits[0]          # 'apple'\n"
            "  fruits[-1]         # 'cherry' (last item)\n"
            "  fruits.append('date')\n"
            "  fruits.remove('banana')\n"
            "  len(fruits)        # 3\n\n"
            "JavaScript array:\n"
            "  const fruits = ['apple', 'banana', 'cherry'];\n"
            "  fruits[0];         // 'apple'\n"
            "  fruits.push('date');\n"
            "  fruits.splice(1, 1); // remove 'banana'\n\n"
            "Lua table (used as array):\n"
            "  local fruits = {'apple', 'banana', 'cherry'}\n"
            "  fruits[1]          -- 'apple' (1-indexed!)\n"
            "  table.insert(fruits, 'date')"
        ),
        "key_points": [
            "Arrays are ordered – the order you put items in is preserved.",
            "Most languages index from 0; Lua indexes from 1.",
            "Common operations: append, remove, sort, search, slice.",
            "Time complexity: access O(1), search O(n), insert/delete O(n).",
        ],
        "quiz": [
            {"q": "What index is the first element of an array in Python?", "a": "0"},
            {"q": "What index is the first element of a table in Lua?", "a": "1"},
        ],
    },

    "dictionary": {
        "title": "Dictionaries / Hash Maps / Objects",
        "explanation": (
            "A dictionary maps keys to values (key-value pairs).\n"
            "Like a real dictionary: look up a word (key) to get its definition (value).\n\n"
            "Python dict:\n"
            "  person = {'name': 'Alice', 'age': 25}\n"
            "  person['name']      # 'Alice'\n"
            "  person['city'] = 'NYC'  # add key\n"
            "  del person['age']   # remove key\n"
            "  'name' in person    # True\n\n"
            "JavaScript object:\n"
            "  const person = { name: 'Alice', age: 25 };\n"
            "  person.name;        // 'Alice'\n"
            "  person.city = 'NYC';\n\n"
            "Lua table (as dict):\n"
            "  local person = {name='Alice', age=25}\n"
            "  person.name         -- 'Alice'\n"
            "  person.city = 'NYC'"
        ),
        "key_points": [
            "Keys must be unique; values can repeat.",
            "Lookup by key is O(1) – very fast.",
            "Great for counting, grouping, and storing structured data.",
            "In Python 3.7+, dicts preserve insertion order.",
        ],
        "quiz": [
            {"q": "What is the time complexity of dictionary lookup?", "a": "O(1)"},
            {"q": "Can a dictionary have duplicate keys?", "a": "no"},
        ],
    },

    # ─── Algorithms ──────────────────────────────────────────────────────────
    "recursion": {
        "title": "Recursion",
        "explanation": (
            "Recursion is when a function calls itself to solve a smaller version\n"
            "of the same problem. Every recursive function needs:\n"
            "  1. Base case  – the stopping condition (prevents infinite recursion)\n"
            "  2. Recursive case – the function calls itself with a simpler input\n\n"
            "Classic example – factorial:\n"
            "  def factorial(n):\n"
            "      if n == 0:          # base case\n"
            "          return 1\n"
            "      return n * factorial(n - 1)  # recursive case\n\n"
            "  factorial(5) → 5 * factorial(4)\n"
            "               → 5 * 4 * factorial(3)\n"
            "               → 5 * 4 * 3 * 2 * 1 * 1 = 120\n\n"
            "Fibonacci:\n"
            "  def fib(n):\n"
            "      if n <= 1: return n\n"
            "      return fib(n-1) + fib(n-2)"
        ),
        "key_points": [
            "Always define the base case first to avoid infinite recursion.",
            "Each recursive call must move towards the base case.",
            "Recursion uses the call stack – deep recursion can cause stack overflow.",
            "Many recursive solutions can be rewritten as loops (iteration).",
        ],
        "quiz": [
            {"q": "What prevents infinite recursion?", "a": "the base case"},
            {"q": "What is factorial(0)?", "a": "1"},
        ],
    },

    "sorting": {
        "title": "Sorting Algorithms",
        "explanation": (
            "Sorting arranges elements in order. Key algorithms:\n\n"
            "Bubble Sort – O(n²) – simple, swap adjacent elements repeatedly\n"
            "  def bubble_sort(arr):\n"
            "      for i in range(len(arr)):\n"
            "          for j in range(len(arr)-1-i):\n"
            "              if arr[j] > arr[j+1]:\n"
            "                  arr[j], arr[j+1] = arr[j+1], arr[j]\n\n"
            "Merge Sort – O(n log n) – divide array in half, sort each, merge\n"
            "Quick Sort – O(n log n) avg – pick pivot, partition, recurse\n"
            "Insertion Sort – O(n²) – build sorted array one element at a time\n\n"
            "Built-in (use these in real code!):\n"
            "  Python:     sorted(arr)  or  arr.sort()\n"
            "  JavaScript: arr.sort((a,b) => a - b)\n"
            "  Lua:        table.sort(arr)"
        ),
        "key_points": [
            "Always use built-in sort for production code.",
            "O(n log n) is optimal for comparison-based sorting.",
            "Bubble sort is easy to understand but very slow for large data.",
            "Merge sort is stable (preserves order of equal elements).",
        ],
        "quiz": [
            {"q": "What is the time complexity of merge sort?", "a": "O(n log n)"},
            {"q": "Which built-in sorts a list in Python?", "a": "sorted() or list.sort()"},
        ],
    },

    "big o": {
        "title": "Big O Notation",
        "explanation": (
            "Big O describes how the time or space an algorithm uses\n"
            "grows as the input size (n) increases.\n\n"
            "From fastest to slowest:\n"
            "  O(1)       Constant   – doesn't grow with input  (array[0])\n"
            "  O(log n)   Logarithmic– halves input each step   (binary search)\n"
            "  O(n)       Linear     – grows linearly           (linear search)\n"
            "  O(n log n) Log-linear – efficient sorting        (merge sort)\n"
            "  O(n²)      Quadratic  – nested loops             (bubble sort)\n"
            "  O(2ⁿ)      Exponential– doubles each step        (naive fibonacci)\n\n"
            "Rule of thumb:\n"
            "  n=1000: O(n)=1000 ops, O(n²)=1,000,000 ops, O(2ⁿ)= way too many"
        ),
        "key_points": [
            "Drop constants: O(2n) → O(n)",
            "Drop non-dominant terms: O(n + n²) → O(n²)",
            "Always aim for O(n log n) or better for large datasets.",
            "Space complexity describes memory usage, not time.",
        ],
        "quiz": [
            {"q": "What is the Big O of accessing an array element by index?", "a": "O(1)"},
            {"q": "What is the Big O of binary search?", "a": "O(log n)"},
        ],
    },

    # ─── Web / General ───────────────────────────────────────────────────────
    "api": {
        "title": "APIs (Application Programming Interfaces)",
        "explanation": (
            "An API is a set of rules that allows programs to talk to each other.\n"
            "A REST API communicates over HTTP using standard methods:\n\n"
            "  GET    /users       – retrieve all users\n"
            "  GET    /users/1     – retrieve user with id=1\n"
            "  POST   /users       – create a new user\n"
            "  PUT    /users/1     – update user 1 completely\n"
            "  PATCH  /users/1     – partially update user 1\n"
            "  DELETE /users/1     – delete user 1\n\n"
            "Python example (requests library):\n"
            "  import requests\n"
            "  response = requests.get('https://api.example.com/users')\n"
            "  data = response.json()\n\n"
            "Response status codes:\n"
            "  200 OK, 201 Created, 400 Bad Request, 401 Unauthorized,\n"
            "  404 Not Found, 500 Internal Server Error"
        ),
        "key_points": [
            "APIs let different systems communicate without knowing each other's internals.",
            "JSON is the most common data format for REST APIs.",
            "Always handle errors – check the status code.",
            "API keys authenticate your requests.",
        ],
        "quiz": [
            {"q": "Which HTTP method creates a new resource?", "a": "POST"},
            {"q": "What does a 404 status code mean?", "a": "not found"},
        ],
    },

    "git": {
        "title": "Git Version Control",
        "explanation": (
            "Git tracks changes to your code over time.\n\n"
            "Essential commands:\n"
            "  git init              – start a new repo\n"
            "  git clone <url>       – copy an existing repo\n"
            "  git status            – see what changed\n"
            "  git add <file>        – stage changes\n"
            "  git add .             – stage all changes\n"
            "  git commit -m 'msg'   – save a snapshot\n"
            "  git push              – upload to remote (GitHub)\n"
            "  git pull              – download latest changes\n"
            "  git branch <name>     – create a branch\n"
            "  git checkout <name>   – switch branches\n"
            "  git merge <branch>    – merge a branch in\n"
            "  git log               – see commit history\n\n"
            "Branching workflow:\n"
            "  main branch – production code\n"
            "  feature branches – work in isolation, then merge"
        ),
        "key_points": [
            "Commit early, commit often – small commits are easier to debug.",
            "Write descriptive commit messages.",
            "Never commit passwords or API keys.",
            "Use .gitignore to exclude files like node_modules.",
        ],
        "quiz": [
            {"q": "What command stages changes for commit?", "a": "git add"},
            {"q": "What command saves a snapshot of staged changes?", "a": "git commit"},
        ],
    },

    "debugging": {
        "title": "Debugging",
        "explanation": (
            "Debugging is the process of finding and fixing bugs in code.\n\n"
            "Techniques:\n"
            "  1. Print debugging – add print() statements to see values\n"
            "     print(f'x = {x}, type = {type(x)}')\n\n"
            "  2. Use a debugger – set breakpoints and step through code\n"
            "     Python: python -m pdb script.py\n"
            "     VS Code: click the gutter to set a breakpoint\n\n"
            "  3. Read the error message! Most errors tell you:\n"
            "     - What went wrong (TypeError, NameError, etc.)\n"
            "     - Which file and line number\n"
            "     - The stack trace (call sequence)\n\n"
            "  4. Rubber duck debugging – explain your code out loud\n"
            "  5. Divide and conquer – comment out half the code to isolate the bug\n\n"
            "Common errors:\n"
            "  SyntaxError  – invalid code structure\n"
            "  NameError    – variable doesn't exist\n"
            "  TypeError    – wrong type for operation\n"
            "  IndexError   – list index out of range\n"
            "  KeyError     – dict key doesn't exist"
        ),
        "key_points": [
            "Always read the full error message before googling.",
            "The error line number is usually where debugging starts.",
            "Print intermediate values to trace data through your code.",
            "Tests catch bugs before they reach users.",
        ],
        "quiz": [
            {"q": "What error occurs when you use a variable that doesn't exist?", "a": "NameError"},
            {"q": "What error occurs when you access index 5 of a 3-element list?", "a": "IndexError"},
        ],
    },
}

# Short concept aliases
ALIASES = {
    "var":          "variable",
    "vars":         "variable",
    "variables":    "variable",
    "types":        "data types",
    "type":         "data types",
    "if":           "if statement",
    "conditionals": "if statement",
    "conditional":  "if statement",
    "loops":        "loop",
    "for":          "loop",
    "while":        "loop",
    "functions":    "function",
    "def":          "function",
    "method":       "function",
    "methods":      "function",
    "classes":      "class",
    "oop":          "class",
    "object":       "class",
    "objects":      "class",
    "list":         "array",
    "lists":        "array",
    "arrays":       "array",
    "dict":         "dictionary",
    "dicts":        "dictionary",
    "dictionaries": "dictionary",
    "hashmap":      "dictionary",
    "hash map":     "dictionary",
    "map":          "dictionary",
    "recursive":    "recursion",
    "sort":         "sorting",
    "sorting algorithms": "sorting",
    "complexity":   "big o",
    "big-o":        "big o",
    "bigo":         "big o",
    "time complexity": "big o",
    "rest":         "api",
    "apis":         "api",
    "http":         "api",
    "version control": "git",
    "vcs":          "git",
    "debug":        "debugging",
    "bugs":         "debugging",
    "error":        "debugging",
    "errors":       "debugging",
}
