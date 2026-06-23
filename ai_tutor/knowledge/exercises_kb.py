"""Coding exercises and challenges database."""

EXERCISES = {
    "beginner": [
        {
            "id":    "b01",
            "title": "Hello World",
            "description": "Print 'Hello, World!' to the console.",
            "hint": "Use the print function.",
            "solution_python":  "print('Hello, World!')",
            "solution_js":      "console.log('Hello, World!');",
            "solution_lua":     "print('Hello, World!')",
            "concept": "output",
        },
        {
            "id":    "b02",
            "title": "Sum of Two Numbers",
            "description": "Write a function that takes two numbers and returns their sum.",
            "hint": "Use the + operator and a return statement.",
            "solution_python":  "def add(a, b):\n    return a + b",
            "solution_js":      "function add(a, b) { return a + b; }",
            "solution_lua":     "local function add(a, b) return a + b end",
            "concept": "function",
        },
        {
            "id":    "b03",
            "title": "Even or Odd",
            "description": "Write a function that returns 'even' if a number is even, 'odd' otherwise.",
            "hint": "Use the modulo operator (%). If n % 2 == 0, it's even.",
            "solution_python":  "def even_or_odd(n):\n    return 'even' if n % 2 == 0 else 'odd'",
            "solution_js":      "function evenOrOdd(n) { return n % 2 === 0 ? 'even' : 'odd'; }",
            "solution_lua":     "local function evenOrOdd(n)\n    return n % 2 == 0 and 'even' or 'odd'\nend",
            "concept": "conditional",
        },
        {
            "id":    "b04",
            "title": "Count to N",
            "description": "Print numbers from 1 to N (inclusive) using a loop.",
            "hint": "Use a for loop with range(1, n+1) in Python.",
            "solution_python":  "def count_to(n):\n    for i in range(1, n+1):\n        print(i)",
            "solution_js":      "function countTo(n) { for (let i=1; i<=n; i++) console.log(i); }",
            "solution_lua":     "local function countTo(n)\n    for i = 1, n do print(i) end\nend",
            "concept": "loop",
        },
        {
            "id":    "b05",
            "title": "Reverse a String",
            "description": "Write a function that reverses a string.",
            "hint": "Python: use slice [::-1]. JS: split, reverse, join.",
            "solution_python":  "def reverse_string(s):\n    return s[::-1]",
            "solution_js":      "function reverseString(s) { return s.split('').reverse().join(''); }",
            "solution_lua":     "local function reverseString(s)\n    return s:reverse()\nend",
            "concept": "string",
        },
        {
            "id":    "b06",
            "title": "Find the Maximum",
            "description": "Given a list of numbers, return the largest one without using built-in max().",
            "hint": "Start with the first element as max, then compare with each other element.",
            "solution_python": (
                "def find_max(nums):\n"
                "    maximum = nums[0]\n"
                "    for n in nums:\n"
                "        if n > maximum:\n"
                "            maximum = n\n"
                "    return maximum"
            ),
            "solution_js": (
                "function findMax(nums) {\n"
                "    let max = nums[0];\n"
                "    for (const n of nums) if (n > max) max = n;\n"
                "    return max;\n"
                "}"
            ),
            "concept": "loop",
        },
        {
            "id":    "b07",
            "title": "FizzBuzz",
            "description": (
                "Print numbers 1-100. For multiples of 3 print 'Fizz', "
                "multiples of 5 print 'Buzz', both print 'FizzBuzz'."
            ),
            "hint": "Check divisibility by 15 first, then 3, then 5.",
            "solution_python": (
                "for i in range(1, 101):\n"
                "    if i % 15 == 0:\n"
                "        print('FizzBuzz')\n"
                "    elif i % 3 == 0:\n"
                "        print('Fizz')\n"
                "    elif i % 5 == 0:\n"
                "        print('Buzz')\n"
                "    else:\n"
                "        print(i)"
            ),
            "concept": "conditional",
        },
    ],

    "intermediate": [
        {
            "id":    "i01",
            "title": "Palindrome Check",
            "description": "Write a function that returns True if a string reads the same forwards and backwards.",
            "hint": "Compare the string with its reverse. Remember to handle case and spaces.",
            "solution_python": (
                "def is_palindrome(s):\n"
                "    s = s.lower().replace(' ', '')\n"
                "    return s == s[::-1]"
            ),
            "concept": "string",
        },
        {
            "id":    "i02",
            "title": "Fibonacci Sequence",
            "description": "Return the first N Fibonacci numbers as a list.",
            "hint": "Each number is the sum of the two before it: 0, 1, 1, 2, 3, 5, 8...",
            "solution_python": (
                "def fibonacci(n):\n"
                "    seq = [0, 1]\n"
                "    for _ in range(n - 2):\n"
                "        seq.append(seq[-1] + seq[-2])\n"
                "    return seq[:n]"
            ),
            "concept": "loop",
        },
        {
            "id":    "i03",
            "title": "Count Word Frequency",
            "description": "Given a string, return a dictionary with how many times each word appears.",
            "hint": "Split the string into words. Use a dict to count occurrences.",
            "solution_python": (
                "def word_frequency(text):\n"
                "    freq = {}\n"
                "    for word in text.lower().split():\n"
                "        freq[word] = freq.get(word, 0) + 1\n"
                "    return freq"
            ),
            "concept": "dictionary",
        },
        {
            "id":    "i04",
            "title": "Binary Search",
            "description": "Implement binary search. Given a sorted list and a target, return the index or -1.",
            "hint": "Repeatedly halve the search space: compare target with middle element.",
            "solution_python": (
                "def binary_search(arr, target):\n"
                "    lo, hi = 0, len(arr) - 1\n"
                "    while lo <= hi:\n"
                "        mid = (lo + hi) // 2\n"
                "        if arr[mid] == target:\n"
                "            return mid\n"
                "        elif arr[mid] < target:\n"
                "            lo = mid + 1\n"
                "        else:\n"
                "            hi = mid - 1\n"
                "    return -1"
            ),
            "concept": "algorithm",
        },
        {
            "id":    "i05",
            "title": "Stack Implementation",
            "description": "Implement a Stack class with push, pop, peek, and is_empty methods.",
            "hint": "A stack is LIFO (Last In First Out). Use a list as the internal storage.",
            "solution_python": (
                "class Stack:\n"
                "    def __init__(self):\n"
                "        self._items = []\n\n"
                "    def push(self, item):\n"
                "        self._items.append(item)\n\n"
                "    def pop(self):\n"
                "        if self.is_empty():\n"
                "            raise IndexError('pop from empty stack')\n"
                "        return self._items.pop()\n\n"
                "    def peek(self):\n"
                "        if self.is_empty():\n"
                "            raise IndexError('peek from empty stack')\n"
                "        return self._items[-1]\n\n"
                "    def is_empty(self):\n"
                "        return len(self._items) == 0\n\n"
                "    def __len__(self):\n"
                "        return len(self._items)"
            ),
            "concept": "class",
        },
        {
            "id":    "i06",
            "title": "Anagram Checker",
            "description": "Write a function that returns True if two strings are anagrams of each other.",
            "hint": "Two strings are anagrams if they contain the same characters in any order.",
            "solution_python": (
                "def is_anagram(s1, s2):\n"
                "    s1 = s1.lower().replace(' ', '')\n"
                "    s2 = s2.lower().replace(' ', '')\n"
                "    return sorted(s1) == sorted(s2)"
            ),
            "concept": "string",
        },
    ],

    "advanced": [
        {
            "id":    "a01",
            "title": "Merge Sort",
            "description": "Implement the merge sort algorithm.",
            "hint": "Divide the list in half, recursively sort each half, then merge them.",
            "solution_python": (
                "def merge_sort(arr):\n"
                "    if len(arr) <= 1:\n"
                "        return arr\n"
                "    mid   = len(arr) // 2\n"
                "    left  = merge_sort(arr[:mid])\n"
                "    right = merge_sort(arr[mid:])\n"
                "    return merge(left, right)\n\n"
                "def merge(left, right):\n"
                "    result = []\n"
                "    i = j  = 0\n"
                "    while i < len(left) and j < len(right):\n"
                "        if left[i] <= right[j]:\n"
                "            result.append(left[i]); i += 1\n"
                "        else:\n"
                "            result.append(right[j]); j += 1\n"
                "    result.extend(left[i:])\n"
                "    result.extend(right[j:])\n"
                "    return result"
            ),
            "concept": "sorting",
        },
        {
            "id":    "a02",
            "title": "Linked List",
            "description": "Implement a singly linked list with insert, delete, and traverse methods.",
            "hint": "Each node holds a value and a reference to the next node.",
            "solution_python": (
                "class Node:\n"
                "    def __init__(self, val):\n"
                "        self.val  = val\n"
                "        self.next = None\n\n"
                "class LinkedList:\n"
                "    def __init__(self):\n"
                "        self.head = None\n\n"
                "    def insert(self, val):\n"
                "        new_node = Node(val)\n"
                "        if not self.head:\n"
                "            self.head = new_node\n"
                "            return\n"
                "        cur = self.head\n"
                "        while cur.next:\n"
                "            cur = cur.next\n"
                "        cur.next = new_node\n\n"
                "    def delete(self, val):\n"
                "        if not self.head: return\n"
                "        if self.head.val == val:\n"
                "            self.head = self.head.next\n"
                "            return\n"
                "        cur = self.head\n"
                "        while cur.next and cur.next.val != val:\n"
                "            cur = cur.next\n"
                "        if cur.next:\n"
                "            cur.next = cur.next.next\n\n"
                "    def traverse(self):\n"
                "        values = []\n"
                "        cur = self.head\n"
                "        while cur:\n"
                "            values.append(cur.val)\n"
                "            cur = cur.next\n"
                "        return values"
            ),
            "concept": "class",
        },
        {
            "id":    "a03",
            "title": "Memoized Fibonacci",
            "description": "Implement Fibonacci with memoization (dynamic programming) for O(n) time.",
            "hint": "Cache results you've already computed to avoid repeating work.",
            "solution_python": (
                "from functools import lru_cache\n\n"
                "@lru_cache(maxsize=None)\n"
                "def fib(n):\n"
                "    if n <= 1: return n\n"
                "    return fib(n-1) + fib(n-2)\n\n"
                "# Manual memoization:\n"
                "def fib_memo(n, memo={}):\n"
                "    if n in memo: return memo[n]\n"
                "    if n <= 1: return n\n"
                "    memo[n] = fib_memo(n-1, memo) + fib_memo(n-2, memo)\n"
                "    return memo[n]"
            ),
            "concept": "recursion",
        },
    ],
}

QUIZZES = {
    "variables": [
        {"q": "Which Python keyword makes a variable constant by convention?",
         "options": ["const", "UPPERCASE", "final", "immutable"], "answer": "UPPERCASE",
         "explanation": "Python has no const keyword – by convention, UPPER_CASE means 'don't change this'."},
        {"q": "What is the output of: x = 5; y = x; x = 10; print(y)?",
         "options": ["5", "10", "Error", "None"], "answer": "5",
         "explanation": "y was assigned the VALUE of x (5), not a reference to x. Changing x later doesn't affect y."},
    ],
    "loops": [
        {"q": "How many times does this print? for i in range(3): print(i)",
         "options": ["2", "3", "4", "0"], "answer": "3",
         "explanation": "range(3) produces 0, 1, 2 – three values."},
        {"q": "What does 'break' do inside a loop?",
         "options": ["Skips one iteration", "Exits the loop", "Restarts the loop", "Raises an error"],
         "answer": "Exits the loop",
         "explanation": "break immediately exits the entire loop. Use 'continue' to skip one iteration."},
    ],
    "functions": [
        {"q": "What does a function return if there is no return statement?",
         "options": ["0", "None", "Error", "True"], "answer": "None",
         "explanation": "In Python, a function with no return statement returns None implicitly."},
        {"q": "What is a function that calls itself called?",
         "options": ["Callback", "Lambda", "Recursive", "Generator"], "answer": "Recursive",
         "explanation": "A recursive function calls itself, solving smaller sub-problems until a base case is reached."},
    ],
    "data types": [
        {"q": "Which of these is NOT a primitive data type?",
         "options": ["int", "float", "bool", "list"], "answer": "list",
         "explanation": "A list is a composite/collection type. Primitives are single values: int, float, bool, str, None."},
        {"q": "What does type('hello') return in Python?",
         "options": ["str", "String", "<class 'str'>", "text"], "answer": "<class 'str'>",
         "explanation": "type() returns the class object; its string representation is <class 'str'>."},
    ],
    "oop": [
        {"q": "What does 'self' refer to in a Python method?",
         "options": ["The class itself", "The current instance", "The parent class", "Nothing"],
         "answer": "The current instance",
         "explanation": "self is a reference to the specific object the method is being called on."},
        {"q": "What is inheritance?",
         "options": [
             "Hiding internal state",
             "A child class reusing a parent class's code",
             "An object with multiple types",
             "Wrapping data in methods"],
         "answer": "A child class reusing a parent class's code",
         "explanation": "Inheritance allows a class to extend another class, reusing and overriding its functionality."},
    ],
}
